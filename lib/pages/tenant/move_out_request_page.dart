import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/services/tenant_service.dart';
import 'package:oxy/models/move_out_request.dart';
import 'package:oxy/utils/formatters.dart';

class MoveOutRequestPage extends StatefulWidget {
  const MoveOutRequestPage({super.key});

  @override
  State<MoveOutRequestPage> createState() => _MoveOutRequestPageState();
}

class _MoveOutRequestPageState extends State<MoveOutRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final minDate = now.add(const Duration(days: 30)); // Minimum 30 days notice
    
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? minDate,
      firstDate: minDate,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Select preferred move-out date',
    );
    
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a move-out date'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tenantService = context.read<TenantService>();
      
      await tenantService.submitMoveOutRequest(
        preferredDate: _selectedDate!,
        reason: _reasonController.text.trim().isEmpty 
            ? null 
            : _reasonController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Move-out request submitted successfully'),
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

  Future<void> _cancelRequest(String requestId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this move-out request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<TenantService>().cancelMoveOutRequest(requestId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request cancelled'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TenantService>(
      builder: (context, tenantService, _) {
        final activeLease = tenantService.activeLease;
        final existingRequests = tenantService.moveOutRequests;
        final hasPendingRequest = existingRequests.any((r) => r.isPending);

        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            title: const Text('Move-Out Request'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Current lease info
              if (activeLease != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Lease',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Lease Start',
                        value: Formatters.date(activeLease.startDate),
                      ),
                      _InfoRow(
                        label: 'Lease End',
                        value: activeLease.endDate != null 
                            ? Formatters.date(activeLease.endDate!) 
                            : 'No end date',
                      ),
                      _InfoRow(
                        label: 'Monthly Rent',
                        value: Formatters.currency(activeLease.rentAmount),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Existing requests
              if (existingRequests.isNotEmpty) ...[
                Text(
                  'Your Requests',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...existingRequests.map((request) => _RequestCard(
                  request: request,
                  onCancel: request.isPending 
                      ? () => _cancelRequest(request.id) 
                      : null,
                )),
                const SizedBox(height: 16),
              ],

              // New request form
              if (!hasPendingRequest && activeLease != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Move-Out Request',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Submit a request to notify your landlord that you intend to move out.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Date picker
                        InkWell(
                          onTap: _selectDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.lightSurfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedDate != null 
                                    ? AppColors.primaryTeal 
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: _selectedDate != null 
                                      ? AppColors.primaryTeal 
                                      : AppColors.lightOnSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Preferred Move-Out Date *',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.lightOnSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedDate != null
                                            ? Formatters.date(_selectedDate!)
                                            : 'Select date (min 30 days notice)',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: _selectedDate != null 
                                              ? FontWeight.w600 
                                              : FontWeight.normal,
                                          color: _selectedDate != null
                                              ? AppColors.lightOnSurface
                                              : AppColors.lightOnSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Reason
                        TextFormField(
                          controller: _reasonController,
                          decoration: const InputDecoration(
                            labelText: 'Reason (Optional)',
                            hintText: 'Why are you moving out?',
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                          maxLines: 3,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Notice box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'A minimum of 30 days notice is required. Your landlord will review and respond to your request.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitRequest,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Submit Request',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (activeLease == null) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: AppColors.lightOnSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Active Lease',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You don\'t have an active lease to request move-out for.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.lightOnSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.lightOnSurfaceVariant),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final MoveOutRequest request;
  final VoidCallback? onCancel;

  const _RequestCard({required this.request, this.onCancel});

  Color get _statusColor {
    switch (request.status) {
      case MoveOutStatus.pending:
        return AppColors.warning;
      case MoveOutStatus.approved:
        return AppColors.success;
      case MoveOutStatus.rejected:
        return AppColors.error;
      case MoveOutStatus.cancelled:
        return AppColors.lightOnSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  request.statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                Formatters.shortDate(request.requestedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.lightOnSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Move-out: ${Formatters.date(request.preferredMoveOutDate)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (request.reason != null && request.reason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              request.reason!,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.lightOnSurfaceVariant,
              ),
            ),
          ],
          if (request.adminNotes != null && request.adminNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.comment, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.adminNotes!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (onCancel != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                child: const Text('Cancel Request'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
