import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oxy/models/service_provider.dart';
import 'package:oxy/services/living_service.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/components/empty_state.dart';
import 'package:uuid/uuid.dart';

/// Listings management page for service providers
class ProviderListingsPage extends StatelessWidget {
  const ProviderListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
      ),
      body: Consumer<LivingService>(
        builder: (context, livingService, _) {
          final listings = livingService.myListings;

          if (listings.isEmpty) {
            return EmptyState(
              icon: HugeIcons.strokeRoundedShoppingBag02,
              title: 'No Listings Yet',
              message: 'Add products or services you offer to attract customers.',
              actionLabel: 'Add Listing',
              onAction: () => _showAddListingSheet(context, livingService),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await livingService.initialize();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                final listing = listings[index];
                return _ListingCard(
                  listing: listing,
                  onEdit: () => _showEditListingSheet(context, livingService, listing),
                  onDelete: () => _confirmDelete(context, livingService, listing),
                  onToggleStatus: () => _toggleListingStatus(context, livingService, listing),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddListingSheet(
          context,
          context.read<LivingService>(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddListingSheet(BuildContext context, LivingService livingService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ListingFormSheet(
        onSave: (title, description, price, priceUnit, imageUrls) async {
          await livingService.addListing(
            title: title,
            description: description,
            price: price,
            priceUnit: priceUnit,
            imageUrls: imageUrls,
          );
        },
      ),
    );
  }

  void _showEditListingSheet(
    BuildContext context,
    LivingService livingService,
    ServiceListing listing,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ListingFormSheet(
        listing: listing,
        onSave: (title, description, price, priceUnit, imageUrls) async {
          final updatedImages = imageUrls != null 
              ? imageUrls.map((url) => {'url': url}).toList()
              : listing.images;
          final updated = ServiceListing(
            id: listing.id,
            providerId: listing.providerId,
            title: title,
            description: description,
            price: price,
            priceUnit: priceUnit,
            images: updatedImages,
            status: listing.status,
            tags: listing.tags,
            createdAt: listing.createdAt,
            updatedAt: DateTime.now(),
          );
          await livingService.updateListing(updated);
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    LivingService livingService,
    ServiceListing listing,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Are you sure you want to delete "${listing.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await livingService.deleteListing(listing.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Listing deleted')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleListingStatus(
    BuildContext context,
    LivingService livingService,
    ServiceListing listing,
  ) async {
    final newStatus = listing.status == ListingStatus.active
        ? ListingStatus.paused
        : ListingStatus.active;
    
    final updated = ServiceListing(
      id: listing.id,
      providerId: listing.providerId,
      title: listing.title,
      description: listing.description,
      price: listing.price,
      priceUnit: listing.priceUnit,
      images: listing.images,
      status: newStatus,
      tags: listing.tags,
      createdAt: listing.createdAt,
      updatedAt: DateTime.now(),
    );
    
    await livingService.updateListing(updated);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == ListingStatus.active
                ? 'Listing activated'
                : 'Listing paused',
          ),
        ),
      );
    }
  }
}

class _ListingCard extends StatelessWidget {
  final ServiceListing listing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _ListingCard({
    required this.listing,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: listing.coverImageUrl != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      listing.coverImageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedImage01,
                      color: colorScheme.onSurfaceVariant,
                      size: 48,
                    ),
                  ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        listing.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _StatusBadge(status: listing.status),
                  ],
                ),
                if (listing.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    listing.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      listing.priceLabel,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        listing.status == ListingStatus.active
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        color: colorScheme.primary,
                      ),
                      tooltip: listing.status == ListingStatus.active ? 'Pause' : 'Activate',
                      onPressed: onToggleStatus,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ListingStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    
    switch (status) {
      case ListingStatus.active:
        bgColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        break;
      case ListingStatus.paused:
        bgColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        break;
      case ListingStatus.soldOut:
        bgColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        break;
      case ListingStatus.expired:
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _ListingFormSheet extends StatefulWidget {
  final ServiceListing? listing;
  final Future<void> Function(
    String title,
    String? description,
    double? price,
    String? priceUnit,
    List<String>? imageUrls,
  ) onSave;

  const _ListingFormSheet({
    this.listing,
    required this.onSave,
  });

  @override
  State<_ListingFormSheet> createState() => _ListingFormSheetState();
}

class _ListingFormSheetState extends State<_ListingFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  String? _selectedPriceUnit;
  bool _isLoading = false;
  List<String> _existingImageUrls = [];
  final List<XFile> _newImages = [];

  final _priceUnits = [
    (value: null as String?, label: 'One-time'),
    (value: 'per_hour', label: 'Per Hour'),
    (value: 'per_item', label: 'Per Item'),
    (value: 'per_service', label: 'Per Service'),
    (value: 'from', label: 'Starting From'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.listing != null) {
      _titleController.text = widget.listing!.title;
      _descriptionController.text = widget.listing!.description ?? '';
      _priceController.text = widget.listing!.price?.toStringAsFixed(0) ?? '';
      _selectedPriceUnit = widget.listing!.priceUnit;
      // Extract existing image URLs
      _existingImageUrls = widget.listing!.images
          .map((img) => img is Map ? img['url'] as String? : null)
          .whereType<String>()
          .toList();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (images.isNotEmpty) {
      setState(() {
        // Limit to 4 total images
        final remaining = 4 - _existingImageUrls.length - _newImages.length;
        _newImages.addAll(images.take(remaining));
      });
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages() async {
    if (_newImages.isEmpty) return [];
    
    final uploadedUrls = <String>[];
    final supabase = Supabase.instance.client;
    
    for (final image in _newImages) {
      final bytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName = '${const Uuid().v4()}.$fileExt';
      final path = 'listing-images/$fileName';
      
      await supabase.storage.from('public').uploadBinary(path, bytes);
      final url = supabase.storage.from('public').getPublicUrl(path);
      uploadedUrls.add(url);
    }
    
    return uploadedUrls;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload new images
      final newUrls = await _uploadImages();
      final allUrls = [..._existingImageUrls, ...newUrls];

      await widget.onSave(
        _titleController.text.trim(),
        _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        _priceController.text.isEmpty ? null : double.tryParse(_priceController.text),
        _selectedPriceUnit,
        allUrls.isNotEmpty ? allUrls : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.listing == null ? 'Listing added' : 'Listing updated'),
            backgroundColor: AppColors.success,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.listing == null ? 'Add Listing' : 'Edit Listing',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'e.g., House Cleaning Service',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Describe what this listing includes',
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // Images section
              Text(
                'Images (up to 4)',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Existing images
                    ..._existingImageUrls.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                entry.value,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeExistingImage(entry.key),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    // New images
                    ..._newImages.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(entry.value.path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeNewImage(entry.key),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    // Add button
                    if (_existingImageUrls.length + _newImages.length < 4)
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? AppColors.darkOutline : Colors.grey.shade300,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                HugeIcons.strokeRoundedImage01,
                                size: 28,
                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price (KES)',
                        hintText: '0',
                        prefixText: 'KES ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String?>(
                      value: _selectedPriceUnit,
                      decoration: const InputDecoration(
                        labelText: 'Price Type',
                      ),
                      items: _priceUnits.map((unit) {
                        return DropdownMenuItem(
                          value: unit.value,
                          child: Text(unit.label),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedPriceUnit = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.listing == null ? 'Add' : 'Save',
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
