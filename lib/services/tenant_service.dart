import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oxy/models/tenant.dart';
import 'package:oxy/models/lease.dart';
import 'package:oxy/models/move_out_request.dart';
import 'package:oxy/models/property.dart';
import 'package:oxy/models/unit.dart';
import 'package:oxy/models/invoice.dart';
import 'package:oxy/models/payment.dart';
import 'package:oxy/models/maintenance_ticket.dart';
import 'package:oxy/models/ticket_comment.dart';
import 'package:oxy/models/property_enquiry.dart';
import 'package:oxy/supabase/supabase_config.dart';
import 'package:oxy/services/auth_service.dart';

/// Service for tenant self-service operations
class TenantService extends ChangeNotifier {
  static final TenantService _instance = TenantService._internal();
  factory TenantService() => _instance;
  TenantService._internal();

  final AuthService _authService = AuthService();
  final List<RealtimeChannel> _subscriptions = [];

  List<TenantLink> _tenantLinks = [];
  TenantLink? _currentLink;
  Tenant? _currentTenant;
  Lease? _activeLease;
  Property? _property;
  Unit? _unit;
  List<Invoice> _invoices = [];
  List<Payment> _payments = [];
  List<MaintenanceTicket> _tickets = [];
  List<MoveOutRequest> _moveOutRequests = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  List<TenantLink> get tenantLinks => _tenantLinks;
  TenantLink? get currentLink => _currentLink;
  Tenant? get currentTenant => _currentTenant;
  Lease? get activeLease => _activeLease;
  Property? get property => _property;
  Unit? get unit => _unit;
  List<Invoice> get invoices => _invoices;
  List<Payment> get payments => _payments;
  List<MaintenanceTicket> get tickets => _tickets;
  List<MoveOutRequest> get moveOutRequests => _moveOutRequests;
  bool get isLoading => _isLoading;
  bool get hasMultipleLinks => _tenantLinks.length > 1;
  String? get currentOrgId => _currentLink?.orgId;
  
  double get totalBalance => _invoices
      .where((i) => i.status == InvoiceStatus.open)
      .fold(0.0, (sum, i) => sum + i.balanceAmount);
  
  List<Invoice> get openInvoices => _invoices.where((i) => i.status == InvoiceStatus.open).toList();

  /// Check if user has any tenant links (is assigned to a property)
  bool get hasUnit => _tenantLinks.isNotEmpty;

