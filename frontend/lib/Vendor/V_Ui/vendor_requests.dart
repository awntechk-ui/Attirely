
import 'package:flutter/material.dart';

import '../../Common_Screens/session_manager.dart';
import '../Vendor_API_Routes/trial_requests_api_routes.dart';

class VendorRequests extends StatefulWidget {
  const VendorRequests({super.key});

  @override
  State<VendorRequests> createState() => _VendorRequestsState();
}

class _VendorRequestsState extends State<VendorRequests>
    with SingleTickerProviderStateMixin {
  static const Color burgundy = Color(0xFF800020);
  static const Color gold = Color(0xFFD4AF37);
  static const Color background = Color(0xFFFFF8F5);
  static const Color textColor = Color(0xFF30202A);
  static const Color muted = Color(0xFF8D7B80);

  late final TabController _tabController;
  final TextEditingController _searchController =
  TextEditingController();

  final List<String> _statuses = [
    'pending',
    'accepted',
    'rejected',
    'completed',
  ];

  final List<String> _tabLabels = [
    'Pending',
    'Accepted',
    'Rejected',
    'Completed',
  ];

  final List<String> _rejectionReasons = [
    'Outfit unavailable for the requested date',
    'Selected size is unavailable',
    'Outfit is under maintenance',
    'Unable to arrange the trial',
    'Store is unavailable on the selected date',
    'Other',
  ];

  List<Map<String, dynamic>> _requests = [];

  bool _isLoading = true;
  bool _isUpdating = false;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: _statuses.length,
      vsync: this,
    );

    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _trialMethodOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required String? selectedMethod,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedMethod == value;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? burgundy.withOpacity(0.07)
              : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? gold
                : burgundy.withOpacity(0.15),
            width: isSelected ? 1.7 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: burgundy.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: burgundy,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? burgundy : muted,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // LOAD REQUESTS
  // --------------------------------------------------

  Future<String> _getAccessToken() async {
    String? token = SessionManager.getToken();
    token ??= await SessionManager.loadToken();

    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    return token;
  }

  Future<void> _loadRequests() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final token = await _getAccessToken();

      final result =
      await TrialRequestsApiRoutes.getRequests(
        accessToken: token,
      );

      if (!mounted) return;

      setState(() {
        _requests = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '');
  }

  // --------------------------------------------------
  // FILTER REQUESTS
  // --------------------------------------------------

  List<Map<String, dynamic>> _requestsForStatus(
      String status,
      ) {
    final query = _searchQuery.toLowerCase().trim();

    return _requests.where((request) {
      final requestStatus =
      request['status']?.toString().toLowerCase();

      if (requestStatus != status) return false;

      if (query.isEmpty) return true;

      final customer =
          request['user_name']?.toString().toLowerCase() ?? '';

      final outfit =
          request['outfit_name']?.toString().toLowerCase() ?? '';

      final booking =
          request['booking_reference']?.toString().toLowerCase() ?? '';

      final requestId =
          request['id']?.toString().toLowerCase() ?? '';

      return customer.contains(query) ||
          outfit.contains(query) ||
          booking.contains(query) ||
          requestId.contains(query);
    }).toList();
  }

  int _countForStatus(String status) {
    return _requests
        .where(
          (request) =>
      request['status']?.toString().toLowerCase() == status,
    )
        .length;
  }


