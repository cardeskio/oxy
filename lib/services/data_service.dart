import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:oxy/models/property.dart';
import 'package:oxy/models/unit.dart';
import 'package:oxy/models/tenant.dart';
import 'package:oxy/models/lease.dart';
import 'package:oxy/models/invoice.dart';
import 'package:oxy/models/payment.dart';
import 'package:oxy/models/maintenance_ticket.dart';
import 'package:oxy/models/audit_log.dart';
import 'package:oxy/supabase/supabase_config.dart';
import 'package:oxy/services/org_service.dart';

const _uuid = Uuid();

class DataService extends ChangeNotifier {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final OrgService _orgService = OrgService();

  List<Property> _properties = [];
  List<Unit> _units = [];
  List<Tenant> _tenants = [];
  List<Lease> _leases = [];
  List<Invoice> _invoices = [];
  List<Payment> _payments = [];
  List<MaintenanceTicket> _tickets = [];
  List<AuditLog> _auditLogs = [];
  bool _isLoading = true;
  bool _isInitialized = false;

  List<Property> get properties => _properties;
  List<Unit> get units => _units;
  List<Tenant> get tenants => _tenants;
  List<Lease> get leases => _leases;
  List<Invoice> get invoices => _invoices;
  List<Payment> get payments => _payments;
  List<MaintenanceTicket> get tickets => _tickets;
  List<AuditLog> get auditLogs => _auditLogs;
  bool get isLoading => _isLoading;
  
  String? get currentOrgId => _orgService.currentOrgId;

