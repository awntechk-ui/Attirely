
import 'package:flutter/material.dart';

import '../../app_routes.dart';

class VendorNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String priority;
  final DateTime createdAt;
  bool isRead;

  VendorNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.createdAt,
    this.isRead = false,
  });
}

class VendorNotificationStore extends ChangeNotifier {
  VendorNotificationStore._();

  static final VendorNotificationStore instance =
  VendorNotificationStore._();

  final List<VendorNotification> notifications = [
    VendorNotification(
      id: '1',
      title: 'New rental request received!',
      message:
      'A customer has raised a rental request for one of your outfits. Check your rental requests to review it.',
      type: 'request',
      priority: 'important',
      createdAt: DateTime.now().subtract(
        const Duration(minutes: 10),
      ),
    ),
    VendorNotification(
      id: '2',
      title: 'Payment received successfully',
      message:
      'Your payment has been successfully confirmed by Attirely. Thank you for choosing us.',
      type: 'payment',
      priority: 'important',
      createdAt: DateTime.now().subtract(
        const Duration(hours: 1),
      ),
    ),
    VendorNotification(
      id: '3',
      title: 'New booking received',
      message:
      'You have a new booking! Visit your bookings section to check the details.',
      type: 'booking',
      priority: 'important',
      createdAt: DateTime.now().subtract(
        const Duration(hours: 3),
      ),
    ),
    VendorNotification(
      id: '4',
      title: 'Your subscription expires soon',
      message:
      'Your current subscription will expire in 5 days. Renew your plan to continue enjoying Attirely vendor benefits.',
      type: 'subscription',
      priority: 'urgent',
      createdAt: DateTime.now().subtract(
        const Duration(days: 1),
      ),
    ),
    VendorNotification(
      id: '5',
      title: 'Upload more catalogues',
      message:
      'Your catalogue is almost full! Add more outfits and showcase your collection to customers.',
      type: 'catalogue',
      priority: 'reminder',
      createdAt: DateTime.now().subtract(
        const Duration(days: 1, hours: 3),
      ),
      isRead: true,
    ),
    VendorNotification(
      id: '6',
      title: 'Subscription purchased successfully',
      message:
      'Congratulations! Your vendor subscription has been activated successfully.',
      type: 'payment',
      priority: 'important',
      createdAt: DateTime.now().subtract(
        const Duration(days: 2),
      ),
      isRead: true,
    ),
    VendorNotification(
      id: '7',
      title: 'Listing limit reached',
      message:
      'You have reached your current outfit listing limit. Upgrade your subscription to add more outfits.',
      type: 'limit',
      priority: 'important',
      createdAt: DateTime.now().subtract(
        const Duration(days: 3),
      ),
    ),
    VendorNotification(
      id: '8',
      title: 'Explore vendor subscription plans',
      message:
      'Unlock more catalogue space and additional benefits with an Attirely vendor subscription.',
      type: 'subscription',
      priority: 'reminder',
      createdAt: DateTime.now().subtract(
        const Duration(days: 4),
      ),
      isRead: true,
    ),
    VendorNotification(
      id: '9',
      title: 'Your subscription has expired',
      message:
      'Your subscription has expired. Renew your plan to continue managing your catalogue.',
      type: 'subscription',
      priority: 'urgent',
      createdAt: DateTime.now().subtract(
        const Duration(days: 7),
      ),
      isRead: true,
    ),
    VendorNotification(
      id: '10',
      title: 'Welcome to Attirely!',
      message:
      'Discover new opportunities, grow your rental business and reach more customers with Attirely.',
      type: 'announcement',
      priority: 'general',
      createdAt: DateTime.now().subtract(
        const Duration(days: 12),
      ),
      isRead: true,
    ),
  ];

  int get unreadCount =>
      notifications.where((n) => !n.isRead).length;

  void markAsRead(String id) {
    final item = notifications.firstWhere(
          (n) => n.id == id,
    );
    item.isRead = true;
    notifyListeners();
  }

  void markAllAsRead() {
    for (final item in notifications) {
      item.isRead = true;
    }
    notifyListeners();
  }
}

class VendorNotifications extends StatefulWidget {
  const VendorNotifications({super.key});

  @override
  State<VendorNotifications> createState() =>
      _VendorNotificationsState();
}

