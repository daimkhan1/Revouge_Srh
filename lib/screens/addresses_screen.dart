// Location: lib/screens/addresses_screen.dart
import 'package:flutter/material.dart';
import '../data/address_store.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    globalAddressBook.addListener(_refresh);
  }

  @override
  void dispose() {
    globalAddressBook.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final addresses = globalAddressBook.addresses;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Addresses'),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _glassCard(
            child: Column(
              children: [
                if (addresses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No addresses yet. Add one below.'),
                  ),
                for (final a in addresses)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      a.isDefault ? Icons.check_circle : Icons.location_on_outlined,
                      color: a.isDefault ? Colors.green : Colors.black54,
                    ),
                    title: Text(a.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${a.line1}, ${a.city} ${a.postalCode}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'default') {
                          globalAddressBook.setDefault(a.id);
                        } else if (value == 'edit') {
                          _showAddressEditor(context, address: a);
                        } else if (value == 'delete') {
                          globalAddressBook.remove(a.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'default', child: Text('Set Default')),
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddressEditor(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Address'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressEditor(BuildContext context, {Address? address}) {
    final label = TextEditingController(text: address?.label ?? '');
    final line1 = TextEditingController(text: address?.line1 ?? '');
    final line2 = TextEditingController(text: address?.line2 ?? '');
    final city = TextEditingController(text: address?.city ?? '');
    final postal = TextEditingController(text: address?.postalCode ?? '');
    final country = TextEditingController(text: address?.country ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(address == null ? 'Add Address' : 'Edit Address',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: label, decoration: const InputDecoration(labelText: 'Label')),
              const SizedBox(height: 8),
              TextField(controller: line1, decoration: const InputDecoration(labelText: 'Address line 1')),
              const SizedBox(height: 8),
              TextField(controller: line2, decoration: const InputDecoration(labelText: 'Address line 2')),
              const SizedBox(height: 8),
              TextField(controller: city, decoration: const InputDecoration(labelText: 'City')),
              const SizedBox(height: 8),
              TextField(controller: postal, decoration: const InputDecoration(labelText: 'Postal code')),
              const SizedBox(height: 8),
              TextField(controller: country, decoration: const InputDecoration(labelText: 'Country')),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  onPressed: () {
                    if (label.text.trim().isEmpty || line1.text.trim().isEmpty) return;
                    if (address == null) {
                      globalAddressBook.add(
                        Address(
                          id: globalAddressBook.newId(),
                          label: label.text,
                          line1: line1.text,
                          line2: line2.text,
                          city: city.text,
                          postalCode: postal.text,
                          country: country.text,
                        ),
                      );
                    } else {
                      globalAddressBook.update(
                        Address(
                          id: address.id,
                          label: label.text,
                          line1: line1.text,
                          line2: line2.text,
                          city: city.text,
                          postalCode: postal.text,
                          country: country.text,
                          isDefault: address.isDefault,
                        ),
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}
