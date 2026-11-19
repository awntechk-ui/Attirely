import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../Common_Screens/session_manager.dart';
import '../../app_config.dart';

class BookingCheckout {
  BookingCheckout({
    this.verificationPath = '/payments/verify',
    this.confirmationPendingStatus = 'booking_pending',
    this.confirmationPendingMessage =
        'Payment received. Your booking is still being confirmed.',
    this.statusButtonLabel = 'Check booking status',
    this.priceChangedMessage =
        'The checkout total changed. Reopen the booking to refresh the price.',
  });

  final String verificationPath;
  final String confirmationPendingStatus;
  final String confirmationPendingMessage;
  final String statusButtonLabel;
  final String priceChangedMessage;
  Map<String, dynamic>? _pendingVerification;

  bool get hasPendingPayment => _pendingVerification != null;

  Future<Map<String, dynamic>> pay({
    required String path,
    required String description,
    required Map<String, dynamic> request,
    required int expectedAmount,
    VoidCallback? onConfirming,
  }) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw Exception('Razorpay Checkout is available on Android and iOS.');
    }

    if (_pendingVerification == null) {
      final order = await _post(path, request);
      if (order['success'] == true) return order;
      if (order['status'] == confirmationPendingStatus) {
        throw Exception(
          '$confirmationPendingMessage Tap Continue to check again.',
        );
      }
      if (order['status'] == 'capture_pending') {
        throw Exception(
          'Payment confirmation is still in progress. Tap Continue to check again.',
        );
      }
      if (order['amount'] != expectedAmount || order['currency'] != 'INR') {
        throw Exception(priceChangedMessage);
      }

      final payment = await _open(order, description);
      _pendingVerification = {
        'checkout_id': order['checkout_id'],
        'razorpay_payment_id': payment.paymentId,
        'razorpay_signature': payment.signature,
      };
    }

    onConfirming?.call();
    final verification = _pendingVerification!;
    var paymentCaptured = false;
    const delays = [
      Duration.zero,
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ];
    for (final delay in delays) {
      if (delay != Duration.zero) await Future<void>.delayed(delay);

      try {
        final result = await _post(
          verificationPath,
          verification,
          timeout: const Duration(seconds: 10),
        );
        if (result['success'] == true) {
          _pendingVerification = null;
          return result;
        }
        paymentCaptured =
            paymentCaptured || result['status'] == confirmationPendingStatus;
      } on TimeoutException {
        // The same verification can be submitted again after a lost response.
      } on http.ClientException {
        // The device may still be reconnecting after leaving Checkout.
      } on _CheckoutHttpException catch (error) {
        if (error.statusCode != 408 &&
            error.statusCode != 429 &&
            error.statusCode < 500) {
          rethrow;
        }
      }
    }

    final status = paymentCaptured
        ? confirmationPendingMessage
        : 'Payment confirmation is still in progress.';
    throw Exception(
      '$status Tap $statusButtonLabel to check the same payment.',
    );
  }

  Future<PaymentSuccessResponse> _open(
    Map<String, dynamic> order,
    String description,
  ) async {
    final key = order['key_id'];
    final orderId = order['razorpay_order_id'];
    if (key is! String ||
        !key.startsWith('rzp_test_') ||
        orderId is! String ||
        order['checkout_id'] is! String) {
      throw Exception('The Razorpay test order is invalid.');
    }

    final checkout = Razorpay();
    final result = Completer<PaymentSuccessResponse>();
    checkout.on(Razorpay.EVENT_PAYMENT_SUCCESS, (
      PaymentSuccessResponse response,
    ) {
      if (result.isCompleted) return;
      if (response.orderId != orderId ||
          response.paymentId == null ||
          response.signature == null) {
        result.completeError(
          Exception('Razorpay did not return valid payment details.'),
        );
        return;
      }
      result.complete(response);
    });
    checkout.on(Razorpay.EVENT_PAYMENT_ERROR, (
      PaymentFailureResponse response,
    ) {
      if (result.isCompleted) return;
      final message = response.code == Razorpay.PAYMENT_CANCELLED
          ? 'Payment cancelled.'
          : response.message ?? 'Razorpay payment failed.';
      result.completeError(Exception(message));
    });

    checkout.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse _) {
      if (!result.isCompleted) {
        result.completeError(
          Exception('Choose another payment method in Razorpay.'),
        );
      }
    });

    try {
      // The SDK's open method is async void. Catch platform errors in its zone.
      runZonedGuarded(
        () {
          checkout.open({
            'key': key,
            'order_id': orderId,
            'amount': order['amount'],
            'currency': order['currency'],
            'name': 'Attirely',
            'description': description,
            'config': {
              'display': {
                'blocks': {
                  'upi': {
                    'name': 'Pay with UPI',
                    'instruments': [
                      {'method': 'upi'},
                    ],
                  },
                },
                'sequence': ['block.upi'],
                'preferences': {'show_default_blocks': true},
              },
            },
          });
        },
        (error, stackTrace) {
          if (!result.isCompleted) {
            result.completeError(
              Exception('Unable to open Razorpay Checkout.'),
            );
          }
        },
      );
      return await result.future;
    } finally {
      checkout.clear();
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 35),
  }) async {
    final token = SessionManager.getToken() ?? await SessionManager.loadToken();
    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please log in again.');
    }

    final response = await http
        .post(
          Uri.parse('${AppConfig.baseUrl}$path'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(timeout);
    final decoded = response.body.startsWith('{')
        ? jsonDecode(response.body)
        : null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = decoded is Map ? decoded['detail'] : null;
      throw _CheckoutHttpException(
        response.statusCode,
        detail is String ? detail : 'Unable to complete checkout. Try again.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw Exception('The checkout response is invalid.');
    }
    return decoded;
  }
}

class _CheckoutHttpException implements Exception {
  const _CheckoutHttpException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'Exception: $message';
}
