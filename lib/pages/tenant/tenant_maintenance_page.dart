import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/services/tenant_service.dart';
import 'package:oxy/models/maintenance_ticket.dart';
import 'package:oxy/components/empty_state.dart';
import 'package:oxy/components/loading_indicator.dart';
import 'package:oxy/utils/formatters.dart';

class TenantMaintenancePage extends StatefulWidget {
  const TenantMaintenancePage({super.key});

  @override
  State<TenantMaintenancePage> createState() => _TenantMaintenancePageState();
}

class _TenantMaintenancePageState extends State<TenantMaintenancePage> {
  TicketStatus? _filterStatus;
  bool _isSubmitting = false;

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.new_:
        return AppColors.info;
      case TicketStatus.assigned:
        return Colors.orange;
      case TicketStatus.inProgress:
        return Colors.amber;
      case TicketStatus.done:
      case TicketStatus.approved:
        return AppColors.success;
      case TicketStatus.rejected:
        return AppColors.error;
    }
  }

  void _showNewTicketDialog(BuildContext context, TenantService tenantService) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    var selectedPriority = TicketPriority.medium;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report an Issue',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Issue Title',
                  hintText: 'e.g., Leaking faucet',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the issue in detail...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text('Priority', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<TicketPriority>(
                segments: const [
                  ButtonSegment(value: TicketPriority.low, label: Text('Low')),
                  ButtonSegment(value: TicketPriority.medium, label: Text('Medium')),
                  ButtonSegment(value: TicketPriority.high, label: Text('High')),
                ],
                selected: {selectedPriority},
                onSelectionChanged: (selected) {
                  setModalState(() => selectedPriority = selected.first);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill in all fields')),
                            );
                            return;
                          }

                          setModalState(() => _isSubmitting = true);
                          debugPrint('Submit button pressed, submitting ticket...');

                          try {
                            final ticket = await tenantService.submitMaintenanceTicket(
                              title: titleController.text.trim(),
                              description: descriptionController.text.trim(),
                              priority: selectedPriority,
                            );
                            debugPrint('Ticket submitted: ${ticket?.id}');
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Issue reported successfully!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('Error submitting ticket: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setModalState(() => _isSubmitting = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const OxyDotsLoader(dotSize: 6)
                      : const Text('Submit Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TenantService>(
      builder: (context, tenantService, _) {
        if (tenantService.isLoading) {
          return Scaffold(
            backgroundColor: AppColors.lightBackground,
            appBar: AppBar(
              backgroundColor: AppColors.primaryTeal,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/tenant'),
              ),
              title: const Text('Maintenance Requests', style: TextStyle(color: Colors.white)),
            ),
            body: const OxyLoadingOverlay(message: 'Loading requests...'),
          );
        }

        final hasActiveLease = tenantService.activeLease != null && tenantService.unit != null;

        // Filter tickets
        List<MaintenanceTicket> tickets = tenantService.tickets.toList();
        if (_filterStatus != null) {
          tickets = tickets.where((t) => t.status == _filterStatus).toList();
        }

        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.go('/tenant'),
            ),
            title: const Text('Maintenance Requests', style: TextStyle(color: Colors.white)),
          ),
          body: RefreshIndicator(
            onRefresh: () => tenantService.refresh(),
            child: Column(
              children: [
                // Status filter chips
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: _filterStatus == null,
                          onSelected: (_) => setState(() => _filterStatus = null),
                          backgroundColor: AppColors.lightSurfaceVariant,
                          selectedColor: AppColors.primaryTeal,
                          labelStyle: TextStyle(
                            color: _filterStatus == null ? Colors.white : AppColors.lightOnSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('New'),
                          selected: _filterStatus == TicketStatus.new_,
                          onSelected: (_) => setState(() => _filterStatus = TicketStatus.new_),
                          backgroundColor: AppColors.lightSurfaceVariant,
                          selectedColor: AppColors.info,
                          labelStyle: TextStyle(
                            color: _filterStatus == TicketStatus.new_ ? Colors.white : AppColors.lightOnSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('In Progress'),
                          selected: _filterStatus == TicketStatus.inProgress,
                          onSelected: (_) => setState(() => _filterStatus = TicketStatus.inProgress),
                          backgroundColor: AppColors.lightSurfaceVariant,
                          selectedColor: Colors.amber,
                          labelStyle: TextStyle(
                            color: _filterStatus == TicketStatus.inProgress ? Colors.white : AppColors.lightOnSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Done'),
                          selected: _filterStatus == TicketStatus.done,
                          onSelected: (_) => setState(() => _filterStatus = TicketStatus.done),
                          backgroundColor: AppColors.lightSurfaceVariant,
                          selectedColor: AppColors.success,
                          labelStyle: TextStyle(
                            color: _filterStatus == TicketStatus.done ? Colors.white : AppColors.lightOnSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tickets list
                Expanded(
                  child: tickets.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: 400,
                            child: EmptyState(
                              icon: Icons.build_outlined,
                              title: 'No Maintenance Requests',
                              message: _filterStatus != null
                                  ? 'No requests with this status'
                                  : 'Tap the button below to report any issues',
                              actionLabel: hasActiveLease ? 'Report Issue' : null,
                              onAction: hasActiveLease
                                  ? () => _showNewTicketDialog(context, tenantService)
                                  : null,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: tickets.length,
                          itemBuilder: (context, index) {
                            final ticket = tickets[index];
                            return _TicketCard(
                              ticket: ticket,
                              statusColor: _getStatusColor(ticket.status),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: hasActiveLease
              ? FloatingActionButton(
                  onPressed: () => _showNewTicketDialog(context, tenantService),
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
        );
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  final MaintenanceTicket ticket;
  final Color statusColor;

  const _TicketCard({
    required this.ticket,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/tenant/maintenance/${ticket.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ticket.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ticket.statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ticket.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.lightSurfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            size: 14,
                            color: ticket.priority == TicketPriority.high
                                ? AppColors.error
                                : ticket.priority == TicketPriority.medium
                                    ? AppColors.warning
                                    : AppColors.lightOnSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ticket.priorityLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: ticket.priority == TicketPriority.high
                                  ? AppColors.error
                                  : ticket.priority == TicketPriority.medium
                                      ? AppColors.warning
                                      : AppColors.lightOnSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.lightOnSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      Formatters.date(ticket.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
