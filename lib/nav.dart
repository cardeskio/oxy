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

// Auth pages
import 'package:oxy/pages/auth/login_page.dart';
import 'package:oxy/pages/auth/signup_page.dart';
import 'package:oxy/pages/auth/forgot_password_page.dart';
import 'package:oxy/pages/auth/claim_code_page.dart';
import 'package:oxy/pages/auth/create_org_page.dart';
import 'package:oxy/pages/auth/link_tenant_page.dart';

// Tenant pages
import 'package:oxy/pages/tenant/tenant_shell.dart';
import 'package:oxy/pages/tenant/tenant_dashboard_page.dart';
import 'package:oxy/pages/tenant/tenant_invoices_page.dart';
import 'package:oxy/pages/tenant/tenant_payments_page.dart';
import 'package:oxy/pages/tenant/tenant_more_page.dart';
import 'package:oxy/pages/tenant/tenant_maintenance_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _adminShellNavigatorKey = GlobalKey<NavigatorState>();
final _tenantShellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final SupabaseAuthManager _authManager = SupabaseAuthManager();
  static final AuthService _authService = AuthService();

  static final GoRouter router = GoRouter(
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
      
      // Onboarding routes (authenticated but no org/tenant yet)
      final onboardingRoutes = [
        AppRoutes.claimCode,
        AppRoutes.createOrg,
      ];
      
      final isPublicRoute = publicRoutes.contains(currentPath);
      final isOnboardingRoute = onboardingRoutes.contains(currentPath);
      
      // Admin routes (require org membership)
      final isAdminRoute = currentPath == AppRoutes.dashboard ||
          currentPath == AppRoutes.properties ||
          currentPath == AppRoutes.tenants ||
          currentPath == AppRoutes.invoices ||
          currentPath == AppRoutes.more ||
          currentPath.startsWith('/properties/') ||
          currentPath.startsWith('/tenants/') ||
          currentPath.startsWith('/invoices/') ||
          currentPath == AppRoutes.payments ||
          currentPath == AppRoutes.maintenance ||
          currentPath == AppRoutes.addProperty ||
          currentPath == AppRoutes.addTenant ||
          currentPath == AppRoutes.addLease ||
          currentPath == AppRoutes.addPayment ||
          currentPath == AppRoutes.addTicket;
      
      // Tenant routes
      final isTenantRoute = currentPath.startsWith('/tenant');
      
      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isPublicRoute) {
        return AppRoutes.login;
      }
      
      // If authenticated, always initialize auth service to get user type
      if (isAuthenticated) {
        await _authService.initialize();
        
        // On public routes, redirect to appropriate dashboard
        if (isPublicRoute) {
          if (_authService.userType == UserType.admin) {
            return AppRoutes.dashboard;
          } else if (_authService.userType == UserType.tenant) {
            return AppRoutes.tenantDashboard;
          } else {
            // User has no role - check if they have a claim code
            if (_authService.claimCode != null && !_authService.claimCode!.isClaimed) {
              return AppRoutes.claimCode;
            }
            // Otherwise, they need to create an org
            return AppRoutes.createOrg;
          }
        }
        
        // If user has unknown type (no org or tenant link) and trying to access admin/tenant routes
        if (_authService.userType == UserType.unknown) {
          if (isAdminRoute || isTenantRoute) {
            // Redirect to onboarding
            if (_authService.claimCode != null && !_authService.claimCode!.isClaimed) {
              return AppRoutes.claimCode;
            }
            return AppRoutes.createOrg;
          }
        }
        
        // If admin trying to access tenant routes, redirect to admin dashboard
        if (_authService.userType == UserType.admin && isTenantRoute) {
          return AppRoutes.dashboard;
        }
        
        // If tenant trying to access admin routes, redirect to tenant dashboard
        if (_authService.userType == UserType.tenant && isAdminRoute) {
          return AppRoutes.tenantDashboard;
        }
      }
      
      return null;
    },
    routes: [
      // ==================== AUTH ROUTES ====================
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => const NoTransitionPage(child: LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        pageBuilder: (context, state) => const NoTransitionPage(child: SignupPage()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        pageBuilder: (context, state) => const NoTransitionPage(child: ForgotPasswordPage()),
      ),
      GoRoute(
        path: AppRoutes.claimCode,
        name: 'claimCode',
        pageBuilder: (context, state) => const NoTransitionPage(child: ClaimCodePage()),
      ),
      GoRoute(
        path: AppRoutes.createOrg,
        name: 'createOrg',
        pageBuilder: (context, state) => const NoTransitionPage(child: CreateOrgPage()),
      ),

      // ==================== ADMIN SHELL ROUTES ====================
      ShellRoute(
        navigatorKey: _adminShellNavigatorKey,
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(child: DashboardPage()),
          ),
          GoRoute(
            path: AppRoutes.properties,
            name: 'properties',
            pageBuilder: (context, state) => const NoTransitionPage(child: PropertiesPage()),
          ),
          GoRoute(
            path: AppRoutes.tenants,
            name: 'tenants',
            pageBuilder: (context, state) => const NoTransitionPage(child: TenantsPage()),
          ),
          GoRoute(
            path: AppRoutes.invoices,
            name: 'invoices',
            pageBuilder: (context, state) => const NoTransitionPage(child: InvoicesPage()),
          ),
          GoRoute(
            path: AppRoutes.more,
            name: 'more',
            pageBuilder: (context, state) => const NoTransitionPage(child: MorePage()),
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
            pageBuilder: (context, state) => const NoTransitionPage(child: TenantDashboardPage()),
          ),
          GoRoute(
            path: AppRoutes.tenantInvoices,
            name: 'tenantInvoices',
            pageBuilder: (context, state) => const NoTransitionPage(child: TenantInvoicesPage()),
          ),
          GoRoute(
            path: AppRoutes.tenantPayments,
            name: 'tenantPayments',
            pageBuilder: (context, state) => const NoTransitionPage(child: TenantPaymentsPage()),
          ),
          GoRoute(
            path: AppRoutes.tenantMore,
            name: 'tenantMore',
            pageBuilder: (context, state) => const NoTransitionPage(child: TenantMorePage()),
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
  static const String tenantInvoices = '/tenant/invoices';
  static const String tenantPayments = '/tenant/payments';
  static const String tenantMore = '/tenant/more';
  static const String tenantMaintenance = '/tenant/maintenance';
}
