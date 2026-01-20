import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/services/auth_service.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/models/maintenance_ticket.dart';
import 'package:oxy/models/lease.dart';
import 'package:oxy/components/empty_state.dart';
import 'package:oxy/utils/formatters.dart';

class TenantMaintenancePage extends StatefulWidget {
  const TenantMaintenancePage({super.key});

  @override
  State<TenantMaintenancePage> createState() => _TenantMaintenancePageState();
}

class _TenantMaintenancePageState extends State<TenantMaintenancePage> {
  TicketStatus? _filterStatus;

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

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, DataService>(
      builder: (context, authService, dataService, _) {
        // Get tenant's unit ID from their active lease
        String? unitId;
        final tenantLinks = authService.tenantLinks;
        
        if (tenantLinks.isNotEmpty) {
          final tenantId = tenantLinks.first.tenantId;
          final activeLease = dataService.getActiveLeaseForTenant(tenantId);
          unitId = activeLease?.unitId;
        }

        // Filter tickets by tenant's unit
        List<MaintenanceTicket> tickets = unitId != null
            ? dataService.getTicketsForUnit(unitId)
            : [];

        // Apply status filter if selected
        if (_filterStatus != null) {
          tickets = tickets.where((t) => t.status == _filterStatus).toList();
        }

        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            title: const Text('Maintenance Requests', style: TextStyle(color: Colors.white)),
          ),
          body: Column(
            children: [
              // Status filter chips
              Container(
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
                        label: const Text('Assigned'),
                        selected: _filterStatus == TicketStatus.assigned,
                        onSelected: (_) => setState(() => _filterStatus = TicketStatus.assigned),
                        backgroundColor: AppColors.lightSurfaceVariant,
                        selectedColor: Colors.orange,
                        labelStyle: TextStyle(
                          color: _filterStatus == TicketStatus.assigned ? Colors.white : AppColors.lightOnSurface,
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
                child: dataService.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : tickets.isEmpty
                        ? EmptyState(
                            icon: Icons.build_outlined,
                            title: 'No Maintenance Requests',
                            message: _filterStatus != null
                                ? 'No requests with this status'
                                : 'Create a request to report any issues',
                            actionLabel: unitId != null ? 'Create Request' : null,
                            onAction: unitId != null
                                ? () => context.push('/add-ticket?unitId=$unitId')
                                : null,
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
          floatingActionButton: unitId != null
              ? FloatingActionButton(
                  onPressed: () => context.push('/add-ticket?unitId=$unitId'),
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
          onTap: () {
            // Navigate to ticket detail if available
          },
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
