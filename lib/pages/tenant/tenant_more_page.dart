import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/services/auth_service.dart';
import 'package:oxy/services/tenant_service.dart';
import 'package:oxy/services/living_service.dart';

class TenantMorePage extends StatelessWidget {
  const TenantMorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, TenantService>(
      builder: (context, authService, tenantService, _) {
        final hasUnit = authService.tenantLinks.isNotEmpty;
        final hasMultipleProperties = tenantService.hasMultipleLinks;
        final claimCode = authService.claimCode;
        
        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            title: const Text('More'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Claim Code Card (only shown if NOT linked to any property)
              if (!hasUnit && claimCode != null) ...[
                _ClaimCodeCard(claimCode: claimCode.code),
                const SizedBox(height: 24),
              ],
              
              // Property switcher (only shown if linked to multiple properties)
              if (hasMultipleProperties) ...[
                _PropertySwitcher(tenantService: tenantService),
                const SizedBox(height: 24),
              ],
              
              // My Unit Section (only shown if linked to a property)
              if (hasUnit) ...[
                _MenuSection(
                  title: 'MY UNIT',
                  items: [
                    _MenuItem(
                      icon: Icons.description_outlined,
                      iconColor: AppColors.primaryTeal,
                      title: 'View My Lease',
                      onTap: () => context.push('/tenant/lease'),
                    ),
                    _MenuItem(
                      icon: Icons.build_outlined,
                      iconColor: AppColors.warning,
                      title: 'Maintenance Requests',
                      onTap: () => context.push('/tenant/maintenance'),
                    ),
                    _MenuItem(
                      icon: Icons.exit_to_app_outlined,
                      iconColor: AppColors.error,
                      title: 'Request Move-Out',
                      onTap: () => context.push('/tenant/move-out'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              
              // Explore Section (only for users without a unit)
              if (!hasUnit) ...[
                _MenuSection(
                  title: 'EXPLORE',
                  items: [
                    _MenuItem(
                      icon: Icons.search,
                      iconColor: AppColors.primaryTeal,
                      title: 'Browse Properties',
                      onTap: () => context.go('/tenant/explore'),
                    ),
                    _MenuItem(
                      icon: Icons.mail_outline,
                      iconColor: AppColors.info,
                      title: 'My Enquiries',
                      onTap: () => context.go('/tenant/enquiries'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              
              // Account Section
              _MenuSection(
                title: 'ACCOUNT',
                items: [
                  _MenuItem(
                    icon: Icons.person_outline,
                    iconColor: AppColors.info,
                    title: 'Edit Profile',
                    onTap: () => context.push('/tenant/profile'),
                  ),
                  _MenuItem(
                    icon: Icons.local_shipping_outlined,
                    iconColor: AppColors.primaryTeal,
                    title: 'Delivery Settings',
                    onTap: () => _showDeliverySettingsSheet(context),
                  ),
                  _MenuItem(
                    icon: Icons.logout,
                    iconColor: AppColors.error,
                    title: 'Sign Out',
                    onTap: () async {
                      await authService.signOut();
                      tenantService.clear();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // App info
              Center(
                child: Column(
                  children: [
                    Text(
                      'Oxy - Tenant Portal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }
}

class _ClaimCodeCard extends StatelessWidget {
  final String claimCode;

  const _ClaimCodeCard({required this.claimCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryTeal, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.key, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Claim Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Share with your property manager',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  claimCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: claimCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Copy code',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Once your manager links your account, you\'ll have full access to your rental information.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.lightOnSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return Column(
                children: [
                  entry.value,
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 56,
                      color: AppColors.lightOutline,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}

class _PropertySwitcher extends StatelessWidget {
  final TenantService tenantService;

  const _PropertySwitcher({required this.tenantService});

  @override
  Widget build(BuildContext context) {
    final links = tenantService.tenantLinks;
    final currentLink = tenantService.currentLink;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_horiz,
                color: AppColors.primaryTeal,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Switch Property',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You are linked to multiple properties. Select which one to view.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.lightOnSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ...links.map((link) {
            final isSelected = currentLink?.id == link.id;
            return InkWell(
              onTap: isSelected 
                  ? null 
                  : () async {
                      await tenantService.selectTenantLink(link.id);
                    },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryTeal : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected ? AppColors.primaryTeal.withValues(alpha: 0.05) : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.apartment,
                        color: AppColors.primaryTeal,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            link.orgName ?? 'Property',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.primaryTeal : null,
                            ),
                          ),
                          Text(
                            'Linked ${_formatDate(link.createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.lightOnSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.primaryTeal,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }
}

void _showDeliverySettingsSheet(BuildContext context) {
  final livingService = context.read<LivingService>();
  livingService.loadDeliverySettings();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final apartmentController = TextEditingController();
  final unitController = TextEditingController();
  final instructionsController = TextEditingController();
  bool isLoading = false;
  bool isSaving = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        // Load existing settings
        if (!isLoading) {
          isLoading = true;
          livingService.loadDeliverySettings().then((_) {
            final settings = livingService.deliverySettings;
            if (settings != null) {
              nameController.text = settings.defaultName ?? '';
              phoneController.text = settings.defaultPhone ?? '';
              addressController.text = settings.defaultAddress ?? '';
              apartmentController.text = settings.defaultApartment ?? '';
              unitController.text = settings.defaultUnit ?? '';
              instructionsController.text = settings.defaultInstructions ?? '';
            }
            setState(() {});
          });
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined, color: AppColors.primaryTeal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Delivery Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Save your details for faster checkout',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Contact Info Section
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '+254...',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    // Address Section
                    const Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address/Location',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: apartmentController,
                            decoration: const InputDecoration(
                              labelText: 'Building/Apartment',
                              prefixIcon: Icon(Icons.apartment_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: unitController,
                            decoration: const InputDecoration(
                              labelText: 'Unit/Room',
                              prefixIcon: Icon(Icons.door_front_door_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: instructionsController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Instructions',
                        hintText: 'e.g., Gate code, landmarks, etc.',
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // Info card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'These details will be automatically filled when you checkout on orders.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),

              // Save button
              Container(
                padding: EdgeInsets.fromLTRB(
                  16, 
                  16, 
                  16, 
                  16 + MediaQuery.of(context).viewPadding.bottom,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setState(() => isSaving = true);
                              try {
                                await livingService.saveDeliverySettings(
                                  name: nameController.text,
                                  phone: phoneController.text,
                                  address: addressController.text,
                                  apartment: apartmentController.text.isEmpty
                                      ? null
                                      : apartmentController.text,
                                  unit: unitController.text.isEmpty
                                      ? null
                                      : unitController.text,
                                  instructions: instructionsController.text.isEmpty
                                      ? null
                                      : instructionsController.text,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Delivery settings saved'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() => isSaving = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Settings',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}
