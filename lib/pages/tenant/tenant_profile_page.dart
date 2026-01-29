import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/services/auth_service.dart';
import 'package:oxy/services/tenant_service.dart';

class TenantProfilePage extends StatefulWidget {
  const TenantProfilePage({super.key});

  @override
  State<TenantProfilePage> createState() => _TenantProfilePageState();
}

class _TenantProfilePageState extends State<TenantProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _kinNameController = TextEditingController();
  final _kinPhoneController = TextEditingController();
  
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _kinNameController.dispose();
    _kinPhoneController.dispose();
    super.dispose();
  }

  void _initializeForm(TenantService tenantService) {
    if (_isInitialized) return;
    
    final tenant = tenantService.currentTenant;
    if (tenant != null) {
      _nameController.text = tenant.fullName;
      _phoneController.text = tenant.phone.replaceFirst('+254', '');
      _kinNameController.text = tenant.nextOfKinName ?? '';
      _kinPhoneController.text = tenant.nextOfKinPhone ?? '';
      _isInitialized = true;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final tenantService = context.read<TenantService>();
      
      String phone = _phoneController.text.trim();
      if (!phone.startsWith('+254')) {
        phone = '+254${phone.replaceFirst(RegExp(r'^0'), '')}';
      }
      
      await tenantService.updateProfile(
        fullName: _nameController.text.trim(),
        phone: phone,
        nextOfKinName: _kinNameController.text.trim().isEmpty ? null : _kinNameController.text.trim(),
        nextOfKinPhone: _kinPhoneController.text.trim().isEmpty ? null : _kinPhoneController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, TenantService>(
      builder: (context, authService, tenantService, _) {
        _initializeForm(tenantService);
        
        final tenant = tenantService.currentTenant;
        final userEmail = authService.currentUser?.email;
        
        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: const Text('Edit Profile'),
          ),
          body: tenant == null
              ? const Center(child: Text('No tenant profile found'))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Profile header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
                              child: Text(
                                tenant.initials,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tenant.fullName,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (userEmail != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      userEmail,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.lightOnSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Personal info
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
                                prefixIcon: Icon(Icons.phone_outlined),
                                prefixText: '+254 ',
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) => value?.trim().isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            // Email is read-only
                            TextFormField(
                              initialValue: userEmail ?? tenant.email ?? '',
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                suffixIcon: const Icon(Icons.lock_outline, size: 18),
                                helperText: 'Email is linked to your account',
                                helperStyle: TextStyle(color: AppColors.lightOnSurfaceVariant),
                              ),
                              enabled: false,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Next of kin
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
                              'Emergency Contact',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _kinNameController,
                              decoration: const InputDecoration(
                                labelText: 'Next of Kin Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _kinPhoneController,
                              decoration: const InputDecoration(
                                labelText: 'Next of Kin Phone',
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
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
