import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/nav.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/models/invoice.dart';
import 'package:oxy/models/lease.dart';
import 'package:oxy/models/tenant.dart';
import 'package:oxy/utils/formatters.dart';
import 'package:oxy/components/list_cards.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TenantDetailPage extends StatefulWidget {
  final String tenantId;
  const TenantDetailPage({super.key, required this.tenantId});

  @override
  State<TenantDetailPage> createState() => _TenantDetailPageState();
}

class _TenantDetailPageState extends State<TenantDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
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

  Future<void> _exportLeasePdf(BuildContext context, DataService dataService) async {
    final tenant = dataService.getTenantById(widget.tenantId);
    final lease = dataService.getActiveLeaseForTenant(widget.tenantId);
    final unit = lease != null ? dataService.getUnitById(lease.unitId) : null;
    final property = lease != null ? dataService.getPropertyById(lease.propertyId) : null;
    
    if (tenant == null || lease == null || unit == null || property == null) return;

    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('LEASE AGREEMENT', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              
              pw.Text('TENANT INFORMATION', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _pdfRow('Name', tenant.fullName),
              _pdfRow('Phone', tenant.phone),
              if (tenant.email != null) _pdfRow('Email', tenant.email!),
              if (tenant.idNumber != null) _pdfRow('ID Number', tenant.idNumber!),
              
              pw.SizedBox(height: 20),
              pw.Text('PROPERTY INFORMATION', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _pdfRow('Property', property.name),
              _pdfRow('Unit', unit.unitLabel),
              _pdfRow('Location', property.locationText),
              
              pw.SizedBox(height: 20),
              pw.Text('LEASE TERMS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _pdfRow('Start Date', Formatters.shortDate(lease.startDate)),
              _pdfRow('End Date', lease.endDate != null ? Formatters.shortDate(lease.endDate!) : 'Open-ended'),
              _pdfRow('Monthly Rent', Formatters.currency(lease.rentAmount)),
              _pdfRow('Deposit', Formatters.currency(lease.depositAmount)),
              _pdfRow('Due Day', '${lease.dueDay}th of each month'),
              _pdfRow('Grace Period', '${lease.graceDays} days'),
              _pdfRow('Status', lease.status.name.toUpperCase()),
              
              pw.SizedBox(height: 40),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text('Generated on ${Formatters.shortDate(DateTime.now())}', 
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 150, child: pw.Text('$label:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  Future<void> _exportInvoicePdf(Invoice invoice, DataService dataService) async {
    final tenant = dataService.getTenantById(widget.tenantId);
    final unit = dataService.getUnitById(invoice.unitId);
    final property = dataService.getPropertyById(invoice.propertyId);
    final lines = invoice.lines;
    
    if (tenant == null || unit == null || property == null) return;

    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('INVOICE', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
                      pw.Text(invoice.status == InvoiceStatus.void_ ? 'VOID' : '', 
                        style: pw.TextStyle(fontSize: 14, color: PdfColors.orange)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Invoice #${invoice.id.substring(0, 8).toUpperCase()}'),
                      pw.Text('Date: ${Formatters.shortDate(invoice.periodStart)}'),
                      pw.Text('Due: ${Formatters.shortDate(invoice.dueDate)}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BILL TO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Text(tenant.fullName),
                        pw.Text(tenant.phone),
                        if (tenant.email != null) pw.Text(tenant.email!),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('PROPERTY:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Text(property.name),
                        pw.Text('Unit: ${unit.unitLabel}'),
                        pw.Text(property.locationText),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              
              // Invoice lines table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  ...lines.map((line) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(line.description)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(Formatters.currency(line.amount), textAlign: pw.TextAlign.right)),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 20),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _pdfSummaryRow('Subtotal', Formatters.currency(invoice.totalAmount)),
                      _pdfSummaryRow('Paid', Formatters.currency(invoice.totalAmount - invoice.balanceAmount)),
                      pw.Divider(),
                      _pdfSummaryRow('Balance Due', Formatters.currency(invoice.balanceAmount), bold: true),
                    ],
                  ),
                ],
              ),
              
              pw.Spacer(),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text('Thank you for your business!', style: const pw.TextStyle(fontSize: 12)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _pdfSummaryRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(width: 100, child: pw.Text(label, style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null)),
          pw.SizedBox(width: 100, child: pw.Text(value, textAlign: pw.TextAlign.right, style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(
      builder: (context, dataService, _) {
        final tenant = dataService.getTenantById(widget.tenantId);
        if (tenant == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Tenant Not Found')),
            body: const Center(child: Text('Tenant not found')),
          );
        }

        final lease = dataService.getActiveLeaseForTenant(widget.tenantId);
        final unit = lease != null ? dataService.getUnitById(lease.unitId) : null;
        final property = lease != null ? dataService.getPropertyById(lease.propertyId) : null;
        
        final allInvoices = dataService.getInvoicesForTenant(widget.tenantId)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final openInvoices = allInvoices.where((i) => i.status == InvoiceStatus.open).toList();
        final paidInvoices = allInvoices.where((i) => i.status == InvoiceStatus.paid).toList();
        final voidInvoices = allInvoices.where((i) => i.status == InvoiceStatus.void_).toList();
        
        final payments = dataService.getPaymentsForTenant(widget.tenantId)
          ..sort((a, b) => b.paidAt.compareTo(a.paidAt));
        final totalBalance = allInvoices
            .where((i) => i.status == InvoiceStatus.open)
            .fold<double>(0, (sum, i) => sum + i.balanceAmount);

        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primaryTeal,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  if (lease != null)
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                      tooltip: 'Export Lease PDF',
                      onPressed: () => _exportLeasePdf(context, dataService),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () => _showEditTenantDialog(context, dataService, tenant),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'terminate_lease' && lease != null) {
                        _showTerminateLeaseDialog(context, dataService, lease);
                      }
                    },
                    itemBuilder: (context) => [
                      if (lease != null)
                        const PopupMenuItem(value: 'terminate_lease', child: Text('Terminate Lease')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete Tenant', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.primaryDark, AppColors.primaryTeal],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: Text(
                              tenant.initials,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            tenant.fullName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.phone(tenant.phone),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Actions
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.add_card,
                              label: 'Record Payment',
                              color: AppColors.success,
                              onTap: () => context.push('${AppRoutes.addPayment}?tenantId=${widget.tenantId}'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.receipt_long,
                              label: 'New Invoice',
                              color: AppColors.primaryTeal,
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.build_outlined,
                              label: 'Create Ticket',
                              color: AppColors.warning,
                              onTap: unit != null 
                                  ? () => context.push('${AppRoutes.addTicket}?unitId=${unit.id}')
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Balance Card
                      if (totalBalance > 0)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Outstanding Balance',
                                      style: TextStyle(fontSize: 12, color: AppColors.error),
                                    ),
                                    Text(
                                      Formatters.currency(totalBalance),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => context.push('${AppRoutes.addPayment}?tenantId=${widget.tenantId}'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                child: const Text('Pay Now', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Contact Info
                      _SectionCard(
                        title: 'Contact Information',
                        children: [
                          _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: Formatters.phone(tenant.phone)),
                          if (tenant.email != null) _InfoRow(icon: Icons.email_outlined, label: 'Email', value: tenant.email!),
                          if (tenant.idNumber != null) _InfoRow(icon: Icons.badge_outlined, label: 'ID Number', value: tenant.idNumber!),
                          if (tenant.nextOfKinName != null) ...[
                            const Divider(height: 24),
                            Text('Next of Kin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightOnSurfaceVariant)),
                            const SizedBox(height: 8),
                            _InfoRow(icon: Icons.person_outline, label: 'Name', value: tenant.nextOfKinName!),
                            if (tenant.nextOfKinPhone != null) _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: Formatters.phone(tenant.nextOfKinPhone!)),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Active Lease
                      if (lease != null && unit != null && property != null)
                        _LeaseCard(
                          lease: lease,
                          unit: unit,
                          property: property,
                          onExportPdf: () => _exportLeasePdf(context, dataService),
                        ),
                      
                      if (lease == null)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.home_outlined, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              const Text('No active lease'),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {},
                                child: const Text('Assign Unit'),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Invoices Section with Tabs
                      Text(
                        'Invoices',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            TabBar(
                              controller: _tabController,
                              labelColor: AppColors.primaryTeal,
                              unselectedLabelColor: AppColors.lightOnSurfaceVariant,
                              indicatorColor: AppColors.primaryTeal,
                              tabs: [
                                Tab(text: 'Open (${openInvoices.length})'),
                                Tab(text: 'Paid (${paidInvoices.length})'),
                                Tab(text: 'Void (${voidInvoices.length})'),
                              ],
                            ),
                            SizedBox(
                              height: allInvoices.isEmpty ? 150 : (allInvoices.length.clamp(1, 5) * 90.0 + 20),
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _InvoiceList(
                                    invoices: openInvoices,
                                    dataService: dataService,
                                    tenant: tenant,
                                    onExportPdf: _exportInvoicePdf,
                                  ),
                                  _InvoiceList(
                                    invoices: paidInvoices,
                                    dataService: dataService,
                                    tenant: tenant,
                                    onExportPdf: _exportInvoicePdf,
                                  ),
                                  _InvoiceList(
                                    invoices: voidInvoices,
                                    dataService: dataService,
                                    tenant: tenant,
                                    onExportPdf: _exportInvoicePdf,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Recent Payments
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Payments',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          TextButton(onPressed: () {}, child: const Text('View All')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              if (payments.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.payment, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text('No payments yet'),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= 5 || index >= payments.length) return null;
                      return PaymentCard(payment: payments[index], tenantName: tenant.fullName);
                    },
                    childCount: payments.length.clamp(0, 5),
                  ),
                ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  void _showEditTenantDialog(BuildContext context, DataService dataService, Tenant tenant) {
    final nameController = TextEditingController(text: tenant.fullName);
    final phoneController = TextEditingController(text: tenant.phone);
    final emailController = TextEditingController(text: tenant.email ?? '');
    final idNumberController = TextEditingController(text: tenant.idNumber ?? '');
    final nextOfKinNameController = TextEditingController(text: tenant.nextOfKinName ?? '');
    final nextOfKinPhoneController = TextEditingController(text: tenant.nextOfKinPhone ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Tenant'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name *'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone *'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: idNumberController,
                  decoration: const InputDecoration(labelText: 'ID Number'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nextOfKinNameController,
                  decoration: const InputDecoration(labelText: 'Next of Kin Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nextOfKinPhoneController,
                  decoration: const InputDecoration(labelText: 'Next of Kin Phone'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              
              Navigator.pop(context);
              
              final updatedTenant = tenant.copyWith(
                fullName: nameController.text.trim(),
                phone: phoneController.text.trim(),
                email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                idNumber: idNumberController.text.trim().isEmpty ? null : idNumberController.text.trim(),
                nextOfKinName: nextOfKinNameController.text.trim().isEmpty ? null : nextOfKinNameController.text.trim(),
                nextOfKinPhone: nextOfKinPhoneController.text.trim().isEmpty ? null : nextOfKinPhoneController.text.trim(),
                updatedAt: DateTime.now(),
              );
              
              await dataService.updateTenant(updatedTenant);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tenant updated'), backgroundColor: AppColors.success),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTerminateLeaseDialog(BuildContext context, DataService dataService, Lease lease) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminate Lease'),
        content: const Text('Are you sure you want to terminate this lease? The unit will be marked as vacant.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final updatedLease = lease.copyWith(
                status: LeaseStatus.ended,
                endDate: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              await dataService.updateLease(updatedLease);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lease terminated'), backgroundColor: AppColors.success),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Terminate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _InvoiceList extends StatelessWidget {
  final List<Invoice> invoices;
  final DataService dataService;
  final dynamic tenant;
  final Function(Invoice, DataService) onExportPdf;

  const _InvoiceList({
    required this.invoices,
    required this.dataService,
    required this.tenant,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('No invoices', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        final unit = dataService.getUnitById(invoice.unitId);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(invoice.status).withValues(alpha: 0.1),
              child: Icon(Icons.receipt, color: _getStatusColor(invoice.status), size: 20),
            ),
            title: Text('${Formatters.monthYear(invoice.periodStart)} Invoice'),
            subtitle: Text('${unit?.unitLabel ?? ""} • ${Formatters.currency(invoice.totalAmount)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, size: 20),
                  onPressed: () => onExportPdf(invoice, dataService),
                  tooltip: 'Export PDF',
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
            onTap: () => context.push('/invoices/${invoice.id}'),
          ),
        );
      },
    );
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.open: return AppColors.info;
      case InvoiceStatus.paid: return AppColors.success;
      case InvoiceStatus.void_: return AppColors.error;
    }
  }
}

class _LeaseCard extends StatelessWidget {
  final Lease lease;
  final dynamic unit;
  final dynamic property;
  final VoidCallback onExportPdf;

  const _LeaseCard({
    required this.lease,
    required this.unit,
    required this.property,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active Lease', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, size: 20),
                    onPressed: onExportPdf,
                    tooltip: 'Export PDF',
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Active', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(unit.unitLabel, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(property.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${unit.unitType ?? "Unit"} • ${Formatters.currency(lease.rentAmount)}/mo',
                      style: TextStyle(fontSize: 13, color: AppColors.lightOnSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _LeaseInfo(label: 'Start Date', value: Formatters.shortDate(lease.startDate))),
              Expanded(child: _LeaseInfo(label: 'End Date', value: lease.endDate != null ? Formatters.shortDate(lease.endDate!) : 'Open')),
              Expanded(child: _LeaseInfo(label: 'Deposit', value: Formatters.compactCurrency(lease.depositAmount))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _LeaseInfo(label: 'Due Day', value: '${lease.dueDay}th')),
              Expanded(child: _LeaseInfo(label: 'Grace Period', value: '${lease.graceDays} days')),
              Expanded(child: _LeaseInfo(label: 'Late Fee', value: lease.lateFeeType.name)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: onTap != null ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: onTap != null ? color : Colors.grey),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: onTap != null ? color : Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.lightOnSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: AppColors.lightOnSurfaceVariant)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaseInfo extends StatelessWidget {
  final String label;
  final String value;

  const _LeaseInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.lightOnSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
