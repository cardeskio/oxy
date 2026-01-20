import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/nav.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/components/list_cards.dart';
import 'package:oxy/components/empty_state.dart';

class PropertiesPage extends StatefulWidget {
  const PropertiesPage({super.key});

  @override
  State<PropertiesPage> createState() => _PropertiesPageState();
}

class _PropertiesPageState extends State<PropertiesPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(
      builder: (context, dataService, _) {
        final filteredProperties = dataService.properties.where((p) {
          if (_searchQuery.isEmpty) return true;
          return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 p.locationText.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
        
        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            title: const Text('Properties', style: TextStyle(color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => context.push(AppRoutes.addProperty),
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
                    hintText: 'Search properties...',
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
              
              // Properties list
              Expanded(
                child: filteredProperties.isEmpty
                    ? EmptyState(
                        icon: Icons.apartment,
                        title: _searchQuery.isEmpty ? 'No Properties' : 'No Results',
                        message: _searchQuery.isEmpty 
                            ? 'Add your first property to get started'
                            : 'Try a different search term',
                        actionLabel: _searchQuery.isEmpty ? 'Add Property' : null,
                        onAction: _searchQuery.isEmpty 
                            ? () => context.push(AppRoutes.addProperty)
                            : null,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 100),
                        itemCount: filteredProperties.length,
                        itemBuilder: (context, index) {
                          final property = filteredProperties[index];
                          final unitCount = dataService.getUnitCountForProperty(property.id);
                          final occupiedCount = dataService.getOccupiedUnitCountForProperty(property.id);
                          
                          return PropertyCard(
                            property: property,
                            unitCount: unitCount,
                            occupiedCount: occupiedCount,
                            onTap: () => context.push('/properties/${property.id}'),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push(AppRoutes.addProperty),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}
