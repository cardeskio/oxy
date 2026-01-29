import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/models/tenant.dart';

class AddTenantPage extends StatefulWidget {
  const AddTenantPage({super.key});

  @override
  State<AddTenantPage> createState() => _AddTenantPageState();
}

class _AddTenantPageState extends State<AddTenantPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();
  final _kinNameController = TextEditingController();
  final _kinPhoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    _kinNameController.dispose();
    _kinPhoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      String phone = _phoneController.text.trim();
      if (!phone.startsWith('+254')) {
        phone = '+254${phone.replaceFirst(RegExp(r'^0'), '')}';
      }
      
      final dataService = context.read<DataService>();
      final orgId = dataService.currentOrgId ?? '';
      
      final tenant = Tenant(
        id: const Uuid().v4(),
        orgId: orgId,
        fullName: _nameController.text.trim(),
        phone: phone,
        idNumber: _idController.text.trim().isEmpty ? null : _idController.text.trim(),
        // Note: email is not set by admin - it comes from the linked user account
        nextOfKinName: _kinNameController.text.trim().isEmpty ? null : _kinNameController.text.trim(),
        nextOfKinPhone: _kinPhoneController.text.trim().isEmpty ? null : _kinPhoneController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await dataService.addTenant(tenant);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tenant.fullName} added successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add Tenant'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value?.trim().isEmpty ?? true ? 'Required' : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      hintText: '07XX XXX XXX',
                      prefixIcon: Icon(Icons.phone_outlined),
                      prefixText: '+254 ',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value?.trim().isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      labelText: 'ID Number',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  // Note: Email is not set here - it comes from tenant's linked account
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next of Kin (Optional)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _kinNameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _kinPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Tenant', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
