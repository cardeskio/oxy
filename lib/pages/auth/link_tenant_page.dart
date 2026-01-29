import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/models/tenant.dart';
import 'package:oxy/models/lease.dart';
import 'package:oxy/models/property.dart';
import 'package:oxy/models/unit.dart';
import 'package:oxy/services/auth_service.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/services/org_service.dart';
import 'package:oxy/theme.dart';
import 'package:uuid/uuid.dart';

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
  String? _error;
  
  // Link mode: 'new' creates new tenant, 'existing' links to existing tenant
  String _linkMode = 'new';
  Tenant? _selectedExistingTenant;
  bool _updateExistingDetails = true; // Whether to update existing tenant's details from user profile
  
  // Unit selection
  Property? _selectedProperty;
  Unit? _selectedUnit;
  DateTime _leaseStartDate = DateTime.now();
  DateTime? _leaseEndDate;

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

  Future<void> _selectLeaseStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _leaseStartDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _leaseStartDate = date);
    }
  }

  Future<void> _selectLeaseEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _leaseEndDate ?? _leaseStartDate.add(const Duration(days: 365)),
      firstDate: _leaseStartDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() => _leaseEndDate = date);
    }
  }

  Future<void> _linkTenant() async {
    if (_claimData == null) return;

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

    // Validate based on mode
    if (_linkMode == 'new' && (_selectedProperty == null || _selectedUnit == null)) {
      setState(() => _error = 'Please select a property and unit');
      return;
    }
    
    if (_linkMode == 'existing' && _selectedExistingTenant == null) {
      setState(() => _error = 'Please select an existing tenant to link');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dataService = context.read<DataService>();
      final now = DateTime.now();
      final userId = _claimData!['user_id'] as String;
      
      // Get details from claim code (profile snapshot)
      final userName = _claimData!['user_name'] as String? ?? 'Unknown';
      final userEmail = _claimData!['user_email'] as String?;
      final userPhone = _claimData!['user_phone'] as String? ?? '';

      String tenantId;

      if (_linkMode == 'existing') {
        // Link to existing tenant
        tenantId = _selectedExistingTenant!.id;
        
        // Update existing tenant with user link
        final updatedTenant = _selectedExistingTenant!.copyWith(
          userId: userId,
          // Optionally update details from user's profile
          fullName: _updateExistingDetails ? userName : null,
          email: _updateExistingDetails ? userEmail : null,
          phone: _updateExistingDetails && userPhone.isNotEmpty ? userPhone : null,
          updatedAt: now,
        );
        
        await dataService.updateTenant(updatedTenant);
      } else {
        // Create new tenant
        tenantId = const Uuid().v4();
        
        final tenant = Tenant(
          id: tenantId,
          orgId: orgId,
          fullName: userName,
          phone: userPhone,
          email: userEmail,
          userId: userId,
          createdAt: now,
          updatedAt: now,
        );

        await dataService.addTenant(tenant);

        // Create lease for new tenant
        final lease = Lease(
          id: const Uuid().v4(),
          orgId: orgId,
          tenantId: tenantId,
          propertyId: _selectedProperty!.id,
          unitId: _selectedUnit!.id,
          startDate: _leaseStartDate,
          endDate: _leaseEndDate,
          rentAmount: _selectedUnit!.rentAmount,
          depositAmount: _selectedUnit!.rentAmount, // Default to 1 month rent
          dueDay: 1, // Due on 1st of month
          graceDays: 5, // 5 day grace period
          lateFeeType: LateFeeType.none,
          status: LeaseStatus.active,
          createdAt: now,
          updatedAt: now,
        );

        await dataService.addLease(lease);
      }

      // Claim the code (link user to tenant)
      final claimSuccess = await _authService.claimTenantProfile(
        code: _codeController.text.trim().toUpperCase(),
        tenantId: tenantId,
        orgId: orgId,
      );

      if (!claimSuccess) {
        throw Exception('Failed to link tenant account');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_linkMode == 'existing' 
                ? 'Tenant account linked successfully!' 
                : 'Tenant created and linked successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      debugPrint('Error linking tenant: $e');
      setState(() => _error = 'Failed to link tenant. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildReadOnlyField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        title: Text('Link Tenant', style: Theme.of(context).appBarTheme.titleTextStyle),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<DataService>(
        builder: (context, dataService, _) {
          final properties = dataService.properties;
          final availableUnits = _selectedProperty != null
              ? dataService.units
                  .where((u) => u.propertyId == _selectedProperty!.id)
                  .where((u) {
                    // Check if unit has an active lease
                    final hasActiveLease = dataService.leases.any(
                      (l) => l.unitId == u.id && l.status == LeaseStatus.active,
                    );
                    return !hasActiveLease;
                  })
                  .toList()
              : <Unit>[];

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
                        const Icon(Icons.info_outline, color: AppColors.info),
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
                                'Enter the code from your tenant, fill in their details, and assign them to a unit.',
                                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Code input
                  Text(
                    'Tenant Claim Code',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                            if (_error != null) setState(() => _error = null);
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
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Look Up'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Show form after valid code found
                  if (_claimData != null) ...[
                    // User info card
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
                              const Icon(Icons.check_circle, color: AppColors.success),
                              const SizedBox(width: 8),
                              const Text(
                                'Valid Code Found',
                                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.success),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
                                child: Text(
                                  (_claimData!['user_name'] as String? ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _claimData!['user_name'] as String? ?? 'Unknown User',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    if (_claimData!['user_email'] != null)
                                      Text(
                                        _claimData!['user_email'] as String,
                                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tenant details section (read-only from profile)
                    Text(
                      'Tenant Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'These details are managed by the tenant',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),

                    _buildReadOnlyField(
                      icon: Icons.person_outline,
                      label: 'Full Name',
                      value: _claimData!['user_name'] as String? ?? 'Not provided',
                    ),
                    const SizedBox(height: 12),

                    _buildReadOnlyField(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: _claimData!['user_email'] as String? ?? 'Not provided',
                    ),
                    const SizedBox(height: 12),

                    _buildReadOnlyField(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: _claimData!['user_phone'] as String? ?? 'Not provided yet',
                    ),
                    const SizedBox(height: 24),

                    // Link mode selection
                    Text(
                      'Link Mode',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose how to link this user account',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    
                    // Mode selector
                    Row(
                      children: [
                        Expanded(
                          child: _LinkModeCard(
                            title: 'New Tenant',
                            subtitle: 'Create new profile & assign unit',
                            icon: Icons.person_add_outlined,
                            isSelected: _linkMode == 'new',
                            onTap: () => setState(() {
                              _linkMode = 'new';
                              _selectedExistingTenant = null;
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LinkModeCard(
                            title: 'Existing Tenant',
                            subtitle: 'Link to tenant you created',
                            icon: Icons.link_outlined,
                            isSelected: _linkMode == 'existing',
                            onTap: () => setState(() {
                              _linkMode = 'existing';
                              _selectedProperty = null;
                              _selectedUnit = null;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Existing tenant selection (when mode is 'existing')
                    if (_linkMode == 'existing') ...[
                      Text(
                        'Select Existing Tenant',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose a tenant profile that was manually created (without a linked user account)',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      
                      // Existing tenant dropdown
                      Builder(builder: (context) {
                        final unlinkedTenants = dataService.tenants
                            .where((t) => t.userId == null)
                            .toList();
                        
                        if (unlinkedTenants.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: AppColors.warning),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No unlinked tenants found. All your tenants already have user accounts linked.',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<Tenant>(
                              value: _selectedExistingTenant,
                              decoration: const InputDecoration(
                                labelText: 'Select Tenant *',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              items: unlinkedTenants.map((t) {
                                final lease = dataService.getActiveLeaseForTenant(t.id);
                                final unit = lease != null ? dataService.getUnitById(lease.unitId) : null;
                                return DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    '${t.fullName}${unit != null ? ' - ${unit.unitLabel}' : ' (no unit)'}',
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _selectedExistingTenant = value),
                            ),
                            const SizedBox(height: 16),
                            
                            // Update details checkbox
                            CheckboxListTile(
                              value: _updateExistingDetails,
                              onChanged: (v) => setState(() => _updateExistingDetails = v ?? true),
                              title: const Text('Update tenant details from user profile'),
                              subtitle: Text(
                                'Replace name, email, phone with user\'s own details',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            
                            // Show what will be linked
                            if (_selectedExistingTenant != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Current Tenant Info',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildComparisonRow('Name', _selectedExistingTenant!.fullName, _claimData!['user_name'] as String? ?? 'Unknown'),
                                    _buildComparisonRow('Phone', _selectedExistingTenant!.phone, _claimData!['user_phone'] as String? ?? 'Not set'),
                                    _buildComparisonRow('Email', _selectedExistingTenant!.email ?? 'Not set', _claimData!['user_email'] as String? ?? 'Not set'),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    // Unit assignment section (only for new tenant mode)
                    if (_linkMode == 'new') ...[
                      Text(
                        'Assign Unit',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Property dropdown (only show for new mode)
                    if (_linkMode == 'new') ...[
                      DropdownButtonFormField<Property>(
                        value: _selectedProperty,
                        decoration: const InputDecoration(
                          labelText: 'Property *',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                        items: properties.map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.name),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedProperty = value;
                            _selectedUnit = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Unit dropdown
                      DropdownButtonFormField<Unit>(
                        value: _selectedUnit,
                        decoration: InputDecoration(
                          labelText: 'Unit *',
                          prefixIcon: const Icon(Icons.door_front_door_outlined),
                          helperText: _selectedProperty == null
                              ? 'Select a property first'
                              : availableUnits.isEmpty
                                  ? 'No available units'
                                  : null,
                        ),
                        items: availableUnits.map((u) => DropdownMenuItem(
                          value: u,
                          child: Text('${u.unitLabel} - KES ${u.rentAmount.toStringAsFixed(0)}/mo'),
                        )).toList(),
                        onChanged: _selectedProperty == null ? null : (value) {
                          setState(() => _selectedUnit = value);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Lease dates
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectLeaseStartDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Start Date',
                                  prefixIcon: Icon(Icons.calendar_today_outlined),
                                ),
                                child: Text(
                                  '${_leaseStartDate.day}/${_leaseStartDate.month}/${_leaseStartDate.year}',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: _selectLeaseEndDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'End Date (Optional)',
                                  prefixIcon: Icon(Icons.event_outlined),
                                ),
                                child: Text(
                                  _leaseEndDate != null
                                      ? '${_leaseEndDate!.day}/${_leaseEndDate!.month}/${_leaseEndDate!.year}'
                                      : 'Open-ended',
                                  style: TextStyle(
                                    color: _leaseEndDate == null ? colorScheme.onSurfaceVariant : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _canSubmit ? _linkTenant : null,
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _linkMode == 'existing' 
                                    ? 'Link to Existing Tenant' 
                                    : 'Create & Link Tenant',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            );
        },
      ),
    );
  }

  bool get _canSubmit {
    if (_claimData == null) return false;
    if (_linkMode == 'new') {
      return _selectedProperty != null && _selectedUnit != null;
    } else {
      return _selectedExistingTenant != null;
    }
  }

  Widget _buildComparisonRow(String label, String current, String fromUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              current,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (_updateExistingDetails && current != fromUser) ...[
            const Icon(Icons.arrow_forward, size: 12, color: AppColors.primaryTeal),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                fromUser,
                style: const TextStyle(fontSize: 12, color: AppColors.primaryTeal, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LinkModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _LinkModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primaryTeal.withValues(alpha: 0.1) 
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primaryTeal : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primaryTeal : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
