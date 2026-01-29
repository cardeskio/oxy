import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/nav.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/models/maintenance_ticket.dart';
import 'package:oxy/components/list_cards.dart';
import 'package:oxy/components/empty_state.dart';

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
          onTap: () => context.push('/maintenance/${ticket.id}'),
        );
      },
    );
  }
}
