import 'package:flutter/material.dart';
import 'package:mobile/screens/advertiser/advertiser_dashboard.dart';
import 'package:mobile/screens/advertiser/create_ad_page.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/register_page.dart';
import 'screens/advertiser/advertiser_home.dart';
import 'screens/ambassador/ambassador_home.dart';
import 'screens/advertiser/advertiser_profile_page.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EchoPub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const AuthNavigator(),
        '/advertiser': (context) => const AdvertiserHome(),
        '/ambassador': (context) => const AmbassadorHome(),
        '/advertiser/create-campaign': (context) => const CreateAdPage(),
        '/advertiser/profile': (context) => const AdvertiserProfilePage(),
        '/advertiser/dashboard': (context) => const AdvertiserDashboardPage(),
      },
    );
  }
}

class AuthNavigator extends StatefulWidget {
  const AuthNavigator({Key? key}) : super(key: key);

  @override
  State<AuthNavigator> createState() => _AuthNavigatorState();
}

class _AuthNavigatorState extends State<AuthNavigator> {
  bool showRegister = false;
  bool _loading = true;
  String? _role;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = await AuthService.getUser();
    setState(() {
      _role = user != null ? user['role'] as String? : null;
      _loading = false;
    });
  }

  void toggle() => setState(() => showRegister = !showRegister);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Si connecté, afficher la navigation principale selon le rôle
    if (_role == 'ambassador' || _role == 'advertiser') {
      return MainScaffold(role: _role!);
    }

    return showRegister
        ? RegisterPage(onLoginTap: toggle)
        : LoginPage(onRegisterTap: toggle);
  }

}

class MainScaffold extends StatefulWidget {
  final String role;
  const MainScaffold({required this.role, Key? key}) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  List<Widget> get _ambassadorPages => const [
    AmbassadorHome(),
    // Remplacer par AmbassadorGains() et AmbassadorProfil() si existants
    Center(child: Text('Gains')), 
    Center(child: Text('Profil')),
  ];
  List<Widget> get _advertiserPages => const [
    AdvertiserHome(),
    AdvertiserProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isAmbassador = widget.role == 'ambassador';
    final pages = isAmbassador ? _ambassadorPages : _advertiserPages;
    return Scaffold(
      body: pages[_selectedIndex],
     
    );
  }
}
