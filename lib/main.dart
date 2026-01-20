import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/nav.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/services/auth_service.dart';
import 'package:oxy/services/org_service.dart';
import 'package:oxy/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _listenToAuthChanges();
  }

  Future<void> _initializeServices() async {
    await _authService.initialize();
    
    if (_authService.isAuthenticated && _authService.currentUserId != null) {
      await _orgService.initialize(_authService.currentUserId!);
      if (_orgService.currentOrgId != null) {
        await _dataService.initializeForOrg(_orgService.currentOrgId!);
      }
    }
  }

  void _listenToAuthChanges() {
    _authService.authStateChanges.listen((AuthState state) async {
      if (state.event == AuthChangeEvent.signedIn) {
        await _authService.refresh();
        if (_authService.currentUserId != null) {
          await _orgService.initialize(_authService.currentUserId!);
          if (_orgService.currentOrgId != null) {
            await _dataService.initializeForOrg(_orgService.currentOrgId!);
          }
        }
      } else if (state.event == AuthChangeEvent.signedOut) {
        _orgService.clear();
        _dataService.clear();
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
      ],
      child: MaterialApp.router(
        title: 'PropManager KE',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
