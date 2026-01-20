import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/nav.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/models/invoice.dart';
import 'package:oxy/components/list_cards.dart';
import 'package:oxy/components/empty_state.dart';

class TenantsPage extends StatefulWidget {
  const TenantsPage({super.key});

  @override
  State<TenantsPage> createState() => _TenantsPageState();
}

class _TenantsPageState extends State<TenantsPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(
      builder: (context, dataService, _) {
        final filteredTenants = dataService.tenants.where((t) {
          if (_searchQuery.isEmpty) return true;
          return t.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 t.phone.contains(_searchQuery);
        }).toList();
        
        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            title: const Text('Tenants', style: TextStyle(color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add, color: Colors.white),
                onPressed: () => context.push(AppRoutes.addTenant),
              ),
            ],
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
                    hintText: 'Search by name or phone...',
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
              
              // Tenants list
              Expanded(
                child: filteredTenants.isEmpty
                    ? EmptyState(
                        icon: Icons.people_outline,
                        title: _searchQuery.isEmpty ? 'No Tenants' : 'No Results',
                        message: _searchQuery.isEmpty 
                            ? 'Add your first tenant to get started'
                            : 'Try a different search term',
                        actionLabel: _searchQuery.isEmpty ? 'Add Tenant' : null,
                        onAction: _searchQuery.isEmpty 
                            ? () => context.push(AppRoutes.addTenant)
                            : null,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 100),
                        itemCount: filteredTenants.length,
                        itemBuilder: (context, index) {
                          final tenant = filteredTenants[index];
                          final lease = dataService.getActiveLeaseForTenant(tenant.id);
                          String? unitInfo;
                          
                          if (lease != null) {
                            final unit = dataService.getUnitById(lease.unitId);
                            final property = dataService.getPropertyById(lease.propertyId);
                            if (unit != null && property != null) {
                              unitInfo = '${property.name} - ${unit.unitLabel}';
                            }
                          }
                          
                          // Calculate balance
                          final invoices = dataService.getInvoicesForTenant(tenant.id);
                          final balance = invoices
                              .where((i) => i.status == InvoiceStatus.open)
                              .fold<double>(0, (sum, i) => sum + i.balanceAmount);
                          
                          return TenantCard(
                            tenant: tenant,
                            unitInfo: unitInfo,
                            balance: balance,
                            onTap: () => context.push('/tenants/${tenant.id}'),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push(AppRoutes.addTenant),
            child: const Icon(Icons.person_add, color: Colors.white),
          ),
        );
      },
    );
  }
}
