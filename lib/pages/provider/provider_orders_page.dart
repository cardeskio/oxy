import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:oxy/models/order.dart';
import 'package:oxy/services/living_service.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/utils/formatters.dart';
import 'package:oxy/components/empty_state.dart';

/// Orders management page for service providers
class ProviderOrdersPage extends StatefulWidget {
  const ProviderOrdersPage({super.key});

  @override
  State<ProviderOrdersPage> createState() => _ProviderOrdersPageState();
}

class _ProviderOrdersPageState extends State<ProviderOrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final livingService = context.read<LivingService>();
      livingService.loadProviderOrders();
      livingService.setupProviderOrdersRealtime();
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
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'New'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Consumer<LivingService>(
        builder: (context, livingService, _) {
          final orders = livingService.providerOrders;
          final newOrders = orders.where((o) => o.status == OrderStatus.pending).toList();
          final activeOrders = orders.where((o) => 
              o.status != OrderStatus.pending && 
              o.status != OrderStatus.completed && 
              o.status != OrderStatus.cancelled
          ).toList();
          final completedOrders = orders.where((o) => 
              o.status == OrderStatus.completed || 
              o.status == OrderStatus.cancelled
          ).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _OrdersList(
                orders: newOrders,
                emptyMessage: 'No new orders',
                emptyIcon: HugeIcons.strokeRoundedInboxDownload,
                showBadge: true,
              ),
              _OrdersList(
                orders: activeOrders,
                emptyMessage: 'No active orders',
                emptyIcon: HugeIcons.strokeRoundedPackage,
              ),
              _OrdersList(
                orders: completedOrders,
                emptyMessage: 'No completed orders',
                emptyIcon: HugeIcons.strokeRoundedCheckmarkSquare02,
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
  final bool showBadge;

  const _OrdersList({
    required this.orders,
    required this.emptyMessage,
    required this.emptyIcon,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return EmptyState(
        icon: emptyIcon,
        title: emptyMessage,
        message: 'Orders will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<LivingService>().loadProviderOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _ProviderOrderCard(order: orders[index], isNew: showBadge);
        },
      ),
    );
  }
}

class _ProviderOrderCard extends StatelessWidget {
  final Order order;
  final bool isNew;

  const _ProviderOrderCard({required this.order, this.isNew = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showOrderDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: isNew && order.status == OrderStatus.pending
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning, width: 2),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    if (isNew && order.status == OrderStatus.pending)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${order.orderNumber}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            order.customerName ?? 'Customer',
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
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
                ...order.items.take(3).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${item.quantity}x ${item.title}',
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
                if (order.items.length > 3)
                  Text(
                    '+${order.items.length - 3} more items',
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),

                const SizedBox(height: 12),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          order.deliveryType.label,
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    Text(
                      Formatters.relativeDate(order.createdAt),
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),

                // Quick actions for pending orders
                if (order.status == OrderStatus.pending) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _rejectOrder(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _acceptOrder(context),
                          child: const Text('Accept', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
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
      builder: (context) => _ProviderOrderDetailsSheet(order: order),
    );
  }

  void _acceptOrder(BuildContext context) async {
    try {
      await context.read<LivingService>().updateOrderStatus(order.id, OrderStatus.confirmed);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order accepted'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _rejectOrder(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<LivingService>().updateOrderStatus(
                  order.id,
                  OrderStatus.cancelled,
                  notes: reasonController.text.isEmpty ? 'Rejected by provider' : reasonController.text,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order rejected')),
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
            child: const Text('Reject'),
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
      child: Text(status.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
    );
  }
}

class _ProviderOrderDetailsSheet extends StatelessWidget {
  final Order order;

  const _ProviderOrderDetailsSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
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
                  // Customer info
                  const Text(
                    'Customer',
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
                        Row(
                          children: [
                            HugeIcon(icon: HugeIcons.strokeRoundedUser, size: 18, color: Colors.grey.shade700),
                            const SizedBox(width: 8),
                            Text(order.deliveryName, style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            HugeIcon(icon: HugeIcons.strokeRoundedCall, size: 18, color: Colors.grey.shade700),
                            const SizedBox(width: 8),
                            Text(order.deliveryPhone),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

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
                          if (order.deliveryApartment != null || order.deliveryUnit != null)
                            Text(
                              '${order.deliveryApartment ?? ''} ${order.deliveryUnit != null ? '- Unit ${order.deliveryUnit}' : ''}'.trim(),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          if (order.deliveryAddress != null) Text(order.deliveryAddress!),
                          if (order.deliveryInstructions != null)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: Colors.amber.shade800),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      order.deliveryInstructions!,
                                      style: TextStyle(color: Colors.amber.shade800, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Order items
                  const Text(
                    'Order Items',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '${item.quantity}x',
                              style: const TextStyle(
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
                                  'Note: ${item.notes}',
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

                  // Customer notes
                  if (order.customerNotes != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Notes',
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue.shade700),
                          ),
                          const SizedBox(height: 4),
                          Text(order.customerNotes!, style: TextStyle(color: Colors.blue.shade900)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),

            // Action buttons
            if (order.status.isActive && order.status != OrderStatus.pending)
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
                  child: _StatusUpdateButton(order: order),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusUpdateButton extends StatelessWidget {
  final Order order;

  const _StatusUpdateButton({required this.order});

  @override
  Widget build(BuildContext context) {
    String buttonText;
    OrderStatus nextStatus;

    switch (order.status) {
      case OrderStatus.confirmed:
        buttonText = 'Start Preparing';
        nextStatus = OrderStatus.preparing;
        break;
      case OrderStatus.preparing:
        buttonText = 'Mark as Ready';
        nextStatus = OrderStatus.ready;
        break;
      case OrderStatus.ready:
        if (order.deliveryType == DeliveryType.delivery) {
          buttonText = 'Out for Delivery';
          nextStatus = OrderStatus.outForDelivery;
        } else {
          buttonText = 'Mark as Picked Up';
          nextStatus = OrderStatus.delivered;
        }
        break;
      case OrderStatus.outForDelivery:
        buttonText = 'Mark as Delivered';
        nextStatus = OrderStatus.delivered;
        break;
      case OrderStatus.delivered:
        buttonText = 'Complete Order';
        nextStatus = OrderStatus.completed;
        break;
      default:
        return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          try {
            await context.read<LivingService>().updateOrderStatus(order.id, nextStatus);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Order updated to ${nextStatus.label}')),
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
        child: Text(buttonText, style: const TextStyle(color: Colors.white)),
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
