import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

import 'package:echopub/theme.dart';

class DepositFormPage extends StatefulWidget {
  final String userId;
  final String campaignId;
  const DepositFormPage({Key? key, required this.userId, required this.campaignId}) : super(key: key);

  @override
  State<DepositFormPage> createState() => _DepositFormPageState();
}

class _DepositFormPageState extends State<DepositFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  bool _loading = false;
  String? _error;
  String _selectedMethod = 'cm.mtn';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
String _formatDate(dynamic date) {
  if (date == null) return '';
  DateTime? dt;
  if (date is DateTime) {
    dt = date;
  } else if (date is String) {
    dt = DateTime.tryParse(date);
  }
  if (dt == null) return date.toString();
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
  Future<void> _submitDeposit() async {
   final formState = _formKey.currentState;
   debugPrint('Form state: $formState');
   if (formState == null || !formState.validate()) return;
    setState(() { _loading = true; _error = null; });
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');
    final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
    final body = {
      "user": widget.userId,
      "type": "deposit",
      "method": _selectedMethod,
      "campaign": widget.campaignId,
      "paymentData": {
        "phone": _phoneController.text.trim()
      }
    };
    final url = Uri.parse('$apiUrl/api/transactions');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dépôt soumis !')));
        Navigator.pushReplacementNamed(context, '/advertiser');
      } else {
        final message = jsonDecode(response.body)!['message'];
        setState(() { _error = 'Erreur: ${response.statusCode} : $message'; });
      }
    } catch (e) {
      setState(() { _error = 'Erreur réseau: $e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer les infos de l'annonce depuis le backend si besoin
    // Ici, on suppose que les infos sont passées via ModalRoute ou à compléter
    final ad = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement via Mobile Money'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Colors.blue.shade50,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ad == null
                        ? const Text('Récapitulatif indisponible.', style: TextStyle(color: Colors.red))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ad['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              if (ad['description'] != null) ...[
                                const SizedBox(height: 4),
                                Text(ad['description'], style: const TextStyle(fontSize: 15)),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.monetization_on, color: Colors.orange, size: 18),
                                  const SizedBox(width: 4),
                                  Flexible(child: Text('Budget: ${ad['budget'] ?? '-'} FCFA', style: const TextStyle(fontSize: 15))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                children: [
                                  const Icon(Icons.flag, size: 18, color: Colors.orange),
                                 
                                  if (ad['expected_views'] != null)
                                    Text('Objectif : ${ad['expected_views']} vues', style: const TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                                 
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (ad['start_date'] != null)
                                    Flexible(
                                      child: Text(
                                        'Début: ${_formatDate(ad['start_date'])}',
                                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                                      ),
                                    ),
                                  if (ad['end_date'] != null) ...[
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        'Fin: ${_formatDate(ad['end_date'])}',
                                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
  
                              if (ad['target_location'] != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: Colors.red),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        ad['location_type'] != 'city'
                                            ? 'Région: ${ad['target_location'].map((e) => e['value']).join(', ')}'
                                            : 'Ville: ${ad['target_location'].map((e) => e['value']).join(', ')}',
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
                // ...formulaire paiement...
                const Text('Mode de paiement', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedMethod,
                  items: [
                    DropdownMenuItem(
                      value: 'cm.mtn',
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/logo-mtn-money.jpeg',
                            height: 24,
                            width: 24,
                            errorBuilder: (_, __, ___) => Icon(Icons.image, size: 24, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          const Text('MTN Mobile Money'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'cm.orange',
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/orange-money-logo.png',
                            height: 24,
                            width: 24,
                            errorBuilder: (_, __, ___) => Icon(Icons.image, size: 24, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          const Text('Orange Money'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() { _selectedMethod = v; });
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                const Text('Numéro Mobile Money', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Téléphone (237...)'),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ requis';
                    if (!RegExp(r'^237[0-9]{9}').hasMatch(v)) return 'Format: 237XXXXXXXXX';
                    return null;
                  },  
                ),
                const SizedBox(height: 24),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                    onPressed: _loading ? null : _submitDeposit,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Soumettre', style: TextStyle(color: Colors.white)),
                  ),
                ),
               _loading? const SizedBox(width: double.infinity,
                child: Text(
                  'Veuillez valider le paiement dans votre telephone...',
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
                ):Container(),
                ],
            ),
          ),
        ),
      ),
    );
  }
}
