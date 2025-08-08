import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/contact.dart';
import '../../theme.dart';

class AudienceCollectionPage extends StatefulWidget {
  final String userCity;
  final String userAgeRange;
  final String userGender;
  final Map<String, dynamic> registrationData;

  const AudienceCollectionPage({
    Key? key,
    required this.userCity,
    required this.userAgeRange,
    required this.userGender,
    required this.registrationData,
  }) : super(key: key);

  @override
  State<AudienceCollectionPage> createState() => _AudienceCollectionPageState();
}

class _AudienceCollectionPageState extends State<AudienceCollectionPage> {
  List<AudienceContact> _contacts = [];
  List<AudienceContact> _filteredContacts = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.contacts.request();
    setState(() {
      _hasPermission = status.isGranted;
    });
    
    if (_hasPermission) {
      await _loadContacts();
    }
  }

  Future<void> _loadContacts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final contacts = await FlutterContacts.getContacts();
      final List<AudienceContact> processedContacts = [];

      for (var contact in contacts) {
        if (contact.displayName.isNotEmpty) {
          processedContacts.add(AudienceContact(
            name: contact.displayName,
            city: widget.userCity,
            ageRange: widget.userAgeRange,
            gender: widget.userGender,
          ));
        }
      }

      setState(() {
        _contacts = processedContacts;
        _filteredContacts = processedContacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des contacts: $e')),
      );
    }
  }

  void _filterContacts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredContacts = _contacts;
      } else {
        _filteredContacts = _contacts
            .where((contact) =>
                contact.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _updateContact(int index, String field, String value) {
    setState(() {
      final contact = _filteredContacts[index];
      final updatedContact = AudienceContact(
        name: field == 'name' ? value : contact.name,
        city: field == 'city' ? value : contact.city,
        ageRange: field == 'ageRange' ? value : contact.ageRange,
        gender: field == 'gender' ? value : contact.gender,
      );
      
      _filteredContacts[index] = updatedContact;
      
      // Mettre à jour dans la liste principale aussi
      final mainIndex = _contacts.indexWhere((c) => c.name == contact.name);
      if (mainIndex != -1) {
        _contacts[mainIndex] = updatedContact;
      }
    });
  }

  Future<void> _proceedToRegistration() async {
    // Préparer les données d'audience
    final audienceData = _prepareAudienceData();
    
    // Ajouter les données d'audience au payload d'inscription
    final registrationPayload = Map<String, dynamic>.from(widget.registrationData);
    registrationPayload['audience'] = audienceData;
    
    // Naviguer vers la page d'inscription finale ou procéder à l'inscription
    _registerWithAudienceData(registrationPayload);
  }

  Map<String, dynamic> _prepareAudienceData() {
    // Calculer les pourcentages pour chaque ville
    final cityStats = <String, int>{};
    final ageStats = <String, int>{};
    final genderStats = <String, int>{};
    
    for (var contact in _contacts) {
      cityStats[contact.city] = (cityStats[contact.city] ?? 0) + 1;
      ageStats[contact.ageRange] = (ageStats[contact.ageRange] ?? 0) + 1;
      genderStats[contact.gender] = (genderStats[contact.gender] ?? 0) + 1;
    }
    
    final total = _contacts.length;
    
    return {
      'city': cityStats.entries.map((entry) => {
        'pourcentage': ((entry.value / total) * 100).round(),
        'value': entry.key,
      }).toList(),
      'age': ageStats.entries.map((entry) => {
        'pourcentage': ((entry.value / total) * 100).round(),
        'value': _parseAgeRange(entry.key),
      }).toList(),
      'genre': genderStats.entries.map((entry) => {
        'pourcentage': ((entry.value / total) * 100).round(),
        'value': entry.key,
      }).toList(),
    };
  }

  Map<String, dynamic> _parseAgeRange(String ageRange) {
    // Convertir les tranches d'âge en format min/max
    switch (ageRange) {
      case '18-25':
        return {'min': 18, 'max': 25};
      case '26-35':
        return {'min': 26, 'max': 35};
      case '36-45':
        return {'min': 36, 'max': 45};
      case '46-55':
        return {'min': 46, 'max': 55};
      case '56+':
        return {'min': 56, 'max': 100};
      default:
        return {'min': 18, 'max': 65};
    }
  }

  Future<void> _registerWithAudienceData(Map<String, dynamic> payload) async {
    // Ici, vous pouvez appeler votre API d'inscription avec les données d'audience
    // Pour l'instant, on affiche juste les données
    print('Payload d\'inscription avec audience: ${jsonEncode(payload)}');
    
    // Naviguer vers la page suivante ou procéder à l'inscription
    Navigator.of(context).pop(payload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Collecte des statistiques d\'audience'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // En-tête avec informations
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.softGreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collecte des statistiques d\'audience',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nous collectons les informations de vos contacts pour analyser votre audience. '
                  'Vos données par défaut sont pré-remplies.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un contact...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _filterContacts,
            ),
          ),
          
          // Liste des contacts
          Expanded(
            child: _hasPermission
                ? _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredContacts.isEmpty
                        ? const Center(
                            child: Text('Aucun contact trouvé'),
                          )
                        : ListView.builder(
                            itemCount: _filteredContacts.length,
                            itemBuilder: (context, index) {
                              final contact = _filteredContacts[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Nom du contact
                                      Text(
                                        contact.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Informations d'audience
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildInfoField(
                                              'Ville',
                                              contact.city,
                                              (value) => _updateContact(
                                                index,
                                                'city',
                                                value,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildInfoField(
                                              'Âge',
                                              contact.ageRange,
                                              (value) => _updateContact(
                                                index,
                                                'ageRange',
                                                value,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildInfoField(
                                              'Genre',
                                              contact.gender,
                                              (value) => _updateContact(
                                                index,
                                                'gender',
                                                value,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                : _buildPermissionRequest(),
          ),
          
          // Bouton de continuation
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _contacts.isNotEmpty ? _proceedToRegistration : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Continuer avec ${_contacts.length} contacts',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        if (label == 'Genre')
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'M', child: Text('M')),
              DropdownMenuItem(value: 'F', child: Text('F')),
            ],
            onChanged: (newValue) {
              if (newValue != null) onChanged(newValue);
            },
          )
        else if (label == 'Âge')
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
            ),
            items: const [
              DropdownMenuItem(value: '18-25', child: Text('18-25')),
              DropdownMenuItem(value: '26-35', child: Text('26-35')),
              DropdownMenuItem(value: '36-45', child: Text('36-45')),
              DropdownMenuItem(value: '46-55', child: Text('46-55')),
              DropdownMenuItem(value: '56+', child: Text('56+')),
            ],
            onChanged: (newValue) {
              if (newValue != null) onChanged(newValue);
            },
          )
        else
          TextFormField(
            initialValue: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
            ),
            onChanged: onChanged,
          ),
      ],
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contact_phone,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Permission requise',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Nous avons besoin d\'accéder à vos contacts pour collecter les statistiques d\'audience.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _requestPermission,
            child: const Text('Autoriser l\'accès'),
          ),
        ],
      ),
    );
  }
} 