import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/services/tenant_service.dart';
import 'package:oxy/components/empty_state.dart';
import 'package:oxy/components/loading_indicator.dart';
import 'package:oxy/utils/formatters.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TenantLeasePage extends StatelessWidget {
  const TenantLeasePage({super.key});

  Future<void> _exportLeasePdf(BuildContext context, TenantService tenantService) async {
    final tenant = tenantService.currentTenant;
    final lease = tenantService.activeLease;
    final unit = tenantService.unit;
    final property = tenantService.property;

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

  static pw.Widget _pdfRow(String label, String value) {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<TenantService>(
      builder: (context, tenantService, _) {
        if (tenantService.isLoading) {
          return Scaffold(
            backgroundColor: AppColors.lightBackground,
            appBar: AppBar(
              backgroundColor: AppColors.primaryTeal,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/tenant'),
              ),
              title: const Text('My Lease', style: TextStyle(color: Colors.white)),
            ),
            body: const OxyLoadingOverlay(message: 'Loading lease...'),
          );
        }

        final lease = tenantService.activeLease;
        final property = tenantService.property;
        final unit = tenantService.unit;

        if (lease == null || property == null || unit == null) {
          return Scaffold(
            backgroundColor: AppColors.lightBackground,
            appBar: AppBar(
              backgroundColor: AppColors.primaryTeal,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/tenant'),
              ),
              title: const Text('My Lease', style: TextStyle(color: Colors.white)),
            ),
            body: const EmptyState(
              icon: Icons.description_outlined,
              title: 'No Active Lease',
              message: 'You don\'t have an active lease at the moment.',
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.go('/tenant'),
            ),
            title: const Text('My Lease', style: TextStyle(color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                tooltip: 'Export PDF',
                onPressed: () => _exportLeasePdf(context, tenantService),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => tenantService.refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryTeal, AppColors.primaryDark],
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
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.home, color: Colors.white, size: 24),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                lease.status.name.toUpperCase(),
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
                        Text(
                          property.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          unit.unitLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Lease Details
                  _SectionCard(
                    title: 'Lease Terms',
                    children: [
                      _InfoRow(icon: Icons.calendar_today, label: 'Start Date', value: Formatters.date(lease.startDate)),
                      _InfoRow(
                        icon: Icons.event,
                        label: 'End Date',
                        value: lease.endDate != null ? Formatters.date(lease.endDate!) : 'Open-ended',
                      ),
                      _InfoRow(icon: Icons.payments, label: 'Monthly Rent', value: Formatters.currency(lease.rentAmount)),
                      _InfoRow(icon: Icons.savings, label: 'Deposit Paid', value: Formatters.currency(lease.depositAmount)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Payment Schedule
                  _SectionCard(
                    title: 'Payment Schedule',
                    children: [
                      _InfoRow(icon: Icons.today, label: 'Due Day', value: '${lease.dueDay}th of each month'),
                      _InfoRow(icon: Icons.timer, label: 'Grace Period', value: '${lease.graceDays} days'),
                      _InfoRow(
                        icon: Icons.warning_amber,
                        label: 'Late Fee',
                        value: lease.lateFeeType.name == 'none' ? 'No late fee' : '${lease.lateFeeType.name} - ${lease.lateFeeValue ?? 0}',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Property Info
                  _SectionCard(
                    title: 'Property Information',
                    children: [
                      _InfoRow(icon: Icons.apartment, label: 'Property', value: property.name),
                      _InfoRow(icon: Icons.door_front_door, label: 'Unit', value: unit.unitLabel),
                      if (unit.unitType != null) _InfoRow(icon: Icons.category, label: 'Type', value: unit.unitType!),
                      _InfoRow(icon: Icons.location_on, label: 'Location', value: property.locationText),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Export Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _exportLeasePdf(context, tenantService),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Export Lease as PDF'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
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
