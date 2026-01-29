import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:oxy/models/order.dart';
import 'package:oxy/models/service_provider.dart';
import 'package:oxy/services/living_service.dart';
import 'package:oxy/services/tenant_service.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/utils/formatters.dart';
import 'package:oxy/components/empty_state.dart';

/// Cart page showing items to order
class TenantCartPage extends StatelessWidget {
  const TenantCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          Consumer<LivingService>(
            builder: (context, livingService, _) {
              if (!livingService.hasItemsInCart) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _confirmClearCart(context, livingService),
                child: const Text('Clear All', style: TextStyle(color: AppColors.error)),
              );
            },
          ),
        ],
      ),
      body: Consumer<LivingService>(
        builder: (context, livingService, _) {
          final cart = livingService.cart;

          if (!livingService.hasItemsInCart) {
            return EmptyState(
              icon: HugeIcons.strokeRoundedShoppingCart01,
              title: 'Your cart is empty',
              message: 'Browse listings and add items to your cart',
              actionLabel: 'Browse',
              onAction: () => context.pop(),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.keys.length,
                  itemBuilder: (context, index) {
                    final providerId = cart.keys.elementAt(index);
                    final items = cart[providerId]!;
                    return _ProviderCartSection(
                      providerId: providerId,
                      items: items,
                      livingService: livingService,
                    );
                  },
                ),
              ),

              // Bottom summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${livingService.totalCartItems} item${livingService.totalCartItems > 1 ? 's' : ''}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            Formatters.currency(livingService.cartSubtotal),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Delivery fees will be calculated at checkout',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmClearCart(BuildContext context, LivingService livingService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              livingService.clearCart();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _ProviderCartSection extends StatelessWidget {
  final String providerId;
  final List<CartItem> items;
  final LivingService livingService;

  const _ProviderCartSection({
    required this.providerId,
    required this.items,
    required this.livingService,
  });

  @override
  Widget build(BuildContext context) {
    // Get provider info
    final provider = livingService.nearbyProviders.firstWhere(
      (p) => p.id == providerId,
      orElse: () => ServiceProvider(
        id: providerId,
        userId: '',
        businessName: 'Provider',
        category: ServiceCategory.other,
        phone: '',
        locationText: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: provider.logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(provider.logoUrl!, fit: BoxFit.cover),
                        )
                      : const Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedStore01,
                            color: AppColors.primaryNavy,
                            size: 20,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider.businessName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Cart items
          ...items.map((item) => _CartItemTile(
            item: item,
            onQuantityChanged: (qty) {
              livingService.updateCartItemQuantity(providerId, item.listingId, qty);
            },
            onRemove: () {
              livingService.removeFromCart(providerId, item.listingId);
            },
          )),

          // Checkout button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Subtotal', style: TextStyle(fontSize: 12)),
                      Text(
                        Formatters.currency(livingService.getProviderCartSubtotal(providerId)),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _proceedToCheckout(context, provider, items),
                  child: const Text('Checkout', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout(BuildContext context, ServiceProvider provider, List<CartItem> items) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          provider: provider,
          items: items,
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: item.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(item.imageUrl!, fit: BoxFit.cover),
                  )
                : const Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedImage01,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.currency(item.price),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Row(
            children: [
              IconButton(
                onPressed: item.quantity > 1
                    ? () => onQuantityChanged(item.quantity - 1)
                    : onRemove,
                icon: Icon(
                  item.quantity > 1 ? Icons.remove : Icons.delete_outline,
                  size: 20,
                  color: item.quantity > 1 ? AppColors.primaryNavy : AppColors.error,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  minimumSize: const Size(32, 32),
                ),
              ),
              Container(
                width: 36,
                alignment: Alignment.center,
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: () => onQuantityChanged(item.quantity + 1),
                icon: const Icon(Icons.add, size: 20, color: AppColors.primaryNavy),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1),
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Checkout page
class CheckoutPage extends StatefulWidget {
  final ServiceProvider provider;
  final List<CartItem> items;

  const CheckoutPage({
    super.key,
    required this.provider,
    required this.items,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  DeliveryType _deliveryType = DeliveryType.delivery;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _apartment;
  String? _unit;
  bool _isLoading = false;
  bool _saveForFuture = true;
  bool _isGettingLocation = false;
  double? _deliveryLatitude;
  double? _deliveryLongitude;

  @override
  void initState() {
    super.initState();
    _loadDeliverySettings();
  }

  Future<void> _loadDeliverySettings() async {
    final livingService = context.read<LivingService>();
    await livingService.loadDeliverySettings();
    
    final settings = livingService.deliverySettings;
    if (settings != null) {
      _nameController.text = settings.defaultName ?? '';
      _phoneController.text = settings.defaultPhone ?? '';
      _addressController.text = settings.defaultAddress ?? '';
      _instructionsController.text = settings.defaultInstructions ?? '';
      _apartment = settings.defaultApartment;
      _unit = settings.defaultUnit;
    }

    // Try to auto-fill from tenant info
    if (!mounted) return;
    final tenantService = context.read<TenantService>();
    if (tenantService.hasUnit) {
      final tenant = tenantService.currentTenant;
      final unit = tenantService.unit;
      final property = tenantService.property;
      
      if (_nameController.text.isEmpty && tenant != null) {
        _nameController.text = tenant.fullName;
      }
      if (_phoneController.text.isEmpty && tenant != null) {
        _phoneController.text = tenant.phone;
      }
      if (property != null) {
        _apartment = property.name;
        _addressController.text = property.locationText;
      }
      if (unit != null) {
        _unit = unit.unitLabel;
      }
    }
    
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get subtotal => widget.items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get deliveryFee => _deliveryType == DeliveryType.delivery ? 100.0 : 0.0;
  double get total => subtotal + deliveryFee;

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services')),
          );
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          setState(() => _isGettingLocation = false);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied')),
          );
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _deliveryLatitude = position.latitude;
      _deliveryLongitude = position.longitude;
      
      // Reverse geocode to get address
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[];
          
          if (p.thoroughfare != null && p.thoroughfare!.isNotEmpty) {
            parts.add(p.thoroughfare!);
          }
          if (p.subLocality != null && p.subLocality!.isNotEmpty) {
            parts.add(p.subLocality!);
          }
          if (p.locality != null && p.locality!.isNotEmpty) {
            if (parts.isEmpty || parts.last != p.locality) {
              parts.add(p.locality!);
            }
          }
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) {
            if (parts.isEmpty || parts.last != p.administrativeArea) {
              parts.add(p.administrativeArea!);
            }
          }
          
          if (parts.isNotEmpty) {
            _addressController.text = parts.join(', ');
          }
        }
      } catch (e) {
        debugPrint('Reverse geocoding error: $e');
      }
      
      setState(() => _isGettingLocation = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location set successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
      setState(() => _isGettingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Provider info
                _SectionCard(
                  title: 'Ordering from',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedStore01,
                          color: AppColors.primaryNavy,
                          size: 24,
                        ),
                      ),
                    ),
                    title: Text(widget.provider.businessName),
                    subtitle: Text(widget.provider.category.label),
                  ),
                ),
                const SizedBox(height: 16),

                // Items summary
                _SectionCard(
                  title: 'Items (${widget.items.length})',
                  child: Column(
                    children: widget.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            '${item.quantity}x',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(item.title)),
                          Text(Formatters.currency(item.totalPrice)),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Delivery type
                _SectionCard(
                  title: 'Delivery Method',
                  child: Column(
                    children: [
                      RadioListTile<DeliveryType>(
                        value: DeliveryType.delivery,
                        groupValue: _deliveryType,
                        onChanged: (v) => setState(() => _deliveryType = v!),
                        title: const Text('Delivery'),
                        subtitle: const Text('Delivered to your address'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<DeliveryType>(
                        value: DeliveryType.pickup,
                        groupValue: _deliveryType,
                        onChanged: (v) => setState(() => _deliveryType = v!),
                        title: const Text('Pickup'),
                        subtitle: const Text('Collect from provider'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Contact info
                _SectionCard(
                  title: 'Contact Information',
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          prefixIcon: Icon(Icons.phone_outlined),
                          hintText: '+254...',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),

                // Delivery address (only for delivery)
                if (_deliveryType == DeliveryType.delivery) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Delivery Address',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_apartment != null || _unit != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryNavy.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedBuilding01,
                                  color: AppColors.primaryNavy,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_apartment != null)
                                        Text(
                                          _apartment!,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      if (_unit != null)
                                        Text(
                                          'Unit: $_unit',
                                          style: TextStyle(color: Colors.grey.shade600),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        TextField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address/Location',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        
                        // Use Current Location button
                        OutlinedButton.icon(
                          onPressed: _isGettingLocation ? null : _getCurrentLocation,
                          icon: _isGettingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location, size: 18),
                          label: Text(_isGettingLocation 
                              ? 'Getting location...' 
                              : 'Use Current Location'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                          ),
                        ),
                        
                        // Show coordinates if available
                        if (_deliveryLatitude != null && _deliveryLongitude != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, 
                                    color: AppColors.success, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'GPS coordinates captured',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _deliveryLatitude = null;
                                    _deliveryLongitude = null;
                                  }),
                                  child: const Icon(Icons.close, 
                                      color: AppColors.success, size: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        
                        TextField(
                          controller: _instructionsController,
                          decoration: const InputDecoration(
                            labelText: 'Delivery Instructions (optional)',
                            hintText: 'e.g., Gate code, landmark',
                            prefixIcon: Icon(Icons.info_outline),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Save for future orders checkbox
                CheckboxListTile(
                  value: _saveForFuture,
                  onChanged: (v) => setState(() => _saveForFuture = v ?? true),
                  title: const Text(
                    'Save details for future orders',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Auto-fill contact and delivery info next time',
                    style: TextStyle(fontSize: 12),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                const SizedBox(height: 8),

                // Notes
                _SectionCard(
                  title: 'Order Notes (optional)',
                  child: TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Any special requests?',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 16),

                // Payment method
                _SectionCard(
                  title: 'Payment Method',
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.payments_outlined, color: Colors.green.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pay on Delivery',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              Text(
                                'Cash or M-Pesa on delivery',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // Bottom bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal'),
                      Text(Formatters.currency(subtotal)),
                    ],
                  ),
                  if (_deliveryType == DeliveryType.delivery) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Fee'),
                        Text(Formatters.currency(deliveryFee)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        Formatters.currency(total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _placeOrder,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Place Order • ${Formatters.currency(total)}',
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    // Validate
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final livingService = context.read<LivingService>();
      
      // Save delivery settings for future use (if opted in)
      if (_saveForFuture) {
        await livingService.saveDeliverySettings(
          name: _nameController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          apartment: _apartment,
          unit: _unit,
          instructions: _instructionsController.text,
        );
      }

      // Place order
      final order = await livingService.placeOrder(
        providerId: widget.provider.id,
        items: widget.items,
        deliveryType: _deliveryType,
        deliveryName: _nameController.text,
        deliveryPhone: _phoneController.text,
        deliveryAddress: _deliveryType == DeliveryType.delivery ? _addressController.text : null,
        deliveryApartment: _deliveryType == DeliveryType.delivery ? _apartment : null,
        deliveryUnit: _deliveryType == DeliveryType.delivery ? _unit : null,
        deliveryInstructions: _deliveryType == DeliveryType.delivery ? _instructionsController.text : null,
        customerNotes: _notesController.text.isEmpty ? null : _notesController.text,
        deliveryLatitude: _deliveryType == DeliveryType.delivery ? _deliveryLatitude : null,
        deliveryLongitude: _deliveryType == DeliveryType.delivery ? _deliveryLongitude : null,
      );

      if (mounted && order != null) {
        // Show success
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: AppColors.success, size: 64),
            title: const Text('Order Placed!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Order #${order.orderNumber}'),
                const SizedBox(height: 8),
                const Text('The provider will confirm your order shortly.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.go('/tenant/orders'); // Go to orders page
                },
                child: const Text('View Orders'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.pop(); // Go back to cart (which should be empty now)
                  context.pop(); // Go back to living page
                },
                child: const Text('Continue Shopping', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}
