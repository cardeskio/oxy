import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oxy/models/property.dart';
import 'package:oxy/models/unit.dart';
import 'package:oxy/models/tenant.dart';
import 'package:oxy/models/lease.dart';
import 'package:oxy/models/invoice.dart';
import 'package:oxy/models/payment.dart';
import 'package:oxy/models/maintenance_ticket.dart';
import 'package:oxy/models/audit_log.dart';
import 'package:oxy/models/ticket_comment.dart';
import 'package:oxy/models/unit_charge.dart';
import 'package:oxy/models/charge_type.dart';
import 'package:oxy/models/property_enquiry.dart';
import 'package:oxy/supabase/supabase_config.dart';
import 'package:oxy/services/org_service.dart';

const _uuid = Uuid();

class DataService extends ChangeNotifier {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final OrgService _orgService = OrgService();
  final List<RealtimeChannel> _subscriptions = [];

  List<Property> _properties = [];
  List<Unit> _units = [];
  List<Tenant> _tenants = [];
  List<Lease> _leases = [];
  List<Invoice> _invoices = [];
  List<Payment> _payments = [];
  List<MaintenanceTicket> _tickets = [];
  List<AuditLog> _auditLogs = [];
  List<UnitCharge> _unitCharges = [];
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
  List<UnitCharge> get unitCharges => _unitCharges;
  bool get isLoading => _isLoading;
  
  String? get currentOrgId => _orgService.currentOrgId;

  Future<void> initialize() async {
    if (_isInitialized && currentOrgId != null) return;
    
    // If no org selected, just mark as not loading (empty state)
    if (currentOrgId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    try {
        await _loadFromSupabase();
      _setupRealtimeSubscriptions();
        _isInitialized = true;
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
      _setupRealtimeSubscriptions();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize DataService for org: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set up realtime subscriptions for instant updates
  void _setupRealtimeSubscriptions() {
    _cancelSubscriptions();
    
    final orgId = currentOrgId;
    if (orgId == null) return;

    // Subscribe to maintenance_tickets changes
    final ticketsChannel = SupabaseConfig.client
        .channel('tickets_$orgId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'maintenance_tickets',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'org_id',
            value: orgId,
          ),
          callback: (payload) => _handleTicketChange(payload),
        )
        .subscribe();
    _subscriptions.add(ticketsChannel);

    // Subscribe to leases changes
    final leasesChannel = SupabaseConfig.client
        .channel('leases_$orgId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'leases',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'org_id',
            value: orgId,
          ),
          callback: (payload) => _handleLeaseChange(payload),
        )
        .subscribe();
    _subscriptions.add(leasesChannel);

    // Subscribe to units changes
    final unitsChannel = SupabaseConfig.client
        .channel('units_$orgId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'units',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'org_id',
            value: orgId,
          ),
          callback: (payload) => _handleUnitChange(payload),
        )
        .subscribe();
    _subscriptions.add(unitsChannel);

    // Subscribe to tenants changes
    final tenantsChannel = SupabaseConfig.client
        .channel('tenants_$orgId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tenants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'org_id',
            value: orgId,
          ),
          callback: (payload) => _handleTenantChange(payload),
        )
        .subscribe();
    _subscriptions.add(tenantsChannel);

