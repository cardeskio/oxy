import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oxy/auth/supabase_auth_manager.dart';
import 'package:oxy/services/auth_service.dart';

// Admin pages
import 'package:oxy/pages/admin_shell.dart';
import 'package:oxy/pages/dashboard_page.dart';
import 'package:oxy/pages/properties_page.dart';
import 'package:oxy/pages/property_detail_page.dart';
import 'package:oxy/pages/tenants_page.dart';
import 'package:oxy/pages/tenant_detail_page.dart';
import 'package:oxy/pages/invoices_page.dart';
import 'package:oxy/pages/invoice_detail_page.dart';
import 'package:oxy/pages/payments_page.dart';
import 'package:oxy/pages/maintenance_page.dart';
import 'package:oxy/pages/more_page.dart';
import 'package:oxy/pages/add_property_page.dart';
import 'package:oxy/pages/add_tenant_page.dart';
import 'package:oxy/pages/add_lease_page.dart';
import 'package:oxy/pages/add_payment_page.dart';
import 'package:oxy/pages/add_ticket_page.dart';
import 'package:oxy/pages/charges_page.dart';

// Auth pages
import 'package:oxy/pages/auth/login_page.dart';
import 'package:oxy/pages/auth/signup_page.dart';
import 'package:oxy/pages/auth/forgot_password_page.dart';
import 'package:oxy/pages/auth/claim_code_page.dart';
import 'package:oxy/pages/auth/create_org_page.dart';
import 'package:oxy/pages/auth/link_tenant_page.dart';

// Provider pages
import 'package:oxy/pages/provider/provider_onboarding_page.dart';
import 'package:oxy/pages/provider/provider_shell.dart';
import 'package:oxy/pages/provider/provider_dashboard_page.dart';
import 'package:oxy/pages/provider/provider_listings_page.dart';
import 'package:oxy/pages/provider/provider_orders_page.dart';
import 'package:oxy/pages/provider/provider_reviews_page.dart';
import 'package:oxy/pages/provider/provider_more_page.dart';

// Tenant pages
import 'package:oxy/pages/tenant/tenant_shell.dart';
import 'package:oxy/pages/tenant/tenant_dashboard_page.dart';
import 'package:oxy/pages/tenant/tenant_invoices_page.dart';
import 'package:oxy/pages/tenant/tenant_payments_page.dart';
import 'package:oxy/pages/tenant/tenant_more_page.dart';
import 'package:oxy/pages/tenant/tenant_maintenance_page.dart';
import 'package:oxy/pages/tenant/tenant_profile_page.dart';
import 'package:oxy/pages/tenant/tenant_explore_page.dart';
import 'package:oxy/pages/tenant/tenant_lease_page.dart';
import 'package:oxy/pages/tenant/tenant_ticket_detail_page.dart';
import 'package:oxy/pages/tenant/move_out_request_page.dart';
import 'package:oxy/pages/tenant/tenant_enquiries_page.dart';
import 'package:oxy/pages/tenant/tenant_living_page.dart';
import 'package:oxy/pages/tenant/tenant_orders_page.dart';
import 'package:oxy/pages/tenant/tenant_cart_page.dart';
import 'package:oxy/pages/ticket_detail_page.dart';
import 'package:oxy/pages/enquiries_page.dart';
import 'package:oxy/pages/notifications_page.dart';

class AppRouter {
  static final SupabaseAuthManager _authManager = SupabaseAuthManager();
  static AuthService? _authServiceInstance;
  
  static AuthService get _authService {
    _authServiceInstance ??= AuthService();
    return _authServiceInstance!;
  }

