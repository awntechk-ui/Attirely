
import 'package:flutter/foundation.dart';

import '../U_API_Routes/u_trial_api_routes.dart';


class MyTrialsLogic extends ChangeNotifier {
  List<Map<String, dynamic>> _trials = [];

  bool isLoading = false;
  String? errorMessage;

  String selectedFilter = 'All';
  String searchQuery = '';

  final List<String> filters = [
    'All',
    'Pending',
    'Accepted',
    'Completed',
    'Rejected',
  ];

  List<Map<String, dynamic>> get trials =>
      List.unmodifiable(_trials);

  Future<void> loadTrials() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _trials = await UserTrialApiRoutes.getMyTrials();
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String filter) {
    selectedFilter = filter;
    notifyListeners();
  }

  void setSearch(String value) {
    searchQuery = value.trim().toLowerCase();
    notifyListeners();
  }

  int countFor(String filter) {
    if (filter == 'All') return _trials.length;

    return _trials.where((trial) {
      return _status(trial) == filter.toLowerCase();
    }).length;
  }

  String _status(Map<String, dynamic> trial) {
    return (trial['status'] ?? 'pending')
        .toString()
        .toLowerCase();
  }

  List<Map<String, dynamic>> get filteredTrials {
    return _trials.where((trial) {
      final status = _status(trial);

      final matchesFilter = selectedFilter == 'All' ||
          status == selectedFilter.toLowerCase();

      final outfit = _outfit(trial);
      final vendor = _vendor(trial);

      final searchable = [
        trial['booking_reference'],
        trial['outfit_name'],
        outfit['name'],
        outfit['brand'],
        vendor['store_name'],
      ].join(' ').toLowerCase();

      final matchesSearch =
          searchQuery.isEmpty || searchable.contains(searchQuery);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  List<Map<String, dynamic>> get groupedTrials {
    final groups = <String, List<Map<String, dynamic>>>{};

    for (final trial in filteredTrials) {
      final reference =
          trial['booking_reference']?.toString() ?? 'Unknown';

      groups.putIfAbsent(reference, () => []).add(trial);
    }

    return groups.entries.map((entry) {
      final rows = entry.value;

      rows.sort((a, b) {
        final aDate = DateTime.tryParse(
          a['created_at']?.toString() ?? '',
        );
        final bDate = DateTime.tryParse(
          b['created_at']?.toString() ?? '',
        );

        return (bDate ?? DateTime(2000))
            .compareTo(aDate ?? DateTime(2000));
      });

      return {
        'booking_reference': entry.key,
        'booked_on': rows.first['created_at'],
        'total_outfits': rows.length,
        'outfits': rows,
      };
    }).toList();
  }

  Map<String, dynamic> outfitOf(Map<String, dynamic> trial) =>
      _outfit(trial);

  Map<String, dynamic> vendorOf(Map<String, dynamic> trial) =>
      _vendor(trial);

  Map<String, dynamic> _outfit(Map<String, dynamic> trial) {
    final value = trial['outfit'];
    return value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }

  Map<String, dynamic> _vendor(Map<String, dynamic> trial) {
    final value = trial['vendor'];
    return value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }

  String imageOf(Map<String, dynamic> trial) {
    final outfit = _outfit(trial);

    final cover = outfit['cover_image_url']?.toString() ?? '';
    if (cover.isNotEmpty) return cover;

    final images = outfit['images'];

    if (images is List) {
      for (final image in images) {
        if (image is Map && image['is_cover'] == true) {
          final url = image['image_url']?.toString() ?? '';
          if (url.isNotEmpty) return url;
        }
      }

      if (images.isNotEmpty && images.first is Map) {
        return images.first['image_url']?.toString() ?? '';
      }
    }

    return '';
  }

  String addressOf(Map<String, dynamic> trial) {
    final address = trial['trial_address'];

    if (address is! Map) return '';

    return [
      address['house'],
      address['street'],
      address['landmark'],
      address['city'],
      address['state'],
      address['pincode'],
    ].where((part) {
      return part != null && part.toString().trim().isNotEmpty;
    }).join(', ');
  }

  String dateLabel(dynamic value) {
    if (value == null) return 'Date not available';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String money(dynamic value) {
    final amount = value is num
        ? value
        : num.tryParse(value?.toString() ?? '') ?? 0;

    return '₹${amount.toStringAsFixed(0)}';
  }
}
