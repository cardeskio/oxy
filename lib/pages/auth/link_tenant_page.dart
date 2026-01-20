import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/services/auth_service.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/services/org_service.dart';
import 'package:oxy/theme.dart';

/// Page for property owners to link a tenant using their claim code
class LinkTenantPage extends StatefulWidget {
  final String? prefilledCode;

  const LinkTenantPage({super.key, this.prefilledCode});

  @override
  State<LinkTenantPage> createState() => _LinkTenantPageState();
}

class _LinkTenantPageState extends State<LinkTenantPage> {
  final _codeController = TextEditingController();
  final _authService = AuthService();
  final _orgService = OrgService();
  
  bool _isLoading = false;
  bool _isLookingUp = false;
  Map<String, dynamic>? _claimData;
  String? _selectedTenantId;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledCode != null) {
      _codeController.text = widget.prefilledCode!;
      _lookupCode();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _lookupCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Please enter a valid 6-character code');
      return;
    }

    setState(() {
      _isLookingUp = true;
      _error = null;
      _claimData = null;
    });

    try {
      final data = await _authService.lookupClaimCode(code);
      
      if (data == null) {
        setState(() => _error = 'Code not found. Please check and try again.');
      } else {
        final claimCode = TenantClaimCode.fromJson(data);
        if (claimCode.isClaimed) {
          setState(() => _error = 'This code has already been claimed.');
        } else if (claimCode.isExpired) {
          setState(() => _error = 'This code has expired. Ask the tenant for a new code.');
        } else {
          setState(() => _claimData = data);
        }
      }
    } catch (e) {
      setState(() => _error = 'Failed to look up code. Please try again.');
    } finally {
      if (mounted) setState(() => _isLookingUp = false);
    }
  }

  Future<void> _linkTenant() async {
    if (_selectedTenantId == null || _claimData == null) return;

    final orgId = _orgService.currentOrgId;
    if (orgId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No organization selected'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _authService.claimTenantProfile(
        code: _codeController.text.trim().toUpperCase(),
        tenantId: _selectedTenantId!,
        orgId: orgId,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tenant linked successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        setState(() => _error = 'Failed to link tenant. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Link Tenant Account'),
      ),
      body: Consumer<DataService>(
        builder: (context, dataService, _) {
          final tenants = dataService.tenants
              .where((t) => t.userId == null) // Only unlinked tenants
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructions card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Link a Tenant Account',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.info,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter the 6-digit code provided by your tenant to link their account with their rental profile.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Code input
                const Text(
                  'Tenant Claim Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 6,
                        style: const TextStyle(
                          fontSize: 20,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'ABC123',
                          counterText: '',
                          prefixIcon: const Icon(Icons.vpn_key_outlined),
                          errorText: _error,
                        ),
                        onChanged: (_) {
                          if (_error != null) {
                            setState(() => _error = null);
                          }
                        },
                        onSubmitted: (_) => _lookupCode(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLookingUp ? null : _lookupCode,
                        child: _isLookingUp
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Look Up'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Claim data display
                if (_claimData != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Valid Code Found',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_claimData!['profiles'] != null) ...[
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
                                child: Text(
                                  (_claimData!['profiles']['full_name'] as String? ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryTeal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _claimData!['profiles']['full_name'] as String? ?? 'Unknown User',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_claimData!['profiles']['email'] != null)
                                      Text(
                                        _claimData!['profiles']['email'] as String,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Select tenant
                  const Text(
                    'Select Tenant Profile to Link',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (tenants.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'No Unlinked Tenants',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'All existing tenant profiles are already linked to user accounts. Create a new tenant profile first.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tenants.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final tenant = tenants[index];
                        final isSelected = _selectedTenantId == tenant.id;
                        
                        // Get active lease for this tenant
                        final activeLease = dataService.getActiveLeaseForTenant(tenant.id);
                        String? unitInfo;
                        if (activeLease != null) {
                          final unit = dataService.getUnitById(activeLease.unitId);
                          final property = dataService.getPropertyById(activeLease.propertyId);
                          if (unit != null && property != null) {
                            unitInfo = '${property.name} - ${unit.unitLabel}';
                          }
                        }

                        return InkWell(
                          onTap: () => setState(() => _selectedTenantId = tenant.id),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
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
                                Radio<String>(
                                  value: tenant.id,
                                  groupValue: _selectedTenantId,
                                  onChanged: (value) => setState(() => _selectedTenantId = value),
                                  activeColor: AppColors.primaryTeal,
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
                                  child: Text(
                                    tenant.initials,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryTeal,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tenant.fullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone_outlined,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            tenant.phone,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (unitInfo != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.home_outlined,
                                              size: 14,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                unitInfo,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),

                  // Link button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _selectedTenantId == null || _isLoading ? null : _linkTenant,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Link Tenant Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
