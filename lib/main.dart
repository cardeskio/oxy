import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/nav.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/services/auth_service.dart';
import 'package:oxy/services/org_service.dart';
import 'package:oxy/services/tenant_service.dart';
import 'package:oxy/services/notification_service.dart';
import 'package:oxy/services/living_service.dart';
import 'package:oxy/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use bundled fonts instead of fetching from network
  GoogleFonts.config.allowRuntimeFetching = false;
  
  await SupabaseConfig.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService _authService = AuthService();
  final OrgService _orgService = OrgService();
  final DataService _dataService = DataService();
  final TenantService _tenantService = TenantService();
  final NotificationService _notificationService = NotificationService();
  final LivingService _livingService = LivingService();

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _listenToAuthChanges();
  }

  Future<void> _initializeServices() async {
    await _authService.initialize();
    
    if (_authService.isAuthenticated && _authService.currentUserId != null) {
      // Initialize notification service for all authenticated users
      await _notificationService.initialize();
      
      // Initialize admin services
      await _orgService.initialize(_authService.currentUserId!);
      if (_orgService.currentOrgId != null) {
        await _dataService.initializeForOrg(_orgService.currentOrgId!);
      } else {
        // Ensure DataService loading state is cleared even without an org
        await _dataService.initialize();
      }
      
      // Initialize tenant services (for tenant users)
      if (_authService.userType == UserType.tenant) {
        await _tenantService.initialize();
      }
      
      // Initialize living service for all authenticated users
      await _livingService.initialize();
    }
  }

  void _listenToAuthChanges() {
    _authService.authStateChanges.listen((AuthState state) async {
      if (state.event == AuthChangeEvent.signedIn) {
        await _authService.refresh();
        if (_authService.currentUserId != null) {
          // Initialize notification service
          await _notificationService.initialize();
          
          await _orgService.initialize(_authService.currentUserId!);
          if (_orgService.currentOrgId != null) {
            await _dataService.initializeForOrg(_orgService.currentOrgId!);
          } else {
            // Ensure DataService loading state is cleared even without an org
            await _dataService.initialize();
          }
          // Initialize tenant service for tenant users
          if (_authService.userType == UserType.tenant) {
            await _tenantService.initialize();
          }
          
          // Initialize living service
          await _livingService.initialize();
        }
      } else if (state.event == AuthChangeEvent.signedOut) {
        _orgService.clear();
        _dataService.clear();
        _tenantService.clear();
        _notificationService.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authService),
        ChangeNotifierProvider.value(value: _orgService),
        ChangeNotifierProvider.value(value: _dataService),
        ChangeNotifierProvider.value(value: _tenantService),
        ChangeNotifierProvider.value(value: _notificationService),
        ChangeNotifierProvider.value(value: _livingService),
      ],
      child: MaterialApp.router(
        title: 'Oxy',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
