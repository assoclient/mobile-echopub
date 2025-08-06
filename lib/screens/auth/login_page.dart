import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile/screens/advertiser/advertiser_home.dart';
import 'package:mobile/services/auth_service.dart';
import '../../theme.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../ambassador/ambassador_home.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import '../advertiser/advertiser_home.dart'; // Décommentez si vous avez une page annonceur

class LoginPage extends StatefulWidget {
  final VoidCallback? onRegisterTap;
  const LoginPage({Key? key, this.onRegisterTap}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    try {
      // Remplacez l'URL par celle de votre backend
      final url = Uri.parse('${dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000'}/api/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: '{"email": "$email", "password": "$password"}',
      );
      debugPrint('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        debugPrint('Login successful: ${response.body}');
        // Supposons que la réponse contient { token, user: { ... , role } }
        final resp = jsonDecode(response.body);
        final token = resp['token'];
        final user = resp['user'];
        // Stocke le token et l'utilisateur
        await AuthService.saveAuth(token, user);
        if (!mounted) return;
        if (user['role'] == 'ambassador') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AmbassadorHome()),
          );
        } else if (user['role'] == 'advertiser') {
           Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdvertiserHome()));
        } else {
          // Autre rôle ou erreur
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rôle non supporté.')));
        }
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdvertiserHome()));
        setState(() {
          _error = 'Email ou mot de passe incorrect';
        });
      }
    } catch (e) {
      debugPrint('Login error: $e');
      setState(() {
        _error = 'Erreur de connexion. Vérifiez votre réseau.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Connexion', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, color: AppColors.primaryBlue),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: Icon(Icons.lock, color: AppColors.primaryBlue),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Se connecter'),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: widget.onRegisterTap,
                child: const Text('Créer un compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