class _VendorNotificationsState
    extends State<VendorNotifications> {
  static const Color burgundy = Color(0xFF800020);
  static const Color gold = Color(0xFFD4AF37);
  static const Color background = Color(0xFFFFF8F5);
  static const Color muted = Color(0xFF8D7379);

  final store = VendorNotificationStore.instance;

  @override
  void initState() {
    super.initState();

    // Keep only notifications from the last 60 days.
    store.notifications.removeWhere(
          (n) => DateTime.now().difference(n.createdAt).inDays >= 60,
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case 'request':
        return Icons.shopping_bag_outlined;
      case 'payment':
        return Icons.account_balance_wallet_outlined;
      case 'booking':
        return Icons.event_available_outlined;
      case 'subscription':
        return Icons.workspace_premium_outlined;
      case 'catalogue':
        return Icons.checkroom_outlined;
      case 'limit':
        return Icons.inventory_2_outlined;
      default:
        return Icons.campaign_outlined;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'request':
      case 'booking':
        return burgundy;
      case 'payment':
        return const Color(0xFF34835A);
      case 'subscription':
        return const Color(0xFFB18435);
      case 'catalogue':
        return const Color(0xFF7951A2);
      case 'limit':
        return const Color(0xFFE08A24);
      default:
        return const Color(0xFF52799A);
    }
  }

  String _time(DateTime date) {
    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  String _group(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final notificationDate =
    DateTime(date.year, date.month, date.day);

    if (notificationDate == today) return 'Today';
    if (notificationDate ==
        today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return 'Earlier';
  }

  void _openNotification(VendorNotification notification) {
    store.markAsRead(notification.id);

    switch (notification.type) {
      case 'request':
        Navigator.pushNamed(context, AppRoutes.vendorRequests);
        break;
      case 'booking':
        Navigator.pushNamed(context, AppRoutes.vendorBookings);
        break;
      case 'catalogue':
        Navigator.pushNamed(context, AppRoutes.addOutfit);
        break;
      case 'subscription':
      case 'limit':
        Navigator.pushNamed(context, AppRoutes.vendorUpgrade);
        break;
      default:
      // Payment details and announcements are placeholders.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final items = store.notifications;

            return Column(
              children: [
                _header(),
                Expanded(
                  child: items.isEmpty
                      ? _emptyState()
                      : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      18, 18, 18, 30,
                    ),
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your activity',
                            style: TextStyle(
                              color: burgundy,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (store.unreadCount > 0)
                            TextButton(
                              onPressed: store.markAllAsRead,
                              child: const Text(
                                'Mark all as read',
                                style: TextStyle(
                                  color: burgundy,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._buildGroupedItems(items),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 23),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF800020),
            Color(0xFF541126),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(27),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Expanded(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: store,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '${store.unreadCount} unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Padding(
            padding: EdgeInsets.only(left: 13),
            child: Text(
              'Stay updated with your store activity',
              style: TextStyle(
                color: Color(0xFFF1DDE3),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedItems(
      List<VendorNotification> items,
      ) {
    final groups = <String, List<VendorNotification>>{
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    for (final item in items) {
      groups[_group(item.createdAt)]!.add(item);
    }

    final widgets = <Widget>[];

    for (final group in groups.entries) {
      if (group.value.isEmpty) continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(
            top: 17,
            bottom: 10,
          ),
          child: Text(
            group.key,
            style: const TextStyle(
              color: burgundy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );

      for (final item in group.value) {
        widgets.add(_notificationCard(item));
      }
    }

    return widgets;
  }

  Widget _notificationCard(VendorNotification item) {
    final color = _color(item.type);

    return GestureDetector(
      onTap: () => _openNotification(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead
              ? Colors.white.withOpacity(0.88)
              : const Color(0xFFF8EDEF),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: item.isRead
                ? burgundy.withOpacity(0.07)
                : burgundy.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: burgundy.withOpacity(0.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: color.withOpacity(0.11),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                _icon(item.type),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            color: Color(0xFF321D25),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(
                            top: 5,
                            left: 5,
                          ),
                          decoration: const BoxDecoration(
                            color: burgundy,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.message,
                    style: const TextStyle(
                      color: Color(0xFF76666B),
                      fontSize: 11.5,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Text(
                        _time(item.createdAt),
                        style: const TextStyle(
                          color: muted,
                          fontSize: 10,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item.priority.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              color: const Color(0xFFF4E6E9),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 43,
              color: burgundy,
            ),
          ),
          const SizedBox(height: 17),
          const Text(
            'You’re all caught up!',
            style: TextStyle(
              color: burgundy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'New updates will appear here.',
            style: TextStyle(
              color: muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
