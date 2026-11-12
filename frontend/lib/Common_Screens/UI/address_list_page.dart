
import 'package:flutter/material.dart';

import '../../User/U_Ui_Logic/trial_address_logic.dart';
import 'add_address_page.dart';

class AddressListPage extends StatefulWidget {
  final bool selectionMode;

  const AddressListPage({
    super.key,
    this.selectionMode = false,
  });

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  static const Color burgundy = Color(0xFF8E2945);

  final logic = TrialAddressLogic.instance;

  @override
  void initState() {
    super.initState();
    logic.loadAddresses(refresh: true);
    logic.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }
  void _selectAddress(Map<String, dynamic> address) {
    logic.selectAddress(address);

    Navigator.pop(
      context,
      address,
    );
  }

  @override
  void dispose() {
    logic.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _openAddAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddAddressPage(),
      ),
    );

    if (result != null && mounted) {
      await logic.loadAddresses(refresh: true);
    }
  }

  Future<void> _openEditAddress(
      Map<String, dynamic> address,
      ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAddressPage(address: address),
      ),
    );

    if (result != null && mounted) {
      await logic.loadAddresses(refresh: true);
    }
  }

  Future<void> _setDefault(String id) async {
    try {
      await logic.setDefaultAddress(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default address updated.'),
        ),
      );
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _deleteAddress(
      Map<String, dynamic> address,
      ) async {
    final id = address['id']?.toString();

    if (id == null || id.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address?'),
        content: const Text(
          'Are you sure you want to delete this address?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await logic.deleteAddress(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address deleted successfully.'),
        ),
      );
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.toString().replaceFirst('Exception: ', ''),
        ),
      ),
    );
  }

  String _addressText(Map<String, dynamic> address) {
    final parts = [
      address['house'],
      address['street'],
      address['landmark'],
      address['city'],
      address['state'],
      address['pincode'],
    ];

    return parts
        .where((part) =>
    part != null && part.toString().trim().isNotEmpty)
        .join(', ');
  }

  Widget _buildAddressCard(Map<String, dynamic> address) {
    final id = address['id']?.toString() ?? '';
    final isDefault = address['is_default'] == true;
    final type = address['address_type']?.toString() ?? 'Home';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDefault ? burgundy : Colors.grey.shade300,
          width: isDefault ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.selectionMode)
                TextButton.icon(
                  onPressed: () => _selectAddress(address),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Select'),
                  style: TextButton.styleFrom(
                    foregroundColor: burgundy,
                  ),
                ),
              Icon(
                type == 'Work'
                    ? Icons.work_outline
                    : type == 'Home'
                    ? Icons.home_outlined
                    : Icons.location_on_outlined,
                color: burgundy,
              ),
              const SizedBox(width: 9),
              Text(
                type,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8EDF1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'DEFAULT',
                    style: TextStyle(
                      color: burgundy,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            address['full_name']?.toString() ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            address['mobile']?.toString() ?? '',
            style: TextStyle(color: Colors.grey.shade700),
          ),

          const SizedBox(height: 8),

          Text(
            _addressText(address),
            style: TextStyle(
              color: Colors.grey.shade800,
              height: 1.5,
            ),
          ),

          if (address['latitude'] != null &&
              address['longitude'] != null) ...[
            const SizedBox(height: 7),
            const Row(
              children: [
                Icon(
                  Icons.location_pin,
                  color: Colors.green,
                  size: 16,
                ),
                SizedBox(width: 5),
                Text(
                  'Map location saved',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],

          const Divider(height: 25),

          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!isDefault)
                TextButton(
                  onPressed: id.isEmpty
                      ? null
                      : () => _setDefault(id),
                  child: const Text(
                    'Set as Default',
                    style: TextStyle(color: burgundy),
                  ),
                ),

              TextButton.icon(
                onPressed: () => _openEditAddress(address),
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: burgundy,
                ),
              ),

              TextButton.icon(
                onPressed: () => _deleteAddress(address),
                icon: const Icon(Icons.delete_outline, size: 17),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F8),
      appBar: AppBar(
        title: const Text(
          'My Addresses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: burgundy,
        elevation: 0,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddAddress,
        backgroundColor: burgundy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add Address'),
      ),

      body: logic.isLoading && logic.addresses.isEmpty
          ? const Center(
        child: CircularProgressIndicator(
          color: burgundy,
        ),
      )
          : logic.errorMessage != null && logic.addresses.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: burgundy,
                size: 45,
              ),
              const SizedBox(height: 12),
              Text(
                logic.errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    logic.loadAddresses(refresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        color: burgundy,
        onRefresh: () =>
            logic.loadAddresses(refresh: true),
        child: logic.addresses.isEmpty
            ? ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 110),
            Icon(
              Icons.location_off_outlined,
              size: 65,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No saved addresses yet.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Add an address to get started.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        )
            : ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            16, 18, 16, 100,
          ),
          children: [
            Text(
              '${logic.addresses.length} Saved Address${logic.addresses.length == 1 ? '' : 'es'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ...logic.addresses.map(
              _buildAddressCard,
            ),
          ],
        ),
      ),
    );
  }
}