  // Navigator keys - created once per router instance
  static final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  static final _adminShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'adminShell');
  static final _tenantShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'tenantShell');
  static final _providerShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'providerShell');

  static GoRouter? _routerInstance;
  
  static GoRouter get router {
    return _routerInstance ??= _createRouter();
  }
  
  static GoRouter _createRouter() => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    redirect: (context, state) async {
      final isAuthenticated = _authManager.isAuthenticated;
      final currentPath = state.matchedLocation;
      
      // Public routes that don't require auth
      final publicRoutes = [
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.forgotPassword,
      ];
      
      final isPublicRoute = publicRoutes.contains(currentPath);
      
      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isPublicRoute) {
        return AppRoutes.login;
      }
      
      // If authenticated and on public route, redirect to appropriate dashboard
      if (isAuthenticated && isPublicRoute) {
        // Initialize auth service if needed
        if (!_authService.isInitialized) {
          await _authService.initialize();
        }
        
        if (_authService.userType == UserType.admin) {
          return AppRoutes.dashboard;
        } else if (_authService.userType == UserType.serviceProvider) {
          return AppRoutes.providerDashboard;
        } else {
          // All non-admin users go to tenant side
          if (_authService.tenantLinks.isNotEmpty) {
            return AppRoutes.tenantDashboard;
          } else {
            return AppRoutes.tenantExplore;
          }
        }
      }
      
      // No redirect needed
      return null;
    },
    routes: [
      // ==================== AUTH ROUTES ====================
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.claimCode,
        name: 'claimCode',
        builder: (context, state) => const ClaimCodePage(),
      ),
      GoRoute(
        path: AppRoutes.createOrg,
        name: 'createOrg',
        builder: (context, state) => const CreateOrgPage(),
      ),
      GoRoute(
        path: AppRoutes.providerOnboarding,
        name: 'providerOnboarding',
        builder: (context, state) => const ProviderOnboardingPage(),
      ),

      // ==================== ADMIN SHELL ROUTES ====================
      ShellRoute(
        navigatorKey: _adminShellNavigatorKey,
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.properties,
            name: 'properties',
            builder: (context, state) => const PropertiesPage(),
          ),
          GoRoute(
            path: AppRoutes.tenants,
            name: 'tenants',
            builder: (context, state) => const TenantsPage(),
          ),
          GoRoute(
            path: AppRoutes.invoices,
            name: 'invoices',
            builder: (context, state) => const InvoicesPage(),
          ),
          GoRoute(
            path: AppRoutes.more,
            name: 'more',
            builder: (context, state) => const MorePage(),
          ),
        ],
      ),

      // ==================== TENANT SHELL ROUTES ====================
      ShellRoute(
        navigatorKey: _tenantShellNavigatorKey,
        builder: (context, state, child) => TenantShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.tenantDashboard,
            name: 'tenantDashboard',
            builder: (context, state) => const TenantDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.tenantExplore,
            name: 'tenantExplore',
            builder: (context, state) => const TenantExplorePage(),
          ),
          GoRoute(
            path: AppRoutes.tenantLiving,
            name: 'tenantLiving',
            builder: (context, state) => const TenantLivingPage(),
          ),
          GoRoute(
            path: AppRoutes.tenantEnquiries,
            name: 'tenantEnquiries',
            builder: (context, state) => const TenantEnquiriesPage(),
          ),
          GoRoute(
            path: AppRoutes.tenantOrders,
            name: 'tenantOrders',
            builder: (context, state) => const TenantOrdersPage(),
          ),
          GoRoute(
            path: AppRoutes.tenantCart,
            name: 'tenantCart',
            builder: (context, state) => const TenantCartPage(),
          ),
          GoRoute(
            path: AppRoutes.tenantInvoices,
            name: 'tenantInvoices',
            builder: (context, state) => const TenantInvoicesPage(),
          ),
          GoRoute(
            path: AppRoutes.tenantPayments,
            name: 'tenantPayments',
            builder: (context, state) => const TenantPaymentsPage(),
          ),
          GoRoute(
            path: AppRoutes.tenantMore,
            name: 'tenantMore',
            builder: (context, state) => const TenantMorePage(),
          ),
        ],
      ),

      // ==================== PROVIDER SHELL ROUTES ====================
      ShellRoute(
        navigatorKey: _providerShellNavigatorKey,
        builder: (context, state, child) => ProviderShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.providerDashboard,
            name: 'providerDashboard',
            builder: (context, state) => const ProviderDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.providerListings,
            name: 'providerListings',
            builder: (context, state) => const ProviderListingsPage(),
          ),
          GoRoute(
            path: AppRoutes.providerOrders,
            name: 'providerOrders',
            builder: (context, state) => const ProviderOrdersPage(),
          ),
          GoRoute(
            path: AppRoutes.providerReviews,
            name: 'providerReviews',
            builder: (context, state) => const ProviderReviewsPage(),
          ),
          GoRoute(
            path: AppRoutes.providerMore,
            name: 'providerMore',
            builder: (context, state) => const ProviderMorePage(),
          ),
        ],
      ),

      // ==================== ADMIN DETAIL ROUTES ====================
      GoRoute(
        path: AppRoutes.propertyDetail,
        name: 'propertyDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PropertyDetailPage(propertyId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.tenantDetail,
        name: 'tenantDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TenantDetailPage(tenantId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.invoiceDetail,
        name: 'invoiceDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return InvoiceDetailPage(invoiceId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.payments,
        name: 'payments',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PaymentsPage(),
      ),
      GoRoute(
        path: AppRoutes.maintenance,
        name: 'maintenance',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MaintenancePage(),
      ),
      GoRoute(
        path: AppRoutes.addProperty,
        name: 'addProperty',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddPropertyPage(),
      ),
      GoRoute(
        path: AppRoutes.addTenant,
        name: 'addTenant',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddTenantPage(),
      ),
      GoRoute(
        path: AppRoutes.addLease,
        name: 'addLease',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final unitId = state.uri.queryParameters['unitId'];
          final tenantId = state.uri.queryParameters['tenantId'];
          return AddLeasePage(unitId: unitId, tenantId: tenantId);
        },
      ),
      GoRoute(
        path: AppRoutes.addPayment,
        name: 'addPayment',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final tenantId = state.uri.queryParameters['tenantId'];
          return AddPaymentPage(tenantId: tenantId);
        },
      ),
      GoRoute(
        path: AppRoutes.addTicket,
        name: 'addTicket',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final unitId = state.uri.queryParameters['unitId'];
          return AddTicketPage(unitId: unitId);
        },
      ),
      GoRoute(
        path: AppRoutes.linkTenant,
        name: 'linkTenant',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final code = state.uri.queryParameters['code'];
          return LinkTenantPage(prefilledCode: code);
        },
      ),
      
      // ==================== TENANT DETAIL ROUTES ====================
      GoRoute(
        path: AppRoutes.tenantMaintenance,
        name: 'tenantMaintenance',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TenantMaintenancePage(),
      ),
      GoRoute(
        path: AppRoutes.tenantProfile,
        name: 'tenantProfile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TenantProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.tenantLease,
        name: 'tenantLease',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TenantLeasePage(),
      ),
      GoRoute(
        path: AppRoutes.tenantMoveOut,
        name: 'tenantMoveOut',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MoveOutRequestPage(),
      ),
      GoRoute(
        path: AppRoutes.tenantTicketDetail,
        name: 'tenantTicketDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TenantTicketDetailPage(ticketId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.ticketDetail,
        name: 'ticketDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TicketDetailPage(ticketId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.charges,
        name: 'charges',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChargesManagementPage(),
      ),
      GoRoute(
        path: AppRoutes.enquiries,
        name: 'enquiries',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EnquiriesPage(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.tenantNotifications,
        name: 'tenantNotifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsPage(isTenantView: true),
      ),
      GoRoute(
        path: AppRoutes.providerNotifications,
        name: 'providerNotifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsPage(isProviderView: true),
      ),
    ],
  );
}