// --------------------------------------------------
// ACCEPT REQUEST
// --------------------------------------------------

  Future<void> _acceptRequest(
      Map<String, dynamic> request,
      ) async {
    String? selectedMethod;

    // STEP 1: Select trial arrangement
    final trialMethod = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFFFCF8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Text(
                'Arrange the trial',
                style: TextStyle(
                  color: burgundy,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How will you provide the outfit for the trial?',
                    style: TextStyle(
                      color: muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _trialMethodOption(
                    title: 'Doorstep delivery',
                    subtitle: 'I will deliver the outfit to the customer.',
                    icon: Icons.local_shipping_outlined,
                    value: 'doorstep_delivery',
                    selectedMethod: selectedMethod,
                    onTap: () {
                      setDialogState(() {
                        selectedMethod = 'doorstep_delivery';
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  _trialMethodOption(
                    title: 'Visit my store',
                    subtitle: 'The customer will visit my store.',
                    icon: Icons.storefront_outlined,
                    value: 'store_visit',
                    selectedMethod: selectedMethod,
                    onTap: () {
                      setDialogState(() {
                        selectedMethod = 'store_visit';
                      });
                    },
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: muted),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedMethod == null
                      ? null
                      : () => Navigator.pop(
                    dialogContext,
                    selectedMethod,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: burgundy,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                    burgundy.withOpacity(0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );

    if (trialMethod == null) return;

    if (!mounted) return;

    // STEP 2: Final confirmation
    final methodLabel = trialMethod == 'doorstep_delivery'
        ? 'Doorstep delivery'
        : 'Visit my store';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFCF8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Confirm acceptance?',
            style: TextStyle(
              color: burgundy,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'You are accepting the trial request from '
                '${request['user_name'] ?? 'this customer'} '
                'with the following arrangement:\n\n'
                '$methodLabel.\n\n'
                'Do you want to continue?',
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: textColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: muted),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: burgundy,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm & Accept'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // STEP 3: Save acceptance
    await _updateRequest(
      request: request,
      status: 'accepted',
      trialMethod: trialMethod,
    );
  }


  // --------------------------------------------------
  // REJECT REQUEST
  // --------------------------------------------------

  Future<void> _rejectRequest(
      Map<String, dynamic> request,
      ) async {
    String selectedReason = _rejectionReasons.first;
    final customReasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Reject trial request',
                style: TextStyle(
                  color: burgundy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please select a reason.',
                    style: TextStyle(color: muted),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _rejectionReasons.map((reason) {
                      return DropdownMenuItem(
                        value: reason,
                        child: Text(
                          reason,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        selectedReason = value;
                      });
                    },
                  ),
                  if (selectedReason == 'Other') ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: customReasonController,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'Write your reason...',
                        filled: true,
                        fillColor: background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: muted),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: burgundy,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final finalReason =
                    selectedReason == 'Other'
                        ? customReasonController.text.trim()
                        : selectedReason;

                    if (finalReason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a reason.'),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, finalReason);
                  },
                  child: const Text('Reject request'),
                ),
              ],
            );
          },
        );
      },
    );

    customReasonController.dispose();

    if (reason == null || reason.trim().isEmpty) return;

    await _updateRequest(
      request: request,
      status: 'rejected',
      trialMethod: null,
      rejectionReason: reason,
    );
  }

  // --------------------------------------------------
  // UPDATE REQUEST STATUS
  // --------------------------------------------------

  Future<void> _updateRequest({
    required Map<String, dynamic> request,
    required String status,
    required String? trialMethod,
    String? rejectionReason,
  }) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final token = await _getAccessToken();

      await TrialRequestsApiRoutes.updateRequestStatus(
        accessToken: token,
        requestId: request['id'].toString(),
        status: status,
        trialMethod: trialMethod,
        rejectionReason: rejectionReason,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted'
                ? 'Trial request accepted successfully.'
                : 'Trial request rejected.',
          ),
          backgroundColor: burgundy,
        ),
      );

      await _loadRequests();

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanError(e)),
          backgroundColor: burgundy,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // FORMAT HELPERS
  // --------------------------------------------------

  String _formatDate(dynamic value) {
    if (value == null) return 'Not specified';

    try {
      final date = DateTime.parse(value.toString());

      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];

      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  String _formatAmount(dynamic value) {
    if (value == null) return '₹0';

    final amount = double.tryParse(value.toString()) ?? 0;

    return '₹${amount.toStringAsFixed(0)}';
  }

  String _formatAddress(dynamic value) {
    if (value == null) return 'Address not available';

    dynamic address = value;

    if (address is String) {
      try {
        address = address;
      } catch (_) {
        return address;
      }
    }

    if (address is Map) {
      final parts = address.values
          .where((item) => item != null)
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();

      return parts.join(', ');
    }

    return address.toString();
  }

  // --------------------------------------------------
  // MAIN UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Requests',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: burgundy,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search customer, outfit or booking ID',
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: muted,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: burgundy,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.close_rounded),
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: burgundy.withOpacity(0.10),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: burgundy.withOpacity(0.10),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: burgundy,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 17),

          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: burgundy,
            unselectedLabelColor: muted,
            indicatorColor: gold,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            tabs: List.generate(
              _statuses.length,
                  (index) {
                final status = _statuses[index];

                return Tab(
                  text:
                  '${_tabLabels[index]} (${_countForStatus(status)})',
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: burgundy,
              ),
            )
                : _errorMessage != null
                ? _buildError()
                : TabBarView(
              controller: _tabController,
              children: _statuses.map((status) {
                return _buildRequestList(status);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // ERROR VIEW
  // --------------------------------------------------

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: muted,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _loadRequests,
              style: ElevatedButton.styleFrom(
                backgroundColor: burgundy,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // REQUEST LIST
  // --------------------------------------------------

  Widget _buildRequestList(String status) {
    final filtered = _requestsForStatus(status);

    return RefreshIndicator(
      color: burgundy,
      onRefresh: _loadRequests,
      child: filtered.isEmpty
          ? ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 110),
          Icon(
            Icons.inbox_outlined,
            size: 55,
            color: burgundy.withOpacity(0.25),
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'No requests found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'New trial requests will appear here.',
              style: TextStyle(
                fontSize: 12,
                color: muted,
              ),
            ),
          ),
        ],
      )
          : ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        itemCount: filtered.length,
        separatorBuilder: (_, __) =>
        const SizedBox(height: 13),
        itemBuilder: (context, index) {
          return _buildRequestCard(filtered[index]);
        },
      ),
    );
  }

  // --------------------------------------------------
  // REQUEST CARD
  // --------------------------------------------------

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status =
        request['status']?.toString().toLowerCase() ?? 'pending';

    final imageUrl = request['outfit_image_url']?.toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: burgundy.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: burgundy.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(13),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 68,
              height: 82,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return _imagePlaceholder();
                },
              )
                  : _imagePlaceholder(),
            ),
          ),
          title: Text(
            request['outfit_name']?.toString() ?? 'Outfit',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request['user_name']?.toString() ?? 'Customer',
                  style: const TextStyle(
                    fontSize: 12,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Trial: ${_formatDate(request['preferred_trial_date'])}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 7),
                _statusBadge(status),
              ],
            ),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),

            _detailRow(
              'Booking reference',
              request['booking_reference']?.toString() ?? '-',
            ),
            _detailRow(
              'Selected size',
              request['selected_size']?.toString() ?? '-',
            ),
            _detailRow(
              'Preferred time',
              request['preferred_time_slot']?.toString() ?? '-',
            ),
            _detailRow(
              'Trial method',
              request['trial_method'] == 'store_visit'
                  ? 'Store visit'
                  : request['trial_method'] == 'doorstep_delivery'
                  ? 'Doorstep delivery'
                  : '-',
            ),
            _detailRow(
              'Trial address',
              _formatAddress(request['trial_address']),
            ),
            _detailRow(
              'Trial amount',
              _formatAmount(request['trial_amount']),
            ),
            _detailRow(
              'Payment status',
              request['payment_status']?.toString() ?? '-',
            ),
            _detailRow(
              'Payment method',
              request['payment_method']?.toString() ?? '-',
            ),

            if (status == 'rejected')
              _detailRow(
                'Rejection reason',
                request['rejection_reason']?.toString() ?? '-',
              ),

            if (status == 'pending') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isUpdating
                          ? null
                          : () => _rejectRequest(request),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: burgundy,
                        side: const BorderSide(color: burgundy),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUpdating
                          ? null
                          : () => _acceptRequest(request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: burgundy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: const Text('Accept request'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: background,
      child: const Icon(
        Icons.checkroom_outlined,
        color: burgundy,
        size: 28,
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;

    switch (status) {
      case 'accepted':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'completed':
        color = Colors.blueGrey;
        break;
      default:
        color = const Color(0xFFE08A24);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
