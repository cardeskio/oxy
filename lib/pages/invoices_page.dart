import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/models/invoice.dart';
import 'package:oxy/components/list_cards.dart';
import 'package:oxy/components/empty_state.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Invoice> _filterInvoices(List<Invoice> invoices, int tabIndex) {
    List<Invoice> filtered;
    switch (tabIndex) {
      case 0: // All
        filtered = invoices;
        break;
      case 1: // Open
        filtered = invoices.where((i) => i.status == InvoiceStatus.open).toList();
        break;
      case 2: // Paid
        filtered = invoices.where((i) => i.status == InvoiceStatus.paid).toList();
        break;
      default:
        filtered = invoices;
    }
    
    if (_searchQuery.isNotEmpty) {
      final dataService = context.read<DataService>();
      filtered = filtered.where((i) {
        final tenant = dataService.getTenantById(i.tenantId);
        final unit = dataService.getUnitById(i.unitId);
        return (tenant?.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
               (unit?.unitLabel.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }
    
    return filtered..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(
      builder: (context, dataService, _) {
        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            title: const Text('Invoices', style: TextStyle(color: Colors.white)),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: 'All (${dataService.invoices.length})'),
                Tab(text: 'Open (${dataService.invoices.where((i) => i.status == InvoiceStatus.open).length})'),
                Tab(text: 'Paid (${dataService.invoices.where((i) => i.status == InvoiceStatus.paid).length})'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Search bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search by tenant or unit...',
                    prefixIcon: Icon(Icons.search, color: AppColors.lightOnSurfaceVariant),
                    filled: true,
                    fillColor: AppColors.lightSurfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              
              // Invoice list
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInvoiceList(dataService, 0),
                    _buildInvoiceList(dataService, 1),
                    _buildInvoiceList(dataService, 2),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvoiceList(DataService dataService, int tabIndex) {
    final invoices = _filterInvoices(dataService.invoices, tabIndex);
    
    if (invoices.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long,
        title: 'No Invoices',
        message: tabIndex == 1 
            ? 'All invoices are paid! 🎉'
            : 'No invoices found',
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        final tenant = dataService.getTenantById(invoice.tenantId);
        final unit = dataService.getUnitById(invoice.unitId);
        final property = dataService.getPropertyById(invoice.propertyId);
        
        return InvoiceCard(
          invoice: invoice,
          tenantName: tenant?.fullName ?? 'Unknown',
          unitLabel: '${property?.name ?? ''} - ${unit?.unitLabel ?? ''}',
          onTap: () => context.push('/invoices/${invoice.id}'),
        );
      },
    );
  }
}
