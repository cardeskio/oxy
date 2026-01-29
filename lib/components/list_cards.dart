import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/models/property.dart';
import 'package:oxy/models/unit.dart';
import 'package:oxy/models/tenant.dart';
import 'package:oxy/models/invoice.dart';
import 'package:oxy/models/payment.dart';
import 'package:oxy/models/maintenance_ticket.dart';
import 'package:oxy/utils/formatters.dart';
import 'package:oxy/utils/icons.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final int unitCount;
  final int occupiedCount;
  final VoidCallback onTap;

  const PropertyCard({
    super.key,
    required this.property,
    required this.unitCount,
    required this.occupiedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final occupancyRate = unitCount > 0 ? (occupiedCount / unitCount * 100).toInt() : 0;
    final imageUrl = property.coverImageUrl;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Property image or fallback icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _getPropertyColor(property.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? Center(
                      child: HugeIcon(
                        icon: _getPropertyIcon(property.type),
                        color: _getPropertyColor(property.type),
                        size: 28,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      HugeIcon(icon: AppIcons.location, size: 14, color: AppColors.lightOnSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.locationText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(
                        label: '$unitCount units',
                        icon: AppIcons.door,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        label: '$occupancyRate% occupied',
                        icon: AppIcons.people,
                        color: occupancyRate >= 80 ? AppColors.success : (occupancyRate >= 50 ? AppColors.warning : AppColors.error),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            HugeIcon(icon: AppIcons.chevronRight, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  IconData _getPropertyIcon(PropertyType type) {
    switch (type) {
      case PropertyType.residential: return AppIcons.house;
      case PropertyType.commercial: return AppIcons.commercial;
      case PropertyType.mixed: return AppIcons.apartment;
    }
  }

  Color _getPropertyColor(PropertyType type) {
    switch (type) {
      case PropertyType.residential: return AppColors.primaryTeal;
      case PropertyType.commercial: return AppColors.info;
      case PropertyType.mixed: return Colors.purple;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;

  const _InfoChip({required this.label, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.lightOnSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: chipColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class UnitCard extends StatelessWidget {
  final Unit unit;
  final String? tenantName;
  final String? fallbackImageUrl; // Use property image if unit has no image
  final VoidCallback? onTap;

  const UnitCard({
    super.key,
    required this.unit,
    this.tenantName,
    this.fallbackImageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use unit image, or fall back to property image
    final imageUrl = unit.coverImageUrl ?? fallbackImageUrl;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightOutline),
        ),
        child: Row(
          children: [
            // Unit image or fallback to label
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getStatusColor(unit.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? Center(
                      child: Text(
                        unit.unitLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(unit.status),
                          fontSize: 14,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        unit.unitLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (unit.unitType != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '• ${unit.unitType}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                      ],
                      const Spacer(),
                      _StatusBadge(status: unit.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.currency(unit.rentAmount),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  if (tenantName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        HugeIcon(icon: AppIcons.person, size: 14, color: AppColors.lightOnSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          tenantName!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                      ],
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

  Color _getStatusColor(UnitStatus status) {
    switch (status) {
      case UnitStatus.vacant: return AppColors.success;
      case UnitStatus.occupied: return AppColors.info;
      case UnitStatus.maintenance: return AppColors.warning;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final UnitStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case UnitStatus.vacant:
        color = AppColors.success;
        label = 'Vacant';
        break;
      case UnitStatus.occupied:
        color = AppColors.info;
        label = 'Occupied';
        break;
      case UnitStatus.maintenance:
        color = AppColors.warning;
        label = 'Maintenance';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class TenantCard extends StatelessWidget {
  final Tenant tenant;
  final String? unitInfo;
  final double? balance;
  final VoidCallback onTap;

  const TenantCard({
    super.key,
    required this.tenant,
    this.unitInfo,
    this.balance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
              child: Text(
                tenant.initials,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTeal,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tenant.fullName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      HugeIcon(icon: AppIcons.phone, size: 14, color: AppColors.lightOnSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.phone(tenant.phone),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.lightOnSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (unitInfo != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        HugeIcon(icon: AppIcons.house, size: 14, color: AppColors.lightOnSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          unitInfo!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (balance != null && balance! > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(balance!),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  Text(
                    'Balance',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.lightOnSurfaceVariant,
                    ),
                  ),
                ],
              )
            else
              HugeIcon(icon: AppIcons.chevronRight, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final String tenantName;
  final String unitLabel;
  final VoidCallback onTap;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.tenantName,
    required this.unitLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(invoice.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    invoice.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(invoice.status),
                    ),
                  ),
                ),
                if (invoice.isOverdue) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(icon: AppIcons.warning, size: 12, color: AppColors.error),
                        SizedBox(width: 4),
                        Text(
                          'Overdue',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  invoice.periodLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenantName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        unitLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.lightOnSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.currency(invoice.totalAmount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (invoice.balanceAmount > 0 && invoice.balanceAmount < invoice.totalAmount)
                      Text(
                        'Bal: ${Formatters.currency(invoice.balanceAmount)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                HugeIcon(icon: AppIcons.calendar, size: 14, color: AppColors.lightOnSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Due: ${Formatters.date(invoice.dueDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.open: return AppColors.warning;
      case InvoiceStatus.paid: return AppColors.success;
      case InvoiceStatus.void_: return AppColors.lightOnSurfaceVariant;
    }
  }
}

class PaymentCard extends StatelessWidget {
  final Payment payment;
  final String tenantName;
  final VoidCallback? onTap;

  const PaymentCard({
    super.key,
    required this.payment,
    required this.tenantName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: HugeIcon(
                icon: _getMethodIcon(payment.method),
                color: AppColors.success,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tenantName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        payment.methodLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.lightOnSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(color: AppColors.lightOnSurfaceVariant),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          payment.reference,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(payment.amount),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  Formatters.relativeDate(payment.paidAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesa: return AppIcons.phone;
      case PaymentMethod.cash: return AppIcons.money;
      case PaymentMethod.bank: return AppIcons.bank;
    }
  }
}

class TicketCard extends StatelessWidget {
  final MaintenanceTicket ticket;
  final String unitLabel;
  final VoidCallback? onTap;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.unitLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(ticket.priority).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ticket.priorityLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getPriorityColor(ticket.priority),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(ticket.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ticket.statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(ticket.status),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  Formatters.relativeDate(ticket.createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ticket.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                HugeIcon(icon: AppIcons.door, size: 14, color: AppColors.lightOnSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  unitLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                  ),
                ),
                if (ticket.vendorName != null) ...[
                  const SizedBox(width: 12),
                  HugeIcon(icon: AppIcons.tools, size: 14, color: AppColors.lightOnSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    ticket.vendorName!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.lightOnSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            if (ticket.totalCost > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  HugeIcon(icon: AppIcons.money, size: 14, color: AppColors.primaryTeal),
                  Text(
                    Formatters.currency(ticket.totalCost),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low: return AppColors.success;
      case TicketPriority.medium: return AppColors.warning;
      case TicketPriority.high: return AppColors.error;
    }
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.new_: return AppColors.info;
      case TicketStatus.assigned: return Colors.purple;
      case TicketStatus.inProgress: return AppColors.warning;
      case TicketStatus.done: return AppColors.primaryTeal;
      case TicketStatus.approved: return AppColors.success;
      case TicketStatus.rejected: return AppColors.error;
    }
  }
}
