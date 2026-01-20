import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/nav.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/models/maintenance_ticket.dart';
import 'package:oxy/components/list_cards.dart';
import 'package:oxy/components/empty_state.dart';
import 'package:oxy/utils/formatters.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<MaintenanceTicket> _filterTickets(List<MaintenanceTicket> tickets, int tabIndex) {
    switch (tabIndex) {
      case 0: return tickets;
      case 1: return tickets.where((t) => t.status == TicketStatus.new_).toList();
      case 2: return tickets.where((t) => t.status == TicketStatus.inProgress || t.status == TicketStatus.assigned).toList();
      case 3: return tickets.where((t) => t.status == TicketStatus.done || t.status == TicketStatus.approved).toList();
      default: return tickets;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(
      builder: (context, dataService, _) {
        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: const Text('Maintenance', style: TextStyle(color: Colors.white)),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: 'All (${dataService.tickets.length})'),
                Tab(text: 'New (${dataService.tickets.where((t) => t.status == TicketStatus.new_).length})'),
                Tab(text: 'Active (${dataService.tickets.where((t) => t.status == TicketStatus.inProgress || t.status == TicketStatus.assigned).length})'),
                Tab(text: 'Done (${dataService.tickets.where((t) => t.status == TicketStatus.done || t.status == TicketStatus.approved).length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTicketList(dataService, 0),
              _buildTicketList(dataService, 1),
              _buildTicketList(dataService, 2),
              _buildTicketList(dataService, 3),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push(AppRoutes.addTicket),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildTicketList(DataService dataService, int tabIndex) {
    final tickets = _filterTickets(dataService.tickets, tabIndex)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    if (tickets.isEmpty) {
      return EmptyState(
        icon: Icons.build_outlined,
        title: tabIndex == 1 ? 'No New Tickets' : 'No Tickets',
        message: tabIndex == 1 ? 'All caught up! 🎉' : 'No tickets found',
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        final unit = dataService.getUnitById(ticket.unitId);
        final property = dataService.getPropertyById(ticket.propertyId);
        
        return TicketCard(
          ticket: ticket,
          unitLabel: '${property?.name ?? ""} - ${unit?.unitLabel ?? ""}',
          onTap: () => _showTicketDetails(context, dataService, ticket, unit, property),
        );
      },
    );
  }

  void _showTicketDetails(BuildContext context, DataService dataService, MaintenanceTicket ticket, dynamic unit, dynamic property) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(ticket.priority).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ticket.priorityLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getPriorityColor(ticket.priority),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(ticket.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ticket.statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(ticket.status),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          Formatters.relativeDate(ticket.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      ticket.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ticket.description,
                      style: TextStyle(
                        color: AppColors.lightOnSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightSurfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _DetailItem(
                            icon: Icons.location_on_outlined,
                            label: 'Location',
                            value: '${property?.name ?? ""} - ${unit?.unitLabel ?? ""}',
                          ),
                          if (ticket.vendorName != null) ...[
                            const SizedBox(height: 12),
                            _DetailItem(
                              icon: Icons.handyman_outlined,
                              label: 'Assigned To',
                              value: ticket.vendorName!,
                            ),
                          ],
                          if (ticket.totalCost > 0) ...[
                            const SizedBox(height: 12),
                            _DetailItem(
                              icon: Icons.attach_money,
                              label: 'Total Cost',
                              value: Formatters.currency(ticket.totalCost),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (ticket.costs.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Cost Items',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...ticket.costs.map((cost) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text(cost.item)),
                            Text(
                              Formatters.currency(cost.amount),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )),
                    ],
                    const SizedBox(height: 24),
                    if (ticket.status != TicketStatus.approved && ticket.status != TicketStatus.rejected) ...[
                      Text(
                        'Update Status',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _getAvailableStatuses(ticket.status).map((status) {
                          return GestureDetector(
                            onTap: () async {
                              final updated = ticket.copyWith(
                                status: status,
                                resolvedAt: status == TicketStatus.done ? DateTime.now() : null,
                                updatedAt: DateTime.now(),
                              );
                              await dataService.updateTicket(updated);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Status updated to ${_getStatusLabel(status)}')),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _getStatusColor(status).withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                _getStatusLabel(status),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(status),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TicketStatus> _getAvailableStatuses(TicketStatus current) {
    switch (current) {
      case TicketStatus.new_:
        return [TicketStatus.assigned, TicketStatus.rejected];
      case TicketStatus.assigned:
        return [TicketStatus.inProgress, TicketStatus.rejected];
      case TicketStatus.inProgress:
        return [TicketStatus.done];
      case TicketStatus.done:
        return [TicketStatus.approved, TicketStatus.rejected];
      default:
        return [];
    }
  }

  String _getStatusLabel(TicketStatus status) {
    switch (status) {
      case TicketStatus.new_: return 'New';
      case TicketStatus.assigned: return 'Assign';
      case TicketStatus.inProgress: return 'In Progress';
      case TicketStatus.done: return 'Mark Done';
      case TicketStatus.approved: return 'Approve';
      case TicketStatus.rejected: return 'Reject';
    }
  }

  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low: return AppColors.success;
      case TicketPriority.medium: return AppColors.warning;
      case TicketPriority.high: return AppColors.error;
    }
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.new_: return AppColors.info;
      case TicketStatus.assigned: return Colors.purple;
      case TicketStatus.inProgress: return AppColors.warning;
      case TicketStatus.done: return AppColors.primaryTeal;
      case TicketStatus.approved: return AppColors.success;
      case TicketStatus.rejected: return AppColors.error;
    }
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.lightOnSurfaceVariant),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.lightOnSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
