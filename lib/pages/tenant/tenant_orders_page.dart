import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:oxy/models/order.dart';
import 'package:oxy/services/living_service.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/utils/formatters.dart';
import 'package:oxy/components/empty_state.dart';

/// Page showing customer's orders
class TenantOrdersPage extends StatefulWidget {
  const TenantOrdersPage({super.key});

  @override
  State<TenantOrdersPage> createState() => _TenantOrdersPageState();
}

class _TenantOrdersPageState extends State<TenantOrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final livingService = context.read<LivingService>();
      livingService.loadCustomerOrders();
      livingService.setupCustomerOrdersRealtime();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: Consumer<LivingService>(
        builder: (context, livingService, _) {
          final orders = livingService.customerOrders;
          final activeOrders = orders.where((o) => o.status.isActive).toList();
          final pastOrders = orders.where((o) => !o.status.isActive).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _OrdersList(
                orders: activeOrders,
                emptyMessage: 'No active orders',
                emptyIcon: HugeIcons.strokeRoundedShoppingCart01,
              ),
              _OrdersList(
                orders: pastOrders,
                emptyMessage: 'No past orders',
                emptyIcon: HugeIcons.strokeRoundedPackage,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<Order> orders;
  final String emptyMessage;
  final IconData emptyIcon;

  const _OrdersList({
    required this.orders,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return EmptyState(
        icon: emptyIcon,
        title: emptyMessage,
        message: 'Your orders will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<LivingService>().loadCustomerOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _OrderCard(order: orders[index]);
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showOrderDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: order.providerLogo != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(order.providerLogo!, fit: BoxFit.cover),
                          )
                        : const Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedStore01,
                              color: AppColors.primaryNavy,
                              size: 24,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.providerName ?? 'Provider',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '#${order.orderNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Items summary
              Text(
                '${order.items.length} item${order.items.length > 1 ? 's' : ''} • ${order.deliveryType.label}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),

              // Total and time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.currency(order.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  Text(
                    Formatters.relativeDate(order.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              // Actions for active orders
              if (order.status.canCancel) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _cancelOrder(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        child: const Text('Cancel Order'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderDetailsSheet(order: order),
    );
  }

  void _cancelOrder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<LivingService>().cancelOrder(order.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order cancelled')),
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
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case OrderStatus.confirmed:
      case OrderStatus.preparing:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      case OrderStatus.ready:
      case OrderStatus.outForDelivery:
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        break;
      case OrderStatus.delivered:
      case OrderStatus.completed:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case OrderStatus.cancelled:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(status.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }
}

class _OrderDetailsSheet extends StatelessWidget {
  final Order order;

  const _OrderDetailsSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
            // Handle
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order.orderNumber}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            Formatters.dateTime(order.createdAt),
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      _StatusBadge(status: order.status),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Provider info
                  ListTile(
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
                    title: Text(order.providerName ?? 'Provider'),
                    subtitle: Text(order.deliveryType.label),
                  ),
                  const SizedBox(height: 16),

                  // Order items
                  const Text(
                    'Order Items',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '${item.quantity}x',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                              if (item.notes != null)
                                Text(
                                  item.notes!,
                                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          Formatters.currency(item.totalPrice),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )),
                  const Divider(height: 24),

                  // Pricing
                  _PriceRow(label: 'Subtotal', amount: order.subtotal),
                  _PriceRow(label: 'Delivery Fee', amount: order.deliveryFee),
                  const SizedBox(height: 8),
                  _PriceRow(label: 'Total', amount: order.totalAmount, isTotal: true),
                  const SizedBox(height: 24),

                  // Delivery info
                  if (order.deliveryType == DeliveryType.delivery) ...[
                    const Text(
                      'Delivery Address',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.deliveryName, style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text(order.deliveryPhone),
                          if (order.deliveryAddress != null) Text(order.deliveryAddress!),
                          if (order.deliveryApartment != null || order.deliveryUnit != null)
                            Text('${order.deliveryApartment ?? ''} ${order.deliveryUnit != null ? '- ${order.deliveryUnit}' : ''}'.trim()),
                          if (order.deliveryInstructions != null)
                            Text(
                              'Note: ${order.deliveryInstructions}',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  // Customer notes
                  if (order.customerNotes != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Your Notes',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(order.customerNotes!),
                  ],

                  // Provider notes
                  if (order.providerNotes != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Provider Notes',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(order.providerNotes!),
                  ],

                  // Cancellation reason
                  if (order.status == OrderStatus.cancelled && order.cancellationReason != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cancelled: ${order.cancellationReason}',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isTotal;

  const _PriceRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            Formatters.currency(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? AppColors.primaryNavy : null,
            ),
          ),
        ],
      ),
    );
  }
}