    // Subscribe to invoices changes
    final invoicesChannel = SupabaseConfig.client
        .channel('invoices_$orgId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invoices',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'org_id',
            value: orgId,
          ),
          callback: (payload) => _handleInvoiceChange(payload),
        )
        .subscribe();
    _subscriptions.add(invoicesChannel);

    // Subscribe to payments changes
    final paymentsChannel = SupabaseConfig.client
        .channel('payments_$orgId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'payments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'org_id',
            value: orgId,
          ),
          callback: (payload) => _handlePaymentChange(payload),
        )
        .subscribe();
    _subscriptions.add(paymentsChannel);

    debugPrint('Realtime subscriptions set up for org $orgId');
  }

  void _cancelSubscriptions() {
    for (final channel in _subscriptions) {
      SupabaseConfig.client.removeChannel(channel);
    }
    _subscriptions.clear();
  }

  void _handleTicketChange(PostgresChangePayload payload) {
    debugPrint('Ticket change: ${payload.eventType}');
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        final ticket = MaintenanceTicket.fromJson(payload.newRecord);
        if (!_tickets.any((t) => t.id == ticket.id)) {
          _tickets.insert(0, ticket);
        }
        break;
      case PostgresChangeEvent.update:
        final ticket = MaintenanceTicket.fromJson(payload.newRecord);
        final index = _tickets.indexWhere((t) => t.id == ticket.id);
        if (index != -1) {
          _tickets[index] = ticket;
        }
        break;
      case PostgresChangeEvent.delete:
        final id = payload.oldRecord['id'] as String?;
        if (id != null) {
          _tickets.removeWhere((t) => t.id == id);
        }
        break;
      default:
        break;
    }
    notifyListeners();
  }

  void _handleLeaseChange(PostgresChangePayload payload) {
    debugPrint('Lease change: ${payload.eventType}');
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        final lease = Lease.fromJson(payload.newRecord);
        if (!_leases.any((l) => l.id == lease.id)) {
          _leases.insert(0, lease);
        }
        break;
      case PostgresChangeEvent.update:
        final lease = Lease.fromJson(payload.newRecord);
        final index = _leases.indexWhere((l) => l.id == lease.id);
        if (index != -1) {
          _leases[index] = lease;
        }
        break;
      case PostgresChangeEvent.delete:
        final id = payload.oldRecord['id'] as String?;
        if (id != null) {
          _leases.removeWhere((l) => l.id == id);
        }
        break;
      default:
        break;
    }
    notifyListeners();
  }

  void _handleUnitChange(PostgresChangePayload payload) {
    debugPrint('Unit change: ${payload.eventType}');
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        final unit = Unit.fromJson(payload.newRecord);
        // Only add if not already present (might have been added manually)
        if (!_units.any((u) => u.id == unit.id)) {
          _units.add(unit);
        }
        break;
      case PostgresChangeEvent.update:
        final unit = Unit.fromJson(payload.newRecord);
        final index = _units.indexWhere((u) => u.id == unit.id);
        if (index != -1) {
          _units[index] = unit;
        } else {
          // Unit was updated but not in our list, add it
          _units.add(unit);
        }
        break;
      case PostgresChangeEvent.delete:
        final id = payload.oldRecord['id'] as String?;
        if (id != null) {
          _units.removeWhere((u) => u.id == id);
        }
        break;
      default:
        break;
    }
    notifyListeners();
  }

  void _handleTenantChange(PostgresChangePayload payload) {
    debugPrint('Tenant change: ${payload.eventType}');
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        final tenant = Tenant.fromJson(payload.newRecord);
        if (!_tenants.any((t) => t.id == tenant.id)) {
          _tenants.add(tenant);
        }
        break;
      case PostgresChangeEvent.update:
        final tenant = Tenant.fromJson(payload.newRecord);
        final index = _tenants.indexWhere((t) => t.id == tenant.id);
        if (index != -1) {
          _tenants[index] = tenant;
        }
        break;
      case PostgresChangeEvent.delete:
        final id = payload.oldRecord['id'] as String?;
        if (id != null) {
          _tenants.removeWhere((t) => t.id == id);
        }
        break;
      default:
        break;
    }
    notifyListeners();
  }

  void _handleInvoiceChange(PostgresChangePayload payload) {
    debugPrint('Invoice change: ${payload.eventType}');
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        final invoice = Invoice.fromJson(payload.newRecord);
        if (!_invoices.any((i) => i.id == invoice.id)) {
          _invoices.insert(0, invoice);
        }
        break;
      case PostgresChangeEvent.update:
        final invoice = Invoice.fromJson(payload.newRecord);
        final index = _invoices.indexWhere((i) => i.id == invoice.id);
        if (index != -1) {
          _invoices[index] = invoice;
        }
        break;
      case PostgresChangeEvent.delete:
        final id = payload.oldRecord['id'] as String?;
        if (id != null) {
          _invoices.removeWhere((i) => i.id == id);
        }
        break;
      default:
        break;
    }
    notifyListeners();
  }

  void _handlePaymentChange(PostgresChangePayload payload) {
    debugPrint('Payment change: ${payload.eventType}');
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        final payment = Payment.fromJson(payload.newRecord);
        if (!_payments.any((p) => p.id == payment.id)) {
          _payments.insert(0, payment);
        }
        break;
      case PostgresChangeEvent.update:
        final payment = Payment.fromJson(payload.newRecord);
        final index = _payments.indexWhere((p) => p.id == payment.id);
        if (index != -1) {
          _payments[index] = payment;
        }
        break;
      case PostgresChangeEvent.delete:
        final id = payload.oldRecord['id'] as String?;
        if (id != null) {
          _payments.removeWhere((p) => p.id == id);
        }
        break;
      default:
        break;
    }
    notifyListeners();
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

      // Load unit charges
      final unitChargesData = await SupabaseConfig.client
          .from('unit_charges')
          .select('*, charge_types(name), units(unit_label)')
          .eq('org_id', orgId);
      _unitCharges = unitChargesData.map((e) => UnitCharge.fromJson(e)).toList();

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

  /// Upload multiple images for a property
  Future<List<PropertyImage>> uploadPropertyImages(String propertyId, List<String> filePaths) async {
    if (currentOrgId == null) return [];
    
    final uploadedImages = <PropertyImage>[];
    
    for (final filePath in filePaths) {
      try {
        final file = await _readFileAsBytes(filePath);
        if (file == null) continue;
        
        final extension = filePath.split('.').last;
        final storagePath = '$currentOrgId/properties/$propertyId/${_uuid.v4()}.$extension';
        
        await SupabaseConfig.client.storage
            .from('property-images')
            .uploadBinary(storagePath, file, fileOptions: const FileOptions(contentType: 'image/jpeg'));
        
        final url = SupabaseConfig.client.storage
            .from('property-images')
            .getPublicUrl(storagePath);
        
        uploadedImages.add(PropertyImage(
          url: url,
          addedAt: DateTime.now(),
        ));
      } catch (e) {
        debugPrint('Error uploading property image: $e');
      }
    }
    
    if (uploadedImages.isNotEmpty) {
      final property = _properties.firstWhere((p) => p.id == propertyId);
      final updatedImages = [...property.images, ...uploadedImages];
      await updateProperty(property.copyWith(images: updatedImages));
    }
    
    return uploadedImages;
  }

  /// Remove image from property
  Future<void> removePropertyImage(String propertyId, String imageUrl) async {
    try {
      final property = _properties.firstWhere((p) => p.id == propertyId);
      final updatedImages = property.images.where((i) => i.url != imageUrl).toList();
      await updateProperty(property.copyWith(images: updatedImages));
      
      // Delete from storage
      final path = imageUrl.split('/property-images/').last;
      await SupabaseConfig.client.storage.from('property-images').remove([path]);
    } catch (e) {
      debugPrint('Error removing property image: $e');
    }
  }

  /// Upload multiple images for a unit
  Future<List<PropertyImage>> uploadUnitImages(String unitId, List<String> filePaths) async {
    if (currentOrgId == null) return [];
    
    final uploadedImages = <PropertyImage>[];
    final unit = _units.firstWhere((u) => u.id == unitId);
    
    for (final filePath in filePaths) {
      try {
        final file = await _readFileAsBytes(filePath);
        if (file == null) continue;
        
        final extension = filePath.split('.').last;
        final storagePath = '$currentOrgId/units/${unit.propertyId}/$unitId/${_uuid.v4()}.$extension';
        
        await SupabaseConfig.client.storage
            .from('property-images')
            .uploadBinary(storagePath, file, fileOptions: const FileOptions(contentType: 'image/jpeg'));
        
        final url = SupabaseConfig.client.storage
            .from('property-images')
            .getPublicUrl(storagePath);
        
        uploadedImages.add(PropertyImage(
          url: url,
          addedAt: DateTime.now(),
        ));
      } catch (e) {
        debugPrint('Error uploading unit image: $e');
      }
    }
    
    if (uploadedImages.isNotEmpty) {
      final updatedImages = [...unit.images, ...uploadedImages];
      await updateUnit(unit.copyWith(images: updatedImages));
    }
    
    return uploadedImages;
  }

  /// Remove image from unit
  Future<void> removeUnitImage(String unitId, String imageUrl) async {
    try {
      final unit = _units.firstWhere((u) => u.id == unitId);
      final updatedImages = unit.images.where((i) => i.url != imageUrl).toList();
      await updateUnit(unit.copyWith(images: updatedImages));
      
      // Delete from storage
      final path = imageUrl.split('/property-images/').last;
      await SupabaseConfig.client.storage.from('property-images').remove([path]);
    } catch (e) {
      debugPrint('Error removing unit image: $e');
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
        'created_at': DateTime.now().toUtc().toIso8601String(),
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

  int get openTicketsCount => _tickets.where((t) => 
    t.status == TicketStatus.new_ || 
    t.status == TicketStatus.assigned || 
    t.status == TicketStatus.inProgress
  ).length;

  // ============ UNIT CHARGES MANAGEMENT ============

  /// Get charge summaries for all occupied units (for bulk invoicing)
  List<UnitChargeSummary> getUnitChargeSummaries({String? propertyId}) {
    final chargeTypes = _orgService.chargeTypes.where((c) => c.isRecurring).toList();
    final summaries = <UnitChargeSummary>[];

    // Get occupied units with active leases
    final activeLeases = _leases.where((l) => l.status == LeaseStatus.active).toList();
    
    for (final lease in activeLeases) {
      final unit = _units.firstWhere((u) => u.id == lease.unitId, orElse: () => _units.first);
      final property = _properties.firstWhere((p) => p.id == lease.propertyId, orElse: () => _properties.first);
      final tenant = _tenants.cast<Tenant?>().firstWhere((t) => t?.id == lease.tenantId, orElse: () => null);
      
      if (propertyId != null && property.id != propertyId) continue;
      
      // Build charge entries
      final charges = <String, UnitChargeEntry>{};
      for (final chargeType in chargeTypes) {
        if (chargeType.name.toLowerCase() == 'rent') continue; // Rent handled separately
        
        // Check for unit-specific override
        final unitCharge = _unitCharges.cast<UnitCharge?>().firstWhere(
          (uc) => uc?.unitId == unit.id && uc?.chargeTypeId == chargeType.id,
          orElse: () => null,
        );
        
        charges[chargeType.id] = UnitChargeEntry(
          unitChargeId: unitCharge?.id,
          chargeTypeId: chargeType.id,
          chargeTypeName: chargeType.name,
          amount: unitCharge?.amount ?? chargeType.defaultAmount ?? 0,
          defaultAmount: chargeType.defaultAmount ?? 0,
          isEnabled: unitCharge?.isEnabled ?? true,
        );
      }
      
      summaries.add(UnitChargeSummary(
        unitId: unit.id,
        unitLabel: unit.unitLabel,
        propertyId: property.id,
        propertyName: property.name,
        tenantId: tenant?.id,
        tenantName: tenant?.fullName,
        rentAmount: lease.rentAmount,
        charges: charges,
      ));
    }
    
    // Sort by property then unit
    summaries.sort((a, b) {
      final propCompare = a.propertyName.compareTo(b.propertyName);
      if (propCompare != 0) return propCompare;
      return a.unitLabel.compareTo(b.unitLabel);
    });
    
    return summaries;
  }

  /// Update or create a unit charge
  Future<void> upsertUnitCharge({
    required String unitId,
    required String chargeTypeId,
    required double amount,
    bool isEnabled = true,
  }) async {
    if (currentOrgId == null) return;
    
    try {
      final now = DateTime.now().toUtc();
      final existing = _unitCharges.cast<UnitCharge?>().firstWhere(
        (uc) => uc?.unitId == unitId && uc?.chargeTypeId == chargeTypeId,
        orElse: () => null,
      );
      
      if (existing != null) {
        // Update existing
        await SupabaseConfig.client
            .from('unit_charges')
            .update({
              'amount': amount,
              'is_enabled': isEnabled,
              'updated_at': now.toIso8601String(),
            })
            .eq('id', existing.id);
        
        final index = _unitCharges.indexWhere((uc) => uc.id == existing.id);
        if (index != -1) {
          _unitCharges[index] = existing.copyWith(
            amount: amount,
            isEnabled: isEnabled,
            updatedAt: now,
          );
        }
      } else {
        // Create new
        final data = {
          'id': _uuid.v4(),
          'org_id': currentOrgId,
          'unit_id': unitId,
          'charge_type_id': chargeTypeId,
          'amount': amount,
          'is_enabled': isEnabled,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };
        
        final result = await SupabaseConfig.client
            .from('unit_charges')
            .insert(data)
            .select()
            .single();
        
        _unitCharges.add(UnitCharge.fromJson(result));
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error upserting unit charge: $e');
      rethrow;
    }
  }

  /// Generate bulk invoices for all tenants with active leases
  Future<List<Invoice>> generateBulkInvoices({
    required DateTime dueDate,
    String? propertyId,
    String? period,
  }) async {
    if (currentOrgId == null) return [];
    
    final summaries = getUnitChargeSummaries(propertyId: propertyId);
    final invoices = <Invoice>[];
    final now = DateTime.now().toUtc();
    final periodLabel = period ?? '${dueDate.month}/${dueDate.year}';
    
    // Calculate period dates (first to last day of the month)
    final periodStart = DateTime(dueDate.year, dueDate.month, 1);
    final periodEnd = DateTime(dueDate.year, dueDate.month + 1, 0);
    
    for (final summary in summaries) {
      if (summary.tenantId == null) continue;
      
      // Get the lease for this tenant
      final lease = _leases.cast<Lease?>().firstWhere(
        (l) => l?.tenantId == summary.tenantId && l?.status == LeaseStatus.active,
        orElse: () => null,
      );
      if (lease == null) continue;
      
      try {
        // Create invoice
        final invoiceId = _uuid.v4();
        final lines = <InvoiceLine>[];
        var totalAmount = 0.0;
        
        // Add rent
        if (summary.rentAmount > 0) {
          final rentChargeType = _orgService.chargeTypes.cast<ChargeType?>().firstWhere(
            (c) => c?.name.toLowerCase() == 'rent',
            orElse: () => null,
          );
          
          lines.add(InvoiceLine(
            id: _uuid.v4(),
            orgId: currentOrgId!,
            invoiceId: invoiceId,
            chargeTypeId: rentChargeType?.id,
            chargeType: 'Rent',
            description: 'Rent - $periodLabel',
            amount: summary.rentAmount,
            balanceAmount: summary.rentAmount,
          ));
          totalAmount += summary.rentAmount;
        }
        
        // Add other charges
        for (final entry in summary.charges.values) {
          if (!entry.isEnabled || entry.amount <= 0) continue;
          
          lines.add(InvoiceLine(
            id: _uuid.v4(),
            orgId: currentOrgId!,
            invoiceId: invoiceId,
            chargeTypeId: entry.chargeTypeId,
            chargeType: entry.chargeTypeName,
            description: '${entry.chargeTypeName} - $periodLabel',
            amount: entry.amount,
            balanceAmount: entry.amount,
          ));
          totalAmount += entry.amount;
        }
        
        if (lines.isEmpty) continue;
        
        // Insert invoice
        final invoiceData = {
          'id': invoiceId,
          'org_id': currentOrgId,
          'lease_id': lease.id,
          'tenant_id': summary.tenantId,
          'property_id': summary.propertyId,
          'unit_id': summary.unitId,
          'period_start': periodStart.toIso8601String(),
          'period_end': periodEnd.toIso8601String(),
          'status': 'open',
          'due_date': dueDate.toIso8601String(),
          'total_amount': totalAmount,
          'balance_amount': totalAmount,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };
        
        await SupabaseConfig.client
            .from('invoices')
            .insert(invoiceData);
        
        // Insert invoice lines
        for (final line in lines) {
          await SupabaseConfig.client
              .from('invoice_lines')
              .insert(line.toJson());
        }
        
        final invoice = Invoice(
          id: invoiceId,
          orgId: currentOrgId!,
          leaseId: lease.id,
          tenantId: summary.tenantId!,
          propertyId: summary.propertyId,
          unitId: summary.unitId,
          periodStart: periodStart,
          periodEnd: periodEnd,
          status: InvoiceStatus.open,
          dueDate: dueDate,
          totalAmount: totalAmount,
          balanceAmount: totalAmount,
          lines: lines,
          createdAt: now,
          updatedAt: now,
        );
        
        _invoices.insert(0, invoice);
        invoices.add(invoice);
        
      } catch (e) {
        debugPrint('Error generating invoice for ${summary.unitLabel}: $e');
      }
    }
    
    notifyListeners();
    return invoices;
  }

  // ============ TICKET COMMENTS ============

  /// Load comments for a ticket
  Future<List<TicketComment>> loadTicketComments(String ticketId) async {
    try {
      final data = await SupabaseConfig.client
          .from('ticket_comments')
          .select()
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);
      
      // Fetch profile info for each unique user
      final userIds = (data as List).map((c) => c['user_id'] as String).toSet();
      final profiles = <String, Map<String, dynamic>>{};
      
      if (userIds.isNotEmpty) {
        final profileData = await SupabaseConfig.client
            .from('profiles')
            .select('id, full_name, email, avatar_url')
            .inFilter('id', userIds.toList());
        
        for (final p in profileData) {
          profiles[p['id'] as String] = p;
        }
      }
      
      final comments = data.map((c) {
        final userId = c['user_id'] as String;
        final profile = profiles[userId];
        final isManager = _orgService.orgMembers.any((m) => m.userId == userId);
        return TicketComment.fromJson({
          ...c,
          'profiles': profile,
          'is_manager': isManager,
        });
      }).toList();
      
      return comments;
    } catch (e) {
      debugPrint('Error loading ticket comments: $e');
      return [];
    }
  }

  /// Add a comment to a ticket
  Future<TicketComment?> addTicketComment({
    required String ticketId,
    required String content,
    List<TicketAttachment> attachments = const [],
    bool isInternal = false,
  }) async {
    if (currentOrgId == null) return null;
    
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return null;
    
    try {
      final now = DateTime.now().toUtc();
      final commentData = {
        'id': _uuid.v4(),
        'ticket_id': ticketId,
        'user_id': userId,
        'org_id': currentOrgId,
        'content': content,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'is_internal': isInternal,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      
      final result = await SupabaseConfig.client
          .from('ticket_comments')
          .insert(commentData)
          .select()
          .single();
      
      // Get current user's profile
      final profileData = await SupabaseConfig.client
          .from('profiles')
          .select('id, full_name, email, avatar_url')
          .eq('id', userId)
          .maybeSingle();
      
      return TicketComment.fromJson({
        ...result,
        'profiles': profileData,
        'is_manager': true,
      });
    } catch (e) {
      debugPrint('Error adding ticket comment: $e');
      return null;
    }
  }

  /// Upload attachment for ticket comment
  Future<TicketAttachment?> uploadTicketAttachment(String ticketId, String filePath, String fileName, String mimeType) async {
    if (currentOrgId == null) return null;
    
    try {
      final file = await _readFileAsBytes(filePath);
      if (file == null) return null;
      
      final extension = fileName.split('.').last;
      final storagePath = '$currentOrgId/$ticketId/${_uuid.v4()}.$extension';
      
      await SupabaseConfig.client.storage
          .from('ticket-attachments')
          .uploadBinary(storagePath, file, fileOptions: FileOptions(contentType: mimeType));
      
      final url = SupabaseConfig.client.storage
          .from('ticket-attachments')
          .getPublicUrl(storagePath);
      
      final type = mimeType.startsWith('video/') ? 'video' : 'image';
      
      return TicketAttachment(
        url: url,
        name: fileName,
        type: type,
        size: file.length,
      );
    } catch (e) {
      debugPrint('Error uploading attachment: $e');
      return null;
    }
  }

  Future<Uint8List?> _readFileAsBytes(String path) async {
    try {
      final file = await File(path).readAsBytes();
      return file;
    } catch (e) {
      debugPrint('Error reading file: $e');
      return null;
    }
  }

  // ============ PROPERTY ENQUIRIES (MANAGER) ============

  List<PropertyEnquiry> _enquiries = [];
  List<PropertyEnquiry> get enquiries => _enquiries;
  
  int get pendingEnquiriesCount => _enquiries.where((e) => e.status == EnquiryStatus.pending).length;

  /// Load all enquiries for the current org
  Future<void> loadEnquiries() async {
    if (currentOrgId == null) return;
    
    try {
      final data = await SupabaseConfig.client
          .from('property_enquiries')
          .select('''
            *,
            properties!property_enquiries_property_id_fkey(name),
            units!property_enquiries_unit_id_fkey(unit_label)
          ''')
          .eq('org_id', currentOrgId!)
          .order('created_at', ascending: false);
      
      _enquiries = (data as List).map((e) {
        return PropertyEnquiry.fromJson({
          ...e,
          'property_name': e['properties']?['name'],
          'unit_label': e['units']?['unit_label'],
        });
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading enquiries: $e');
    }
  }

  /// Update enquiry status
  Future<void> updateEnquiryStatus(String enquiryId, EnquiryStatus status, {String? notes, DateTime? scheduledDate}) async {
    try {
      final updateData = <String, dynamic>{
        'status': PropertyEnquiry.statusToDb(status),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      
      if (notes != null) updateData['manager_notes'] = notes;
      if (scheduledDate != null) updateData['scheduled_date'] = scheduledDate.toUtc().toIso8601String();
      
      await SupabaseConfig.client
          .from('property_enquiries')
          .update(updateData)
          .eq('id', enquiryId);
      
      final index = _enquiries.indexWhere((e) => e.id == enquiryId);
      if (index != -1) {
        _enquiries[index] = _enquiries[index].copyWith(
          status: status,
          managerNotes: notes ?? _enquiries[index].managerNotes,
          scheduledDate: scheduledDate ?? _enquiries[index].scheduledDate,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating enquiry: $e');
      rethrow;
    }
  }

  /// Toggle property listing visibility
  Future<void> togglePropertyListing(String propertyId, bool isListed, {String? description}) async {
    final property = _properties.firstWhere((p) => p.id == propertyId);
    await updateProperty(property.copyWith(
      isListed: isListed,
      listingDescription: description ?? property.listingDescription,
      updatedAt: DateTime.now(),
    ));
  }

  /// Toggle unit listing visibility
  Future<void> toggleUnitListing(String unitId, bool isListed, {String? description, List<String>? amenities}) async {
    final unit = _units.firstWhere((u) => u.id == unitId);
    await updateUnit(unit.copyWith(
      isListed: isListed,
      listingDescription: description ?? unit.listingDescription,
      amenities: amenities ?? unit.amenities,
      updatedAt: DateTime.now(),
    ));
  }

  /// Load comments for an enquiry
  Future<List<EnquiryComment>> loadEnquiryComments(String enquiryId) async {
    try {
      final data = await SupabaseConfig.client
          .from('enquiry_comments')
          .select()
          .eq('enquiry_id', enquiryId)
          .order('created_at', ascending: true);
      
      // Load profile info for each comment
      final comments = <EnquiryComment>[];
      for (final c in data as List) {
        String? userName;
        String? userEmail;
        try {
          final profile = await SupabaseConfig.client
              .from('profiles')
              .select('full_name, email')
              .eq('id', c['user_id'])
              .maybeSingle();
          if (profile != null) {
            userName = profile['full_name'] as String?;
            userEmail = profile['email'] as String?;
          }
        } catch (_) {}
        
        comments.add(EnquiryComment.fromJson({
          ...c,
          'user_name': userName,
          'user_email': userEmail,
        }));
      }
      return comments;
    } catch (e) {
      debugPrint('Error loading enquiry comments: $e');
      return [];
    }
  }

  /// Add a comment to an enquiry (as manager)
  Future<EnquiryComment?> addEnquiryComment({
    required String enquiryId,
    required String content,
  }) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    if (currentOrgId == null) throw Exception('No organization selected');
    
    try {
      final now = DateTime.now().toUtc();
      final commentData = {
        'id': const Uuid().v4(),
        'enquiry_id': enquiryId,
        'user_id': userId,
        'org_id': currentOrgId,
        'content': content,
        'is_from_manager': true,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      
      final result = await SupabaseConfig.client
          .from('enquiry_comments')
          .insert(commentData)
          .select()
          .single();
      
      return EnquiryComment.fromJson(result);
    } catch (e) {
      debugPrint('Error adding enquiry comment: $e');
      rethrow;
    }
  }

  /// Get enquiry by ID
  PropertyEnquiry? getEnquiryById(String id) {
    try {
      return _enquiries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Clear all data (on logout or org switch)
  void clear() {
    _cancelSubscriptions();
    _properties = [];
    _units = [];
    _tenants = [];
    _leases = [];
    _invoices = [];
    _payments = [];
    _tickets = [];
    _auditLogs = [];
    _unitCharges = [];
    _enquiries = [];
    _isInitialized = false;
    notifyListeners();
  }
}
