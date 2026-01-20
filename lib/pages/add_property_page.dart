import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/models/property.dart';

class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  PropertyType _selectedType = PropertyType.residential;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final dataService = context.read<DataService>();
      final orgId = dataService.currentOrgId ?? '';
      
      final property = Property(
        id: const Uuid().v4(),
        orgId: orgId,
        name: _nameController.text.trim(),
        type: _selectedType,
        locationText: _locationController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await dataService.addProperty(property);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${property.name} added successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add Property', style: TextStyle(color: Colors.white)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Property Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Property Name *',
                      hintText: 'e.g., Greenview Apartments',
                    ),
                    validator: (value) => value?.trim().isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<PropertyType>(
                    value: _selectedType,
                    decoration: const InputDecoration(labelText: 'Property Type'),
                    items: PropertyType.values.map((type) {
                      String label;
                      IconData icon;
                      switch (type) {
                        case PropertyType.residential:
                          label = 'Residential';
                          icon = Icons.home_outlined;
                          break;
                        case PropertyType.commercial:
                          label = 'Commercial';
                          icon = Icons.store_outlined;
                          break;
                        case PropertyType.mixed:
                          label = 'Mixed Use';
                          icon = Icons.domain_outlined;
                          break;
                      }
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(icon, size: 20, color: AppColors.primaryTeal),
                            const SizedBox(width: 12),
                            Text(label),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedType = value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location *',
                      hintText: 'e.g., Kilimani, Nairobi',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (value) => value?.trim().isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'Additional details about the property',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Property', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