class AppRoutes {
  // Auth routes
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String claimCode = '/claim-code';
  static const String createOrg = '/create-org';
  static const String linkTenant = '/link-tenant';
  static const String providerOnboarding = '/provider-onboarding';

  // Admin routes
  static const String dashboard = '/';
  static const String properties = '/properties';
  static const String propertyDetail = '/properties/:id';
  static const String tenants = '/tenants';
  static const String tenantDetail = '/tenants/:id';
  static const String invoices = '/invoices';
  static const String invoiceDetail = '/invoices/:id';
  static const String payments = '/payments';
  static const String maintenance = '/maintenance';
  static const String more = '/more';
  static const String addProperty = '/add-property';
  static const String addTenant = '/add-tenant';
  static const String addLease = '/add-lease';
  static const String addPayment = '/add-payment';
  static const String addTicket = '/add-ticket';

  // Tenant routes
  static const String tenantDashboard = '/tenant';
  static const String tenantExplore = '/tenant/explore';
  static const String tenantLiving = '/tenant/living';
  static const String tenantInvoices = '/tenant/invoices';
  static const String tenantPayments = '/tenant/payments';
  static const String tenantMore = '/tenant/more';
  static const String tenantMaintenance = '/tenant/maintenance';
  static const String tenantProfile = '/tenant/profile';
  static const String tenantLease = '/tenant/lease';
  static const String tenantMoveOut = '/tenant/move-out';
  static const String tenantTicketDetail = '/tenant/maintenance/:id';
  static const String tenantEnquiries = '/tenant/enquiries';
  static const String tenantOrders = '/tenant/orders';
  static const String tenantCart = '/tenant/cart';
  
  // Admin detail routes
  static const String ticketDetail = '/maintenance/:id';
  static const String charges = '/charges';
  static const String enquiries = '/enquiries';
  static const String notifications = '/notifications';
  
  // Tenant detail routes
  static const String tenantNotifications = '/tenant/notifications';
  
  // Provider routes
  static const String providerDashboard = '/provider';
  static const String providerListings = '/provider/listings';
  static const String providerOrders = '/provider/orders';
  static const String providerReviews = '/provider/reviews';
  static const String providerMore = '/provider/more';
  static const String providerNotifications = '/provider/notifications';
}