  Future<void> initialize() async {
    if (_isInitialized && currentOrgId != null) return;
    
    try {
      if (currentOrgId != null) {
        await _loadFromSupabase();
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('Failed to initialize DataService: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initialize data for a specific organization
  Future<void> initializeForOrg(String orgId) async {
    _isLoading = true;
    _isInitialized = false;
    notifyListeners();
    
    try {
      await _loadFromSupabase();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize DataService for org: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromSupabase() async {
    final orgId = currentOrgId;
    if (orgId == null) {
      debugPrint('No org selected, skipping data load');
      return;
    }

    try {
      // Load properties
      final propertiesData = await SupabaseService.select(
        'properties',
        filters: {'org_id': orgId},
        orderBy: 'created_at',
        ascending: false,
      );
      _properties = propertiesData.map((e) => Property.fromJson(e)).toList();

      // Load units
      final unitsData = await SupabaseService.select(
        'units',
        filters: {'org_id': orgId},
        orderBy: 'created_at',
        ascending: false,
      );
      _units = unitsData.map((e) => Unit.fromJson(e)).toList();

      // Load tenants
      final tenantsData = await SupabaseService.select(
        'tenants',
        filters: {'org_id': orgId},
        orderBy: 'created_at',
        ascending: false,
      );
      _tenants = tenantsData.map((e) => Tenant.fromJson(e)).toList();

      // Load leases
      final leasesData = await SupabaseService.select(
        'leases',
        filters: {'org_id': orgId},
        orderBy: 'created_at',
        ascending: false,
      );
      _leases = leasesData.map((e) => Lease.fromJson(e)).toList();

      // Load invoices with lines
      final invoicesData = await SupabaseService.select(
        'invoices',
        filters: {'org_id': orgId},
        orderBy: 'created_at',
        ascending: false,
      );
      _invoices = [];
      for (final invoiceData in invoicesData) {
        final linesData = await SupabaseService.select(
          'invoice_lines',
          filters: {'invoice_id': invoiceData['id']},
        );
        final lines = linesData.map((e) => InvoiceLine.fromJson(e)).toList();
        final invoice = Invoice.fromJson(invoiceData);
        _invoices.add(invoice.copyWith(lines: lines));
      }

      // Load payments with allocations
      final paymentsData = await SupabaseService.select(
        'payments',
        filters: {'org_id': orgId},
        orderBy: 'paid_at',
        ascending: false,
      );
      _payments = [];
      for (final paymentData in paymentsData) {
        final allocationsData = await SupabaseService.select(
          'payment_allocations',
          filters: {'payment_id': paymentData['id']},
        );
        final allocations = allocationsData.map((e) => PaymentAllocation.fromJson(e)).toList();
        final payment = Payment.fromJson(paymentData);
        _payments.add(payment.copyWith(allocations: allocations));
      }

      // Load maintenance tickets with costs
      final ticketsData = await SupabaseService.select(
        'maintenance_tickets',
        filters: {'org_id': orgId},
        orderBy: 'created_at',
        ascending: false,
      );
      _tickets = [];
      for (final ticketData in ticketsData) {
        final costsData = await SupabaseService.select(
          'maintenance_costs',
          filters: {'ticket_id': ticketData['id']},
        );
        final costs = costsData.map((e) => MaintenanceCost.fromJson(e)).toList();
        final ticket = MaintenanceTicket.fromJson(ticketData);
        _tickets.add(ticket.copyWith(costs: costs));
      }

      debugPrint('Loaded data for org $orgId: ${_properties.length} properties, ${_units.length} units, ${_tenants.length} tenants');
    } catch (e) {
      debugPrint('Error loading from Supabase: $e');
      rethrow;
    }
  }

  /// Refresh all data from Supabase
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _loadFromSupabase();
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Property CRUD
  List<Unit> getUnitsForProperty(String propertyId) => _units.where((u) => u.propertyId == propertyId).toList();
  
  int getUnitCountForProperty(String propertyId) => _units.where((u) => u.propertyId == propertyId).length;
  
  int getOccupiedUnitCountForProperty(String propertyId) => 
      _units.where((u) => u.propertyId == propertyId && u.status == UnitStatus.occupied).length;

  Future<void> addProperty(Property property) async {
    try {
      final data = property.toJson();
      data.remove('lines'); // Remove any nested data
      await SupabaseService.insert('properties', data);
      _properties.insert(0, property);
      await _logAudit(AuditLog.createProperty, 'property', property.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding property: $e');
      rethrow;
    }
  }

  Future<void> updateProperty(Property property) async {
    try {
      final data = property.toJson();
      await SupabaseService.update('properties', data, filters: {'id': property.id});
      final index = _properties.indexWhere((p) => p.id == property.id);
      if (index != -1) {
        _properties[index] = property;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating property: $e');
      rethrow;
    }
  }

  Future<void> deleteProperty(String id) async {
    try {
      await SupabaseService.delete('properties', filters: {'id': id});
      _properties.removeWhere((p) => p.id == id);
      _units.removeWhere((u) => u.propertyId == id);
      await _logAudit(AuditLog.deleteProperty, 'property', id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting property: $e');
      rethrow;
    }
  }

  // Unit CRUD
  Future<void> addUnit(Unit unit) async {
    try {
      final data = unit.toJson();
      await SupabaseService.insert('units', data);
      _units.insert(0, unit);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding unit: $e');
      rethrow;
    }
  }

  Future<void> updateUnit(Unit unit) async {
    try {
      final data = unit.toJson();
      await SupabaseService.update('units', data, filters: {'id': unit.id});
      final index = _units.indexWhere((u) => u.id == unit.id);
      if (index != -1) {
        _units[index] = unit;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating unit: $e');
      rethrow;
    }
  }

  Future<void> deleteUnit(String id) async {
    try {
      await SupabaseService.delete('units', filters: {'id': id});
      _units.removeWhere((u) => u.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting unit: $e');
      rethrow;
    }
  }

  Unit? getUnitById(String id) => _units.cast<Unit?>().firstWhere((u) => u?.id == id, orElse: () => null);
  Property? getPropertyById(String id) => _properties.cast<Property?>().firstWhere((p) => p?.id == id, orElse: () => null);

  // Tenant CRUD
  Future<void> addTenant(Tenant tenant) async {
    try {
      final data = tenant.toJson();
      await SupabaseService.insert('tenants', data);
      _tenants.insert(0, tenant);
      await _logAudit(AuditLog.createTenant, 'tenant', tenant.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding tenant: $e');
      rethrow;
    }
  }

  Future<void> updateTenant(Tenant tenant) async {
    try {
      final data = tenant.toJson();
      await SupabaseService.update('tenants', data, filters: {'id': tenant.id});
      final index = _tenants.indexWhere((t) => t.id == tenant.id);
      if (index != -1) {
        _tenants[index] = tenant;
        await _logAudit(AuditLog.updateTenant, 'tenant', tenant.id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating tenant: $e');
      rethrow;
    }
  }

  Future<void> deleteTenant(String id) async {
    try {
      await SupabaseService.delete('tenants', filters: {'id': id});
      _tenants.removeWhere((t) => t.id == id);
      await _logAudit(AuditLog.deleteTenant, 'tenant', id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting tenant: $e');
      rethrow;
    }
  }

  Tenant? getTenantById(String id) => _tenants.cast<Tenant?>().firstWhere((t) => t?.id == id, orElse: () => null);

  // Lease CRUD
  Lease? getActiveLeaseForUnit(String unitId) => 
      _leases.cast<Lease?>().firstWhere((l) => l?.unitId == unitId && l?.status == LeaseStatus.active, orElse: () => null);
  
  Lease? getActiveLeaseForTenant(String tenantId) => 
      _leases.cast<Lease?>().firstWhere((l) => l?.tenantId == tenantId && l?.status == LeaseStatus.active, orElse: () => null);

  List<Lease> getLeasesForTenant(String tenantId) => _leases.where((l) => l.tenantId == tenantId).toList();

  Future<void> addLease(Lease lease) async {
    try {
      final data = lease.toJson();
      await SupabaseService.insert('leases', data);
      _leases.insert(0, lease);
      await _logAudit(AuditLog.createLease, 'lease', lease.id);
      
      if (lease.status == LeaseStatus.active) {
        final unitIndex = _units.indexWhere((u) => u.id == lease.unitId);
        if (unitIndex != -1) {
          final updatedUnit = _units[unitIndex].copyWith(status: UnitStatus.occupied, updatedAt: DateTime.now());
          await updateUnit(updatedUnit);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding lease: $e');
      rethrow;
    }
  }

  Future<void> updateLease(Lease lease) async {
    try {
      final index = _leases.indexWhere((l) => l.id == lease.id);
      if (index != -1) {
        final oldLease = _leases[index];
        final data = lease.toJson();
        await SupabaseService.update('leases', data, filters: {'id': lease.id});
        _leases[index] = lease;
        
        // Log status changes
        if (oldLease.status != lease.status) {
          if (lease.status == LeaseStatus.active) {
            await _logAudit(AuditLog.activateLease, 'lease', lease.id);
          } else if (lease.status == LeaseStatus.ended) {
            await _logAudit(AuditLog.endLease, 'lease', lease.id);
          }
          
          final unitIndex = _units.indexWhere((u) => u.id == lease.unitId);
          if (unitIndex != -1) {
            UnitStatus newStatus = _units[unitIndex].status;
            if (lease.status == LeaseStatus.active) {
              newStatus = UnitStatus.occupied;
            } else if (lease.status == LeaseStatus.ended) {
              newStatus = UnitStatus.vacant;
            }
            final updatedUnit = _units[unitIndex].copyWith(status: newStatus, updatedAt: DateTime.now());
            await updateUnit(updatedUnit);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating lease: $e');
      rethrow;
    }
  }

  Lease? getLeaseById(String id) => _leases.cast<Lease?>().firstWhere((l) => l?.id == id, orElse: () => null);

  // Invoice CRUD
  List<Invoice> getInvoicesForTenant(String tenantId) => _invoices.where((i) => i.tenantId == tenantId).toList();
  List<Invoice> getInvoicesForLease(String leaseId) => _invoices.where((i) => i.leaseId == leaseId).toList();

  Future<void> addInvoice(Invoice invoice) async {
    try {
      final invoiceData = invoice.toJson();
      invoiceData.remove('lines');
      await SupabaseService.insert('invoices', invoiceData);
      
      for (final line in invoice.lines) {
        final lineData = line.toJson();
        await SupabaseService.insert('invoice_lines', lineData);
      }
      
      _invoices.insert(0, invoice);
      await _logAudit(AuditLog.createInvoice, 'invoice', invoice.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding invoice: $e');
      rethrow;
    }
  }

  Future<void> updateInvoice(Invoice invoice) async {
    try {
      final invoiceData = invoice.toJson();
      invoiceData.remove('lines');
      await SupabaseService.update('invoices', invoiceData, filters: {'id': invoice.id});
      
      await SupabaseService.delete('invoice_lines', filters: {'invoice_id': invoice.id});
      for (final line in invoice.lines) {
        final lineData = line.toJson();
        await SupabaseService.insert('invoice_lines', lineData);
      }
      
      final index = _invoices.indexWhere((i) => i.id == invoice.id);
      if (index != -1) {
        _invoices[index] = invoice;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating invoice: $e');
      rethrow;
    }
  }

  Future<void> voidInvoice(String invoiceId, String reason) async {
    try {
      final index = _invoices.indexWhere((i) => i.id == invoiceId);
      if (index != -1) {
        final invoice = _invoices[index].copyWith(
          status: InvoiceStatus.void_,
          updatedAt: DateTime.now(),
        );
        await updateInvoice(invoice);
        await _logAudit(AuditLog.voidInvoice, 'invoice', invoiceId, metadata: {'reason': reason});
      }
    } catch (e) {
      debugPrint('Error voiding invoice: $e');
      rethrow;
    }
  }

  Invoice? getInvoiceById(String id) => _invoices.cast<Invoice?>().firstWhere((i) => i?.id == id, orElse: () => null);

  // Payment CRUD
  List<Payment> getPaymentsForTenant(String tenantId) => _payments.where((p) => p.tenantId == tenantId).toList();

  Future<void> addPayment(Payment payment) async {
    try {
      final paymentData = payment.toJson();
      paymentData.remove('allocations');
      await SupabaseService.insert('payments', paymentData);
      
      for (final allocation in payment.allocations) {
        final allocationData = allocation.toJson();
        await SupabaseService.insert('payment_allocations', allocationData);
      }
      
      _payments.insert(0, payment);
      await _logAudit(AuditLog.createPayment, 'payment', payment.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding payment: $e');
      rethrow;
    }
  }

  Future<void> updatePayment(Payment payment) async {
    try {
      final paymentData = payment.toJson();
      paymentData.remove('allocations');
      await SupabaseService.update('payments', paymentData, filters: {'id': payment.id});
      
      await SupabaseService.delete('payment_allocations', filters: {'payment_id': payment.id});
      for (final allocation in payment.allocations) {
        final allocationData = allocation.toJson();
        await SupabaseService.insert('payment_allocations', allocationData);
      }
      
      final index = _payments.indexWhere((p) => p.id == payment.id);
      if (index != -1) {
        _payments[index] = payment;
        await _logAudit(AuditLog.editPayment, 'payment', payment.id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating payment: $e');
      rethrow;
    }
  }

  // Ticket CRUD
  List<MaintenanceTicket> getTicketsForProperty(String propertyId) => _tickets.where((t) => t.propertyId == propertyId).toList();
  List<MaintenanceTicket> getTicketsForUnit(String unitId) => _tickets.where((t) => t.unitId == unitId).toList();

  Future<void> addTicket(MaintenanceTicket ticket) async {
    try {
      final ticketData = ticket.toJson();
      ticketData.remove('costs');
      await SupabaseService.insert('maintenance_tickets', ticketData);
      
      for (final cost in ticket.costs) {
        final costData = cost.toJson();
        await SupabaseService.insert('maintenance_costs', costData);
      }
      
      _tickets.insert(0, ticket);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding ticket: $e');
      rethrow;
    }
  }

  Future<void> updateTicket(MaintenanceTicket ticket) async {
    try {
      final ticketData = ticket.toJson();
      ticketData.remove('costs');
      await SupabaseService.update('maintenance_tickets', ticketData, filters: {'id': ticket.id});
      
      await SupabaseService.delete('maintenance_costs', filters: {'ticket_id': ticket.id});
      for (final cost in ticket.costs) {
        final costData = cost.toJson();
        await SupabaseService.insert('maintenance_costs', costData);
      }
      
      final index = _tickets.indexWhere((t) => t.id == ticket.id);
      if (index != -1) {
        _tickets[index] = ticket;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating ticket: $e');
      rethrow;
    }
  }

  // Audit logging
  Future<void> _logAudit(String action, String entityType, String entityId, {Map<String, dynamic>? metadata}) async {
    if (currentOrgId == null) return;
    
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      final logData = {
        'id': _uuid.v4(),
        'org_id': currentOrgId,
        'actor_user_id': userId,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'metadata_json': metadata,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      await SupabaseService.insert('audit_logs', logData);
    } catch (e) {
      debugPrint('Error logging audit: $e');
      // Don't rethrow - audit logging shouldn't break the main operation
    }
  }

  /// Load audit logs (for admin view)
  Future<void> loadAuditLogs() async {
    if (currentOrgId == null) return;
    
    try {
      final logsData = await SupabaseService.select(
        'audit_logs',
        filters: {'org_id': currentOrgId},
        orderBy: 'created_at',
        ascending: false,
        limit: 100,
      );
      _auditLogs = logsData.map((l) => AuditLog.fromJson(l)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading audit logs: $e');
    }
  }

  // Dashboard metrics
  double get totalExpectedRent {
    return _leases.where((l) => l.status == LeaseStatus.active).fold(0.0, (sum, l) => sum + l.rentAmount);
  }

  double get totalCollected {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _payments.where((p) => p.paidAt.isAfter(startOfMonth)).fold(0.0, (sum, p) => sum + p.amount);
  }

  double get totalArrears {
    return _invoices.where((i) => i.status == InvoiceStatus.open).fold(0.0, (sum, i) => sum + i.balanceAmount);
  }

  double get occupancyRate {
    if (_units.isEmpty) return 0;
    final occupied = _units.where((u) => u.status == UnitStatus.occupied).length;
    return (occupied / _units.length) * 100;
  }

  int get openTicketsCount => _tickets.where((t) => t.status != TicketStatus.approved && t.status != TicketStatus.rejected).length;

  /// Clear all data (on logout or org switch)
  void clear() {
    _properties = [];
    _units = [];
    _tenants = [];
    _leases = [];
    _invoices = [];
    _payments = [];
    _tickets = [];
    _auditLogs = [];
    _isInitialized = false;
    notifyListeners();
  }
}
