import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:echopub/services/auth_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../theme.dart';

class ContactData {
  final String name;
  String ageRange;
  String gender;
  String city;

  ContactData({
    required this.name,
    this.ageRange = '18-25',
    this.gender = 'M',
    this.city = 'Douala',
  });
}

class AudienceCollectionPage extends StatefulWidget {
  final Map<String, dynamic> registrationData;
  final Function(Map<String, dynamic>)? onComplete; // Rendu optionnel

  const AudienceCollectionPage({
    Key? key,
    required this.registrationData,
    this.onComplete, // Rendu optionnel
  }) : super(key: key);

  @override
  State<AudienceCollectionPage> createState() => _AudienceCollectionPageState();
}

class _AudienceCollectionPageState extends State<AudienceCollectionPage> {
  List<ContactData> contacts = [];
  List<Map<String, dynamic>> cities = [];
  bool isLoading = true;
  bool hasPermission = false;
  String? errorMessage;
  bool isRegistering = false; // Nouveau: pour l'état de l'inscription

  final List<String> ageRanges = ['18-25', '26-35', '36-45', '46-55', '56+'];
  final List<String> genders = ['M', 'F'];

  @override
  void initState() {
    super.initState();
    _loadCities();
    _requestContactsPermission();
  }

  Future<void> _loadCities() async {
    try {
      final String citiesJson = await DefaultAssetBundle.of(context)
          .loadString('assets/cities_cm.json');
      final List<dynamic> citiesList = json.decode(citiesJson);
      setState(() {
        cities = citiesList.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      print('Erreur lors du chargement des villes: $e');
    }
  }

  Future<void> _requestContactsPermission() async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      setState(() {
        errorMessage = 'Permission d\'accès aux contacts refusée';
        isLoading = false;
      });
      return;
    }
    
    await _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final List<Contact> deviceContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      
      setState(() {
        contacts = deviceContacts.map((contact) {
          return ContactData(
            name: contact.displayName,
          );
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors du chargement des contacts: $e';
        isLoading = false;
      });
    }
  }

  void _updateContactData(int index, String field, String value) {
    setState(() {
      switch (field) {
        case 'ageRange':
          contacts[index].ageRange = value;
          break;
        case 'gender':
          contacts[index].gender = value;
          break;
        case 'city':
          contacts[index].city = value;
          break;
      }
    });
  }

  Map<String, dynamic> _calculateAudienceStats() {
    final Map<String, Map<String, int>> stats = {
      'city': {},
      'age': {},
      'genre': {},
    };

    for (final contact in contacts) {
      // Statistiques par ville
      stats['city']![contact.city] = (stats['city']![contact.city] ?? 0) + 1;
      
      // Statistiques par tranche d'âge
      stats['age']![contact.ageRange] = (stats['age']![contact.ageRange] ?? 0) + 1;
      
      // Statistiques par genre
      stats['genre']![contact.gender] = (stats['genre']![contact.gender] ?? 0) + 1;
    }

    final int totalContacts = contacts.length;
    
    // Convertir en pourcentages
    final List<Map<String, dynamic>> cityStats = stats['city']!.entries.map((entry) {
      return {
        'pourcentage': ((entry.value / totalContacts) * 100).round(),
        'value': entry.key,
      };
    }).toList();

    final List<Map<String, dynamic>> ageStats = stats['age']!.entries.map((entry) {
      final ageRange = entry.key;
      final parts = ageRange.split('-');
      return {
        'pourcentage': ((entry.value / totalContacts) * 100).round(),
        'value': {
          'min': int.parse(parts[0]),
          'max': parts[1] == '+' ? 100 : int.parse(parts[1]),
        },
      };
    }).toList();

    final List<Map<String, dynamic>> genreStats = stats['genre']!.entries.map((entry) {
      return {
        'pourcentage': ((entry.value / totalContacts) * 100).round(),
        'value': entry.key,
      };
    }).toList();

    return {
      'audience': {
        'city': cityStats,
        'age': ageStats,
        'genre': genreStats,
      },
    };
  }

  Future<void> _completeRegistration() async {
    setState(() {
      isRegistering = true;
    });

    try {
      final audienceStats = _calculateAudienceStats();
      final completeData = {
        ...widget.registrationData,
        ...audienceStats,
      };
      debugPrint("completeData: $completeData");
      // Appeler le callback si fourni (pour compatibilité)
      if (widget.onComplete != null) {
        widget.onComplete!(completeData);
        return; // Sortir si le callback gère l'inscription
      }

      // Envoyer la requête d'inscription directement au backend
      final response = await http.post(
        Uri.parse('${dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000/api'}/api/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(completeData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
       // final responseData = jsonDecode(response.body);
        
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inscription réussie ! Bienvenue ${completeData['name']}'),
            backgroundColor: Colors.green,
          ),
        );

        // Attendre un peu avant de naviguer
        await Future.delayed(const Duration(seconds: 2));
        
       final resp = jsonDecode(response.body);
        final token = resp['token'];
        final user = resp['user'];
        // Stocke le token et l'utilisateur
        await AuthService.saveAuth(token, user);
        if (mounted) {
          if (user != null && user['role'] == 'ambassador') {
            Navigator.of(context).pushReplacementNamed('/ambassador');
          } else if (user != null && user['role'] == 'advertiser') {
            Navigator.of(context).pushReplacementNamed('/advertiser');
          }
        }
      } else {
        debugPrint("Erreur API: ${response.body}");
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Erreur lors de l\'inscription';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Erreur lors de l'inscription: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isRegistering = false;
        });
      }
    }
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(errorMessage!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _requestContactsPermission,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      child: Column(
                        children: [
                          Icon(Icons.people, size: 48, color: AppColors.primaryBlue),
                          const SizedBox(height: 8),
                          Text(
                            'Statistiques d\'audience',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${contacts.length} contacts chargés',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Modifiez les données selon vos connaissances de votre audience',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final contact = contacts[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contact.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      if (constraints.maxWidth < 600) {
                                        // Layout en colonnes pour les petits écrans
                                        return Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text('Tranche d\'âge', style: TextStyle(fontSize: 12)),
                                                      DropdownButtonFormField<String>(
                                                        value: contact.ageRange,
                                                        decoration: const InputDecoration(
                                                          border: OutlineInputBorder(),
                                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          isDense: true,
                                                        ),
                                                        items: ageRanges.map((age) {
                                                          return DropdownMenuItem(
                                                            value: age,
                                                            child: Text(age, style: const TextStyle(fontSize: 12)),
                                                          );
                                                        }).toList(),
                                                        onChanged: (value) {
                                                          if (value != null) {
                                                            _updateContactData(index, 'ageRange', value);
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text('Genre', style: TextStyle(fontSize: 12)),
                                                      DropdownButtonFormField<String>(
                                                        value: contact.gender,
                                                        decoration: const InputDecoration(
                                                          border: OutlineInputBorder(),
                                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          isDense: true,
                                                        ),
                                                        items: genders.map((gender) {
                                                          return DropdownMenuItem(
                                                            value: gender,
                                                            child: Text(gender, style: const TextStyle(fontSize: 12)),
                                                          );
                                                        }).toList(),
                                                        onChanged: (value) {
                                                          if (value != null) {
                                                            _updateContactData(index, 'gender', value);
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Ville', style: TextStyle(fontSize: 12)),
                                                DropdownButtonFormField<String>(
                                                  value: contact.city,
                                                  decoration: const InputDecoration(
                                                    border: OutlineInputBorder(),
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    isDense: true,
                                                  ),
                                                  items: cities.map((city) {
                                                    return DropdownMenuItem<String>(
                                                      value: city['name'],
                                                      child: Text(city['name'], style: const TextStyle(fontSize: 12)),
                                                    );
                                                  }).toList(),
                                                  onChanged: (value) {
                                                    if (value != null) {
                                                      _updateContactData(index, 'city', value);
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      } else {
                                        // Layout en ligne pour les grands écrans
                                        return Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Tranche d\'âge', style: TextStyle(fontSize: 12)),
                                                  DropdownButtonFormField<String>(
                                                    value: contact.ageRange,
                                                    decoration: const InputDecoration(
                                                      border: OutlineInputBorder(),
                                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      isDense: true,
                                                    ),
                                                    items: ageRanges.map((age) {
                                                      return DropdownMenuItem(
                                                        value: age,
                                                        child: Text(age, style: const TextStyle(fontSize: 12)),
                                                      );
                                                    }).toList(),
                                                    onChanged: (value) {
                                                      if (value != null) {
                                                        _updateContactData(index, 'ageRange', value);
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Genre', style: TextStyle(fontSize: 12)),
                                                  DropdownButtonFormField<String>(
                                                    value: contact.gender,
                                                    decoration: const InputDecoration(
                                                      border: OutlineInputBorder(),
                                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      isDense: true,
                                                    ),
                                                    items: genders.map((gender) {
                                                      return DropdownMenuItem(
                                                        value: gender,
                                                        child: Text(gender, style: const TextStyle(fontSize: 12)),
                                                      );
                                                    }).toList(),
                                                    onChanged: (value) {
                                                      if (value != null) {
                                                        _updateContactData(index, 'gender', value);
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Ville', style: TextStyle(fontSize: 12)),
                                                  DropdownButtonFormField<String>(
                                                    value: contact.city,
                                                    decoration: const InputDecoration(
                                                      border: OutlineInputBorder(),
                                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      isDense: true,
                                                    ),
                                                    items: cities.map((city) {
                                                      return DropdownMenuItem<String>(
                                                        value: city['name'],
                                                        child: Text(city['name'], style: const TextStyle(fontSize: 12)),
                                                      );
                                                    }).toList(),
                                                    onChanged: (value) {
                                                      if (value != null) {
                                                        _updateContactData(index, 'city', value);
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isRegistering ? null : _completeRegistration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: isRegistering
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Inscription en cours...',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Terminer l\'inscription',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
