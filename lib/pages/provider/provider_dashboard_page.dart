import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:oxy/models/service_provider.dart';
import 'package:oxy/services/living_service.dart';
import 'package:oxy/components/notification_badge.dart';
import 'package:oxy/theme.dart';

/// Dashboard page for service providers
class ProviderDashboardPage extends StatelessWidget {
  const ProviderDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LivingService>(
      builder: (context, livingService, _) {
        final provider = livingService.myProvider;

        if (provider == null) {
          // Shouldn't happen if routed correctly, but handle gracefully
          return Scaffold(
            appBar: AppBar(title: const Text('Dashboard')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No business profile found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/provider-onboarding'),
                    child: const Text('Set Up Business', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: const [
              NotificationBadge(isProviderView: true),
              SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await livingService.initialize();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Business card
                _BusinessCard(provider: provider),
                const SizedBox(height: 20),

                // Quick stats
                _StatsGrid(
                  listings: livingService.myListings.length,
                  reviews: provider.ratingCount,
                  rating: provider.ratingAverage,
                ),
                const SizedBox(height: 20),

                // Quick actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _QuickActionsGrid(),
                const SizedBox(height: 20),

                // Recent listings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Listings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/provider/listings'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (livingService.myListings.isEmpty)
                  _EmptyListingsCard()
                else
                  ...livingService.myListings.take(3).map(
                    (listing) => _ListingTile(listing: listing),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.go('/provider/listings'),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _BusinessCard extends StatelessWidget {
  final ServiceProvider provider;

  const _BusinessCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo/Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: provider.logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          provider.logoUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          provider.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.businessName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        HugeIcon(
                          icon: _getCategoryIcon(provider.category),
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          provider.category.label,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: provider.status == ProviderStatus.active
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  provider.status == ProviderStatus.active ? 'Active' : 'Pending',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Colors.white.withValues(alpha: 0.8),
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  provider.locationText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (provider.isVerified) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.verified,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Verified Business',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int listings;
  final int reviews;
  final double rating;

  const _StatsGrid({
    required this.listings,
    required this.reviews,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: HugeIcons.strokeRoundedShoppingBag02,
            label: 'Listings',
            value: listings.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: HugeIcons.strokeRoundedComment02,
            label: 'Reviews',
            value: reviews.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: HugeIcons.strokeRoundedStar,
            label: 'Rating',
            value: reviews > 0 ? rating.toStringAsFixed(1) : '-',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        ),
      ),
      child: Column(
        children: [
          HugeIcon(
            icon: icon,
            color: colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final livingService = context.read<LivingService>();
    final provider = livingService.myProvider;
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _QuickActionChip(
          icon: Icons.edit_outlined,
          label: 'Edit Profile',
          onTap: provider != null 
              ? () => showEditProfileSheet(context, provider, livingService)
              : null,
        ),
        _QuickActionChip(
          icon: Icons.schedule_outlined,
          label: 'Business Hours',
          onTap: provider != null 
              ? () => showBusinessHoursSheet(context, provider, livingService)
              : null,
        ),
        _QuickActionChip(
          icon: Icons.image_outlined,
          label: 'Photos',
          onTap: provider != null 
              ? () => showPhotosSheet(context, provider, livingService)
              : null,
        ),
        _QuickActionChip(
          icon: Icons.share_outlined,
          label: 'Share',
          onTap: () {
            // TODO: Share provider profile
          },
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ActionChip(
      avatar: Icon(icon, size: 18, color: colorScheme.primary),
      label: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.primaryNavy,
        ),
      ),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      side: BorderSide(
        color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
      ),
      onPressed: onTap,
    );
  }
}

class _EmptyListingsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No Listings Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your products or services to attract customers',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.go('/provider/listings'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Your First Listing', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  final ServiceListing listing;

  const _ListingTile({required this.listing});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: listing.coverImageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    listing.coverImageUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  Icons.inventory_2_outlined,
                  color: colorScheme.primary,
                ),
        ),
        title: Text(
          listing.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          listing.priceLabel,
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: listing.status == ListingStatus.active
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            listing.status.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: listing.status == ListingStatus.active
                  ? AppColors.success
                  : AppColors.warning,
            ),
          ),
        ),
        onTap: () => context.go('/provider/listings'),
      ),
    );
  }
}

IconData _getCategoryIcon(ServiceCategory category) {
  switch (category) {
    case ServiceCategory.foodDining:
      return HugeIcons.strokeRoundedRestaurant01;
    case ServiceCategory.shopping:
      return HugeIcons.strokeRoundedShoppingBag02;
    case ServiceCategory.healthWellness:
      return HugeIcons.strokeRoundedMedicine02;
    case ServiceCategory.homeServices:
      return HugeIcons.strokeRoundedHome03;
    case ServiceCategory.professionalServices:
      return HugeIcons.strokeRoundedBriefcase01;
    case ServiceCategory.entertainment:
      return HugeIcons.strokeRoundedTicket02;
    case ServiceCategory.transport:
      return HugeIcons.strokeRoundedCar01;
    case ServiceCategory.education:
      return HugeIcons.strokeRoundedBook02;
    case ServiceCategory.beautySpa:
      return HugeIcons.strokeRoundedHairDryer;
    case ServiceCategory.fitness:
      return HugeIcons.strokeRoundedDumbbell01;
    case ServiceCategory.financial:
      return HugeIcons.strokeRoundedBank;
    case ServiceCategory.other:
      return HugeIcons.strokeRoundedMoreHorizontal;
  }
}

/// Shows the edit profile bottom sheet
void showEditProfileSheet(BuildContext context, ServiceProvider provider, LivingService livingService) {
  final nameController = TextEditingController(text: provider.businessName);
  final descriptionController = TextEditingController(text: provider.businessDescription ?? '');
  final phoneController = TextEditingController(text: provider.phone);
  final emailController = TextEditingController(text: provider.email ?? '');
  final websiteController = TextEditingController(text: provider.website ?? '');
  final whatsappController = TextEditingController(text: provider.whatsapp ?? '');
  final locationController = TextEditingController(text: provider.locationText);
  ServiceCategory selectedCategory = provider.category;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
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
                  'Edit Business Profile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Business Name *'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ServiceCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category *'),
                  items: ServiceCategory.values.map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: _getCategoryIcon(cat),
                          color: AppColors.primaryNavy,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(cat.label),
                      ],
                    ),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => selectedCategory = value);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Business Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number *'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: whatsappController,
                  decoration: const InputDecoration(labelText: 'WhatsApp Number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: websiteController,
                  decoration: const InputDecoration(labelText: 'Website'),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location *'),
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
                        onPressed: () async {
                          if (nameController.text.isEmpty || 
                              phoneController.text.isEmpty ||
                              locationController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill required fields')),
                            );
                            return;
                          }
                          try {
                            final updatedProvider = provider.copyWith(
                              businessName: nameController.text,
                              businessDescription: descriptionController.text.isEmpty 
                                  ? null 
                                  : descriptionController.text,
                              category: selectedCategory,
                              phone: phoneController.text,
                              email: emailController.text.isEmpty ? null : emailController.text,
                              website: websiteController.text.isEmpty ? null : websiteController.text,
                              whatsapp: whatsappController.text.isEmpty ? null : whatsappController.text,
                              locationText: locationController.text,
                              updatedAt: DateTime.now(),
                            );
                            await livingService.updateProviderProfile(updatedProvider);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profile updated')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('Save', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Shows the business hours editor sheet
void showBusinessHoursSheet(BuildContext context, ServiceProvider provider, LivingService livingService) {
  final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  final dayLabels = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  
  // Initialize hours state from provider
  final hoursState = <String, ({bool isOpen, String openTime, String closeTime})>{};
  for (final day in days) {
    final dayHours = provider.businessHours?.hours[day];
    hoursState[day] = (
      isOpen: dayHours != null,
      openTime: dayHours?.open ?? '09:00',
      closeTime: dayHours?.close ?? '17:00',
    );
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        Future<void> pickTime(String day, bool isOpen) async {
          final current = isOpen ? hoursState[day]!.openTime : hoursState[day]!.closeTime;
          final parts = current.split(':');
          final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          
          final picked = await showTimePicker(
            context: context,
            initialTime: initialTime,
          );
          
          if (picked != null) {
            final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
            setState(() {
              if (isOpen) {
                hoursState[day] = (isOpen: hoursState[day]!.isOpen, openTime: formatted, closeTime: hoursState[day]!.closeTime);
              } else {
                hoursState[day] = (isOpen: hoursState[day]!.isOpen, openTime: hoursState[day]!.openTime, closeTime: formatted);
              }
            });
          }
        }

        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.8,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Business Hours',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: days.length,
                    itemBuilder: (context, index) {
                      final day = days[index];
                      final state = hoursState[day]!;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dayLabels[index],
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                                Switch(
                                  value: state.isOpen,
                                  onChanged: (v) => setState(() {
                                    hoursState[day] = (isOpen: v, openTime: state.openTime, closeTime: state.closeTime);
                                  }),
                                ),
                              ],
                            ),
                            if (state.isOpen) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => pickTime(day, true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(state.openTime, style: const TextStyle(fontSize: 16)),
                                            const Icon(Icons.access_time, size: 18, color: Colors.grey),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('to', style: TextStyle(color: Colors.grey)),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => pickTime(day, false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(state.closeTime, style: const TextStyle(fontSize: 16)),
                                            const Icon(Icons.access_time, size: 18, color: Colors.grey),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text('Closed', style: TextStyle(color: Colors.grey)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
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
                          onPressed: () async {
                            // Build BusinessHours from state
                            final hoursMap = <String, DayHours?>{};
                            for (final day in days) {
                              final state = hoursState[day]!;
                              if (state.isOpen) {
                                hoursMap[day] = DayHours(open: state.openTime, close: state.closeTime);
                              } else {
                                hoursMap[day] = null;
                              }
                            }
                            
                            final updatedProvider = provider.copyWith(
                              businessHours: BusinessHours(hours: hoursMap),
                              updatedAt: DateTime.now(),
                            );
                            
                            try {
                              await livingService.updateProviderProfile(updatedProvider);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Business hours updated')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Save', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Shows the photos management sheet
void showPhotosSheet(BuildContext context, ServiceProvider provider, LivingService livingService) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _PhotosSheet(provider: provider, livingService: livingService),
  );
}

/// Shows the location settings sheet
void showLocationSheet(BuildContext context, ServiceProvider provider, LivingService livingService) {
  final locationController = TextEditingController(text: provider.locationText);
  double serviceRadius = provider.serviceRadiusKm;
  double? latitude = provider.latitude;
  double? longitude = provider.longitude;
  bool isGettingLocation = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        Future<void> getCurrentLocation() async {
          setState(() => isGettingLocation = true);
          
          try {
            // Check if location services are enabled
            bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
            if (!serviceEnabled) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enable location services')),
                );
              }
              setState(() => isGettingLocation = false);
              return;
            }

            // Check permission
            LocationPermission permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.denied) {
              permission = await Geolocator.requestPermission();
              if (permission == LocationPermission.denied) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Location permission denied')),
                  );
                }
                setState(() => isGettingLocation = false);
                return;
              }
            }
            
            if (permission == LocationPermission.deniedForever) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location permissions are permanently denied. Please enable in Settings.')),
                );
              }
              setState(() => isGettingLocation = false);
              return;
            }

            // Get current position
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
            
            latitude = position.latitude;
            longitude = position.longitude;
            
            // Reverse geocode to get address
            String? locationName;
            try {
              final placemarks = await placemarkFromCoordinates(
                position.latitude,
                position.longitude,
              );
              
              if (placemarks.isNotEmpty) {
                final p = placemarks.first;
                final parts = <String>[];
                
                // Build from most specific to least specific
                // Street/thoroughfare
                if (p.thoroughfare != null && p.thoroughfare!.isNotEmpty) {
                  parts.add(p.thoroughfare!);
                }
                // Sublocality (neighborhood/area)
                if (p.subLocality != null && p.subLocality!.isNotEmpty) {
                  parts.add(p.subLocality!);
                }
                // Locality (city)
                if (p.locality != null && p.locality!.isNotEmpty) {
                  // Only add if different from subLocality
                  if (parts.isEmpty || parts.last != p.locality) {
                    parts.add(p.locality!);
                  }
                }
                // Admin area (state/county) - optional for context
                if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) {
                  if (parts.isEmpty || parts.last != p.administrativeArea) {
                    parts.add(p.administrativeArea!);
                  }
                }
                
                if (parts.isNotEmpty) {
                  locationName = parts.join(', ');
                  // Auto-fill the address field
                  locationController.text = locationName;
                }
              }
            } catch (e) {
              debugPrint('Reverse geocoding error: $e');
            }
            
            setState(() => isGettingLocation = false);
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(locationName != null 
                    ? 'Location set: $locationName' 
                    : 'Location captured'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } catch (e) {
            debugPrint('Error getting location: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error getting location: $e')),
              );
            }
            setState(() => isGettingLocation = false);
          }
        }

        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
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
                  'Location Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Business Address',
                    hintText: 'e.g., Westlands, Nairobi',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                
                // Use Current Location button
                OutlinedButton.icon(
                  onPressed: isGettingLocation ? null : getCurrentLocation,
                  icon: isGettingLocation 
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(isGettingLocation ? 'Getting location...' : 'Use Current Location'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                
                // Show coordinates if available
                if (latitude != null && longitude != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'GPS: ${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() {
                            latitude = null;
                            longitude = null;
                          }),
                          child: const Icon(Icons.close, color: AppColors.success, size: 18),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                Text(
                  'Service Radius',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'How far are you willing to travel to serve customers?',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: serviceRadius,
                        min: 1,
                        max: 50,
                        divisions: 49,
                        label: '${serviceRadius.round()} km',
                        onChanged: (v) => setState(() => serviceRadius = v),
                      ),
                    ),
                    Container(
                      width: 70,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${serviceRadius.round()} km',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
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
                        onPressed: () async {
                          if (locationController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a location')),
                            );
                            return;
                          }
                          
                          final updatedProvider = provider.copyWith(
                            locationText: locationController.text,
                            latitude: latitude,
                            longitude: longitude,
                            serviceRadiusKm: serviceRadius,
                            updatedAt: DateTime.now(),
                          );
                          
                          try {
                            await livingService.updateProviderProfile(updatedProvider);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Location updated')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('Save', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Shows notification settings sheet
void showNotificationSettingsSheet(BuildContext context) {
  // Simple preferences - in real app would persist these
  bool newReviews = true;
  bool newMessages = true;
  bool bookingAlerts = true;
  bool promotions = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                'Notification Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _NotificationToggle(
                icon: HugeIcons.strokeRoundedStar,
                title: 'New Reviews',
                subtitle: 'When customers leave reviews',
                value: newReviews,
                onChanged: (v) => setState(() => newReviews = v),
              ),
              _NotificationToggle(
                icon: HugeIcons.strokeRoundedMail01,
                title: 'Messages',
                subtitle: 'When you receive new messages',
                value: newMessages,
                onChanged: (v) => setState(() => newMessages = v),
              ),
              _NotificationToggle(
                icon: HugeIcons.strokeRoundedCalendar03,
                title: 'Booking Alerts',
                subtitle: 'New bookings and reminders',
                value: bookingAlerts,
                onChanged: (v) => setState(() => bookingAlerts = v),
              ),
              _NotificationToggle(
                icon: HugeIcons.strokeRoundedMegaphone01,
                title: 'Promotions',
                subtitle: 'Tips and promotional offers',
                value: promotions,
                onChanged: (v) => setState(() => promotions = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification preferences saved')),
                    );
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}

class _NotificationToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          HugeIcon(icon: icon, color: AppColors.primaryNavy, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Shows help & support sheet
void showHelpSupportSheet(BuildContext context) {
  final helpTopics = [
    (icon: HugeIcons.strokeRoundedStore01, title: 'Getting Started', subtitle: 'How to set up your business profile'),
    (icon: HugeIcons.strokeRoundedShoppingBag02, title: 'Managing Listings', subtitle: 'Add, edit, and organize your services'),
    (icon: HugeIcons.strokeRoundedStar, title: 'Reviews & Ratings', subtitle: 'Understanding your customer feedback'),
    (icon: HugeIcons.strokeRoundedWallet01, title: 'Payments', subtitle: 'How to receive payments from customers'),
    (icon: HugeIcons.strokeRoundedChartLineData01, title: 'Analytics', subtitle: 'Track your business performance'),
    (icon: HugeIcons.strokeRoundedSecurityCheck, title: 'Account Security', subtitle: 'Keep your account safe'),
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Help & Support',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ...helpTopics.map((topic) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: HugeIcon(icon: topic.icon, color: AppColors.primaryNavy, size: 24),
                      title: Text(topic.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(topic.subtitle, style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opening ${topic.title}...')),
                        );
                      },
                    ),
                  )),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedCustomerService01,
                          color: AppColors.primaryNavy,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Need more help?',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contact our support team',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Opening support chat...')),
                            );
                          },
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text('Chat with Support'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Shows privacy policy sheet
void showPrivacyPolicySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Privacy Policy',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _PolicySection(
                    title: '1. Information We Collect',
                    content: 'We collect information you provide directly, such as your business name, contact details, and location. We also collect usage data to improve our services.',
                  ),
                  _PolicySection(
                    title: '2. How We Use Your Information',
                    content: 'Your information is used to provide and improve our services, connect you with customers, process transactions, and send relevant communications.',
                  ),
                  _PolicySection(
                    title: '3. Information Sharing',
                    content: 'We share your public business profile with users looking for services. We do not sell your personal information to third parties.',
                  ),
                  _PolicySection(
                    title: '4. Data Security',
                    content: 'We implement industry-standard security measures to protect your data. However, no method of transmission over the Internet is 100% secure.',
                  ),
                  _PolicySection(
                    title: '5. Your Rights',
                    content: 'You can access, update, or delete your information at any time through your account settings. Contact us for assistance with data-related requests.',
                  ),
                  _PolicySection(
                    title: '6. Updates to This Policy',
                    content: 'We may update this policy from time to time. We will notify you of significant changes via email or in-app notification.',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Last updated: January 2026',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;

  const _PolicySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(color: Colors.grey.shade700, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Photos management sheet
class _PhotosSheet extends StatefulWidget {
  final ServiceProvider provider;
  final LivingService livingService;

  const _PhotosSheet({required this.provider, required this.livingService});

  @override
  State<_PhotosSheet> createState() => _PhotosSheetState();
}

class _PhotosSheetState extends State<_PhotosSheet> {
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  
  String? _logoUrl;
  String? _coverUrl;
  List<String> _galleryUrls = [];
  
  XFile? _newLogo;
  XFile? _newCover;
  final List<XFile> _newGalleryImages = [];

  @override
  void initState() {
    super.initState();
    _logoUrl = widget.provider.logoUrl;
    _coverUrl = widget.provider.coverImageUrl;
    _galleryUrls = widget.provider.images
        .map((img) => img is Map ? img['url'] as String? : img as String?)
        .whereType<String>()
        .toList();
  }

  Future<String?> _uploadImage(XFile image, String folder) async {
    try {
      final supabase = Supabase.instance.client;
      final bytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName = '${const Uuid().v4()}.$fileExt';
      final path = '$folder/$fileName';
      
      await supabase.storage.from('public').uploadBinary(path, bytes);
      return supabase.storage.from('public').getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _pickLogo() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 90,
    );
    if (image != null) {
      setState(() => _newLogo = image);
    }
  }

  Future<void> _pickCover() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _newCover = image);
    }
  }

  Future<void> _pickGalleryImages() async {
    final images = await _imagePicker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (images.isNotEmpty) {
      setState(() {
        final remaining = 6 - _galleryUrls.length - _newGalleryImages.length;
        _newGalleryImages.addAll(images.take(remaining));
      });
    }
  }

  void _removeGalleryImage(int index) {
    setState(() => _galleryUrls.removeAt(index));
  }

  void _removeNewGalleryImage(int index) {
    setState(() => _newGalleryImages.removeAt(index));
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      String? logoUrl = _logoUrl;
      String? coverUrl = _coverUrl;
      List<String> galleryUrls = List.from(_galleryUrls);

      // Upload new logo
      if (_newLogo != null) {
        logoUrl = await _uploadImage(_newLogo!, 'provider-logos');
      }

      // Upload new cover
      if (_newCover != null) {
        coverUrl = await _uploadImage(_newCover!, 'provider-covers');
      }

      // Upload new gallery images
      for (final image in _newGalleryImages) {
        final url = await _uploadImage(image, 'provider-gallery');
        if (url != null) galleryUrls.add(url);
      }

      final updatedProvider = widget.provider.copyWith(
        logoUrl: logoUrl,
        coverImageUrl: coverUrl,
        images: galleryUrls.map((url) => {'url': url}).toList(),
        updatedAt: DateTime.now(),
      );

      await widget.livingService.updateProviderProfile(updatedProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photos updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Photos & Media',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Logo section
                  _SectionTitle(title: 'Business Logo'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickLogo,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                        image: _newLogo != null
                            ? DecorationImage(
                                image: FileImage(File(_newLogo!.path)),
                                fit: BoxFit.cover,
                              )
                            : _logoUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(_logoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child: _newLogo == null && _logoUrl == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, 
                                    size: 32, color: Colors.grey.shade500),
                                const SizedBox(height: 4),
                                Text('Add Logo', 
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cover section
                  _SectionTitle(title: 'Cover Image'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickCover,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        image: _newCover != null
                            ? DecorationImage(
                                image: FileImage(File(_newCover!.path)),
                                fit: BoxFit.cover,
                              )
                            : _coverUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(_coverUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child: _newCover == null && _coverUrl == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.panorama_outlined, 
                                    size: 40, color: Colors.grey.shade500),
                                const SizedBox(height: 8),
                                Text('Add Cover Image', 
                                    style: TextStyle(color: Colors.grey.shade500)),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Gallery section
                  _SectionTitle(title: 'Gallery (up to 6)'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Existing images
                        ..._galleryUrls.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  entry.value,
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeGalleryImage(entry.key),
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
                        )),
                        // New images
                        ..._newGalleryImages.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(entry.value.path),
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeNewGalleryImage(entry.key),
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
                        )),
                        // Add button
                        if (_galleryUrls.length + _newGalleryImages.length < 6)
                          GestureDetector(
                            onTap: _pickGalleryImages,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, 
                                      color: Colors.grey.shade500),
                                  const SizedBox(height: 4),
                                  Text('Add', 
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
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
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
