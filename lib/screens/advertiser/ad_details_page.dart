import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

import 'package:echopub/theme.dart';

class AdDetailsPage extends StatefulWidget {
  final String campaignId;
  const AdDetailsPage({Key? key, required this.campaignId}) : super(key: key);

  @override
  State<AdDetailsPage> createState() => _AdDetailsPageState();
}

class _AdDetailsPageState extends State<AdDetailsPage> {
  Map<String, dynamic>? _adDetails;
  List<Map<String, dynamic>> _publications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() { _loading = true; _error = null; });
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
      final url = Uri.parse('$apiUrl/api/campaigns/${widget.campaignId}');
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          _adDetails = decoded['campaign'] ?? {};
          _publications = List<Map<String, dynamic>>.from(decoded['publications'] ?? []);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Erreur serveur: ${response.statusCode}';
          _loading = false;
        });
      }
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
      appBar: AppBar(
        title: const Text('Détails de l\'annonce'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _adDetails == null
                  ? const Center(child: Text('Aucune donnée.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_adDetails!['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(_adDetails!['description'] ?? '', style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(label: Text('Budget: ${_adDetails!['budget']} FCFA')),
                              Chip(label: Text('Vues totales: ${_adDetails!['views'] ?? 0}')),
                              Chip(label: Text('Clics totaux: ${_adDetails!['clicks'] ?? 0}')),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('Toutes les publications(${_publications.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ..._publications.map((pub) => Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Ambassadeur: ${pub['ambassador_name'] ?? pub['ambassador'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.remove_red_eye, size: 18, color: Colors.blue.shade700),
                                          const SizedBox(width: 8),
                                          Text('Vues: ${pub['views'] ?? 0}'),
                                          const SizedBox(width: 8),
                                          Icon(Icons.touch_app, size: 18, color: Colors.green.shade700),
                                          const SizedBox(width: 8),
                                          Text('Clics: ${pub['clicks'] ?? 0}'),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                     
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                             if (pub['proof1'] != null)
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                             children: [
                                              const Text('Capture 1:'),
                                             
                                              Image.network(pub['proof1'], height: 280, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                                             ],
                                            ),
                                            if (pub['proof2'] != null)
                                              Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Text('Capture 2:'),
                                                  const SizedBox(height: 4),
                                                  Image.network(pub['proof2'], height: 280, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                                                ],
                                              )
                                          ],
                                        ),
                                      
                                    ],
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
    );
  }
}
