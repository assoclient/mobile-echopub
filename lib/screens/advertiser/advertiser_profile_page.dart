import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdvertiserProfilePage extends StatefulWidget {
  const AdvertiserProfilePage({Key? key}) : super(key: key);

  @override
  State<AdvertiserProfilePage> createState() => _AdvertiserProfilePageState();
}

class _AdvertiserProfilePageState extends State<AdvertiserProfilePage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final user = await AuthService.getUser();
      if (user == null || user['_id'] == null) {
        setState(() {
          _error = "Impossible de récupérer l'utilisateur.";
          _loading = false;
        });
        return;
      }
      debugPrint('Fetching profile for user: ${user}');
      setState(() {
          _profile = user;
          _loading = false;
        });
     
    } catch (e) {
      setState(() {
        _error = 'Erreur réseau: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _profile == null
                  ? const Center(child: Text('Aucune donnée.'))
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              child: Text((_profile!['name'] ?? 'A')[0], style: const TextStyle(fontSize: 32)),
                            ),
                            const SizedBox(height: 16),
                            Text(_profile!['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            Text(_profile!['email'] ?? '', style: const TextStyle(fontSize: 16)),
                            if (_profile!['phone'] != null)
                              Text(_profile!['phone'], style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: [
                                if (_profile!['balance'] != null)
                                  Chip(label: Text('Solde: ${_profile!['balance']} FCFA')),

                              ],
                            ),
                            const SizedBox(height: 24),
                          if (_profile!['createdAt'] != null)
                            Text('Inscrit le: ${_profile!['createdAt'].toString().substring(0, 10)}'),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.logout),
                            label: const Text('Déconnexion'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                                Navigator.pop(context);
                                AuthService.clear();
                                // TODO: Rediriger vers la page de connexion
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Déconnecté.')));
                              },
                          ),
                        ],
                      ),
                    ),
                    ),
    );
  }
}