  /// Initialize tenant service - load all tenant links for the current user
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        _isInitialized = true;
        return;
      }

      // Load tenant links with org info
      final linksData = await SupabaseConfig.client
          .from('tenant_user_links')
          .select('*, orgs!tenant_user_links_org_id_fkey(id, name)')
          .eq('user_id', userId);

      _tenantLinks = linksData.map((l) => TenantLink.fromJson(l)).toList();

      // Select the first link by default if not already selected
      if (_tenantLinks.isNotEmpty && _currentLink == null) {
        await selectTenantLink(_tenantLinks.first.id);
      }
      
      // Ensure user has a claim code if they don't have any tenant links
      // This is for users who signed up but haven't been linked to a property yet
      if (_tenantLinks.isEmpty && _authService.claimCode == null) {
        await _authService.generateClaimCode();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing TenantService: $e');
      _isInitialized = true; // Mark as initialized even on error to prevent loops
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Switch to a different tenant link (for multi-org tenants)
  Future<void> selectTenantLink(String linkId) async {
    final link = _tenantLinks.cast<TenantLink?>().firstWhere(
      (l) => l?.id == linkId,
      orElse: () => null,
    );
    
    if (link == null) return;

    _currentLink = link;
    _isLoading = true;
    notifyListeners();
    
    try {
      // Load the tenant record
      final tenantData = await SupabaseConfig.client
          .from('tenants')
          .select()
          .eq('id', link.tenantId)
          .single();
      
      _currentTenant = Tenant.fromJson(tenantData);

      // Load active lease
      final leaseData = await SupabaseConfig.client
          .from('leases')
          .select()
          .eq('tenant_id', link.tenantId)
          .eq('status', 'active')
          .maybeSingle();
      
      _activeLease = leaseData != null ? Lease.fromJson(leaseData) : null;
      
      // Load property and unit if we have an active lease
      if (_activeLease != null) {
        final propertyData = await SupabaseConfig.client
            .from('properties')
            .select()
            .eq('id', _activeLease!.propertyId)
            .single();
        _property = Property.fromJson(propertyData);
        
        final unitData = await SupabaseConfig.client
            .from('units')
            .select()
            .eq('id', _activeLease!.unitId)
            .single();
        _unit = Unit.fromJson(unitData);
      } else {
        _property = null;
        _unit = null;
      }
      
      // Load invoices for this tenant
      final invoicesData = await SupabaseConfig.client
          .from('invoices')
          .select()
          .eq('tenant_id', link.tenantId)
          .order('created_at', ascending: false);
      _invoices = invoicesData.map((i) => Invoice.fromJson(i)).toList();
      
      // Load payments for this tenant
      final paymentsData = await SupabaseConfig.client
          .from('payments')
          .select()
          .eq('tenant_id', link.tenantId)
          .order('paid_at', ascending: false);
      _payments = paymentsData.map((p) => Payment.fromJson(p)).toList();
      
      // Load maintenance tickets for the unit
      if (_unit != null) {
        final ticketsData = await SupabaseConfig.client
            .from('maintenance_tickets')
            .select()
            .eq('unit_id', _unit!.id)
            .order('created_at', ascending: false);
        _tickets = ticketsData.map((t) => MaintenanceTicket.fromJson(t)).toList();
      } else {
        _tickets = [];
      }

      // Load move-out requests
      await loadMoveOutRequests();
      
      // Set up realtime subscriptions
      _setupRealtimeSubscriptions();

    } catch (e) {
      debugPrint('Error selecting tenant link: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set up realtime subscriptions for tenant-side instant updates
  void _setupRealtimeSubscriptions() {
    _cancelSubscriptions();
    
    if (_currentLink == null || _unit == null) return;
    
    final tenantId = _currentLink!.tenantId;
    final unitId = _unit!.id;

    // Subscribe to maintenance_tickets changes for this unit
    final ticketsChannel = SupabaseConfig.client
        .channel('tenant_tickets_$unitId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'maintenance_tickets',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'unit_id',
            value: unitId,
          ),
          callback: (payload) => _handleTicketChange(payload),
        )
        .subscribe();
    _subscriptions.add(ticketsChannel);

    // Subscribe to invoices changes for this tenant
    final invoicesChannel = SupabaseConfig.client
        .channel('tenant_invoices_$tenantId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invoices',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tenant_id',
            value: tenantId,
          ),
          callback: (payload) => _handleInvoiceChange(payload),
        )
        .subscribe();
    _subscriptions.add(invoicesChannel);

    // Subscribe to lease changes for this tenant
    final leaseChannel = SupabaseConfig.client
        .channel('tenant_leases_$tenantId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'leases',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tenant_id',
            value: tenantId,
          ),
          callback: (payload) => _handleLeaseChange(payload),
        )
        .subscribe();
    _subscriptions.add(leaseChannel);

    debugPrint('Tenant realtime subscriptions set up for tenant $tenantId');
  }

  void _cancelSubscriptions() {
    for (final channel in _subscriptions) {
      SupabaseConfig.client.removeChannel(channel);
    }
    _subscriptions.clear();
  }

  void _handleTicketChange(PostgresChangePayload payload) {
    debugPrint('Tenant ticket change: ${payload.eventType}');
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        final ticket = MaintenanceTicket.fromJson(payload.newRecord);
        // Only add if not already present (might have been added manually)
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

  void _handleInvoiceChange(PostgresChangePayload payload) {
    debugPrint('Tenant invoice change: ${payload.eventType}');
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        final invoice = Invoice.fromJson(payload.newRecord);
        // Only add if not already present (might have been added manually)
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

  void _handleLeaseChange(PostgresChangePayload payload) {
    debugPrint('Tenant lease change: ${payload.eventType}');
    // For lease changes, reload to get the full context
    if (payload.eventType == PostgresChangeEvent.update) {
      final lease = Lease.fromJson(payload.newRecord);
      if (lease.tenantId == _currentTenant?.id) {
        _activeLease = lease;
        notifyListeners();
      }
    }
  }
  
  /// Refresh all data
  Future<void> refresh() async {
    if (_currentLink == null) return;
    await selectTenantLink(_currentLink!.id);
  }

  /// Update tenant's own profile
  Future<void> updateProfile({
    required String fullName,
    required String phone,
    String? nextOfKinName,
    String? nextOfKinPhone,
  }) async {
    if (_currentTenant == null) throw Exception('No tenant selected');

    final now = DateTime.now().toUtc();
    final updateData = {
      'full_name': fullName,
      'phone': phone,
      'next_of_kin_name': nextOfKinName,
      'next_of_kin_phone': nextOfKinPhone,
      'updated_at': now.toIso8601String(),
    };

    // Update tenants table
    await SupabaseConfig.client
        .from('tenants')
        .update(updateData)
        .eq('id', _currentTenant!.id);

    // Also update profiles table to keep in sync
    if (_currentTenant!.userId != null) {
      await SupabaseConfig.client
          .from('profiles')
          .update({
            'full_name': fullName,
            'phone': phone,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', _currentTenant!.userId!);
    }

    _currentTenant = _currentTenant!.copyWith(
      fullName: fullName,
      phone: phone,
      nextOfKinName: nextOfKinName,
      nextOfKinPhone: nextOfKinPhone,
      updatedAt: now,
    );

    notifyListeners();
  }

  /// Load move-out requests for current tenant
  Future<void> loadMoveOutRequests() async {
    if (_currentTenant == null) return;

    try {
      final data = await SupabaseConfig.client
          .from('move_out_requests')
          .select()
          .eq('tenant_id', _currentTenant!.id)
          .order('created_at', ascending: false);

      _moveOutRequests = data.map((r) => MoveOutRequest.fromJson(r)).toList();
    } catch (e) {
      debugPrint('Error loading move-out requests: $e');
      _moveOutRequests = [];
    }
  }

  /// Submit a move-out request
  Future<MoveOutRequest?> submitMoveOutRequest({
    required DateTime preferredDate,
    String? reason,
  }) async {
    if (_currentTenant == null || _activeLease == null) {
      throw Exception('No active lease found');
    }

    // Check if there's already a pending request
    final existingPending = _moveOutRequests.any((r) => r.status == MoveOutStatus.pending);
    if (existingPending) {
      throw Exception('You already have a pending move-out request');
    }

    final request = MoveOutRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tenantId: _currentTenant!.id,
      leaseId: _activeLease!.id,
      orgId: _currentLink!.orgId,
      requestedAt: DateTime.now(),
      preferredMoveOutDate: preferredDate,
      reason: reason,
      status: MoveOutStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final data = await SupabaseConfig.client
        .from('move_out_requests')
        .insert(request.toJson())
        .select()
        .single();

    final newRequest = MoveOutRequest.fromJson(data);
    _moveOutRequests.insert(0, newRequest);
    notifyListeners();

    return newRequest;
  }

  /// Cancel a pending move-out request
  Future<void> cancelMoveOutRequest(String requestId) async {
    await SupabaseConfig.client
        .from('move_out_requests')
        .update({
          'status': 'cancelled',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', requestId);

    final index = _moveOutRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _moveOutRequests[index] = _moveOutRequests[index].copyWith(
        status: MoveOutStatus.cancelled,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// Submit a maintenance ticket
  Future<MaintenanceTicket?> submitMaintenanceTicket({
    required String title,
    required String description,
    required TicketPriority priority,
  }) async {
    debugPrint('TenantService: submitMaintenanceTicket called');
    debugPrint('TenantService: currentTenant=$_currentTenant, unit=$_unit, currentLink=$_currentLink, activeLease=$_activeLease');
    
    if (_currentTenant == null || _unit == null || _currentLink == null || _activeLease == null) {
      debugPrint('TenantService: Missing required data for ticket submission');
      throw Exception('No active lease or unit found. Please ensure you are linked to a property.');
    }

    try {
      final now = DateTime.now().toUtc();
      final ticketId = const Uuid().v4();
      
      // Build insert data without 'costs' field (it's a related table, not a column)
      final insertData = {
        'id': ticketId,
        'org_id': _currentLink!.orgId,
        'property_id': _activeLease!.propertyId,
        'unit_id': _unit!.id,
        'tenant_id': _currentTenant!.id,
        'lease_id': _activeLease!.id,
        'title': title,
        'description': description,
        'priority': priority.name,
        'status': 'new',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      debugPrint('TenantService: Inserting ticket with data: $insertData');

      final data = await SupabaseConfig.client
          .from('maintenance_tickets')
          .insert(insertData)
          .select()
          .single();

      debugPrint('TenantService: Ticket created successfully: $data');

      final newTicket = MaintenanceTicket.fromJson(data);
      _tickets.insert(0, newTicket);
      notifyListeners();

      return newTicket;
    } catch (e) {
      debugPrint('TenantService: Error creating ticket: $e');
      rethrow;
    }
  }

  /// Clear state on logout
  void clear() {
    _cancelSubscriptions();
    _tenantLinks = [];
    _currentLink = null;
    _currentTenant = null;
    _activeLease = null;
    _property = null;
    _unit = null;
    _invoices = [];
    _payments = [];
    _tickets = [];
    _moveOutRequests = [];
    _isInitialized = false;
    notifyListeners();
  }

  // ============ TICKET COMMENTS ============

  /// Load comments for a ticket (non-internal only for tenants)
  Future<List<TicketComment>> loadTicketComments(String ticketId) async {
    try {
      debugPrint('TenantService: Loading comments for ticket $ticketId');
      final data = await SupabaseConfig.client
          .from('ticket_comments')
          .select()
          .eq('ticket_id', ticketId)
          .eq('is_internal', false)
          .order('created_at', ascending: true);
      
      debugPrint('TenantService: Got ${(data as List).length} comments from DB');
      
      // Fetch profile info for each unique user
      final userIds = data.map((c) => c['user_id'] as String).toSet();
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
      
      final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
      final comments = data.map((c) {
        final commentUserId = c['user_id'] as String;
        final profile = profiles[commentUserId];
        final isFromCurrentUser = commentUserId == currentUserId;
        return TicketComment.fromJson({
          ...c,
          'profiles': profile,
          'is_manager': !isFromCurrentUser,
        });
      }).toList();
      
      return comments;
    } catch (e) {
      debugPrint('Error loading ticket comments: $e');
      return [];
    }
  }

  /// Add a comment to a ticket (tenants can only add non-internal comments)
  Future<TicketComment?> addTicketComment({
    required String ticketId,
    required String content,
    List<TicketAttachment> attachments = const [],
  }) async {
    if (_currentLink == null) return null;
    
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return null;
    
    try {
      final now = DateTime.now().toUtc();
      final commentData = {
        'id': const Uuid().v4(),
        'ticket_id': ticketId,
        'user_id': userId,
        'org_id': _currentLink!.orgId,
        'content': content,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'is_internal': false,
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
        'is_manager': false,
      });
    } catch (e) {
      debugPrint('Error adding ticket comment: $e');
      return null;
    }
  }

  /// Upload attachment for ticket comment
  Future<TicketAttachment?> uploadTicketAttachment(String ticketId, String filePath, String fileName, String mimeType) async {
    if (_currentLink == null) return null;
    
    try {
      final file = await _readFileAsBytes(filePath);
      if (file == null) return null;
      
      final extension = fileName.split('.').last;
      final storagePath = '${_currentLink!.orgId}/$ticketId/${const Uuid().v4()}.$extension';
      
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

  // ============ EXPLORE / HOUSE HUNTING ============

  /// Load all listed properties for the explore page
  Future<List<ListedProperty>> loadListedProperties({String? locationFilter}) async {
    try {
      var query = SupabaseConfig.client
          .from('listed_properties')
          .select();
      
      // Apply location filter if provided
      if (locationFilter != null && locationFilter.isNotEmpty) {
        query = query.ilike('location_text', '%$locationFilter%');
      }
      
      final data = await query.order('created_at', ascending: false);
      
      return (data as List)
          .map((p) => ListedProperty.fromJson(p))
          .where((p) => p.availableUnits > 0) // Only show properties with available units
          .toList();
    } catch (e) {
      debugPrint('Error loading listed properties: $e');
      return [];
    }
  }

  /// Load listed units for a specific property
  Future<List<ListedUnit>> loadListedUnitsForProperty(String propertyId) async {
    try {
      final data = await SupabaseConfig.client
          .from('listed_units')
          .select()
          .eq('property_id', propertyId)
          .order('rent_amount', ascending: true);
      
      return (data as List).map((u) => ListedUnit.fromJson(u)).toList();
    } catch (e) {
      debugPrint('Error loading listed units: $e');
      return [];
    }
  }

  /// Load all listed units (for search/filter across all properties)
  Future<List<ListedUnit>> loadAllListedUnits({
    String? locationFilter,
    double? minRent,
    double? maxRent,
    String? propertyType,
  }) async {
    try {
      var query = SupabaseConfig.client
          .from('listed_units')
          .select();
      
      if (locationFilter != null && locationFilter.isNotEmpty) {
        query = query.ilike('property_location', '%$locationFilter%');
      }
      if (minRent != null) {
        query = query.gte('rent_amount', minRent);
      }
      if (maxRent != null) {
        query = query.lte('rent_amount', maxRent);
      }
      if (propertyType != null && propertyType.isNotEmpty) {
        query = query.eq('property_type', propertyType);
      }
      
      final data = await query.order('rent_amount', ascending: true);
      
      return (data as List).map((u) => ListedUnit.fromJson(u)).toList();
    } catch (e) {
      debugPrint('Error loading all listed units: $e');
      return [];
    }
  }

  /// Submit an enquiry for a property/unit
  Future<PropertyEnquiry?> submitEnquiry({
    required String orgId,
    required String propertyId,
    String? unitId,
    required EnquiryType enquiryType,
    required String contactName,
    required String contactPhone,
    String? contactEmail,
    String? message,
    DateTime? preferredDate,
  }) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    try {
      final now = DateTime.now().toUtc();
      final enquiryData = {
        'id': const Uuid().v4(),
        'org_id': orgId,
        'property_id': propertyId,
        'unit_id': unitId,
        'user_id': userId,
        'enquiry_type': EnquiryType.viewing == enquiryType ? 'viewing' 
            : enquiryType == EnquiryType.information ? 'information' : 'application',
        'status': 'pending',
        'contact_name': contactName,
        'contact_phone': contactPhone,
        'contact_email': contactEmail,
        'message': message,
        'preferred_date': preferredDate?.toUtc().toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      
      final result = await SupabaseConfig.client
          .from('property_enquiries')
          .insert(enquiryData)
          .select()
          .single();
      
      return PropertyEnquiry.fromJson(result);
    } catch (e) {
      debugPrint('Error submitting enquiry: $e');
      rethrow;
    }
  }

  /// Load user's own enquiries
  Future<List<PropertyEnquiry>> loadMyEnquiries() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return [];
    
    try {
      final data = await SupabaseConfig.client
          .from('property_enquiries')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      final enquiriesList = data as List;
      if (enquiriesList.isEmpty) return [];
      
      // Collect unique property and unit IDs
      final propertyIds = enquiriesList
          .map((e) => e['property_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      final unitIds = enquiriesList
          .map((e) => e['unit_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      
      // Batch fetch properties
      final propertiesMap = <String, String>{};
      if (propertyIds.isNotEmpty) {
        final properties = await SupabaseConfig.client
            .from('properties')
            .select('id, name')
            .inFilter('id', propertyIds);
        for (final p in properties as List) {
          propertiesMap[p['id'] as String] = p['name'] as String;
        }
      }
      
      // Batch fetch units
      final unitsMap = <String, String>{};
      if (unitIds.isNotEmpty) {
        final units = await SupabaseConfig.client
            .from('units')
            .select('id, unit_label')
            .inFilter('id', unitIds);
        for (final u in units as List) {
          unitsMap[u['id'] as String] = u['unit_label'] as String;
        }
      }
      
      // Build enquiries with joined data
      return enquiriesList.map((e) {
        return PropertyEnquiry.fromJson({
          ...e,
          'property_name': propertiesMap[e['property_id']],
          'unit_label': unitsMap[e['unit_id']],
        });
      }).toList();
    } catch (e) {
      debugPrint('Error loading my enquiries: $e');
      return [];
    }
  }

  /// Get unique locations from listed properties for filter
  Future<List<String>> getAvailableLocations() async {
    try {
      final data = await SupabaseConfig.client
          .from('listed_properties')
          .select('location_text');
      
      final locations = (data as List)
          .map((p) => p['location_text'] as String)
          .toSet()
          .toList()
        ..sort();
      
      return locations;
    } catch (e) {
      debugPrint('Error loading locations: $e');
      return [];
    }
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
        // Try to get profile info
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

  /// Add a comment to an enquiry
  Future<EnquiryComment?> addEnquiryComment({
    required String enquiryId,
    required String orgId,
    required String content,
  }) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    try {
      final now = DateTime.now().toUtc();
      final commentData = {
        'id': const Uuid().v4(),
        'enquiry_id': enquiryId,
        'user_id': userId,
        'org_id': orgId,
        'content': content,
        'is_from_manager': false,
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
}

/// Represents a link between a user and a tenant record
class TenantLink {
  final String id;
  final String userId;
  final String tenantId;
  final String orgId;
  final String? orgName;
  final DateTime createdAt;

  TenantLink({
    required this.id,
    required this.userId,
    required this.tenantId,
    required this.orgId,
    this.orgName,
    required this.createdAt,
  });

  factory TenantLink.fromJson(Map<String, dynamic> json) => TenantLink(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    tenantId: json['tenant_id'] as String,
    orgId: json['org_id'] as String,
    orgName: json['orgs'] != null ? json['orgs']['name'] as String? : null,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
