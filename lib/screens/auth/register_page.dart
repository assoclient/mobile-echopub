import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../theme.dart';
import '../../utils/country_dial_codes.dart';
import '../../services/auth_service.dart';
import 'audience_collection_page.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback? onLoginTap;
  const RegisterPage({Key? key, this.onLoginTap}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isLoading = false;
  String? _apiError;
@override
  void initState() {
    super.initState();
    _whatsappController.text = '';
    _countryDialCode='+237';
    _detectLocation();
  }
  Future<void> _register(Map<String, dynamic> completeData) async {
    setState(() {
      _isLoading = true;
      _apiError = null;
    });
    
    final url = Uri.parse('${dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000'}/api/auth/register');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(completeData),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Succès : login automatique (stockage du token possible ici)
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
          } else {
            widget.onLoginTap?.call();
          }
        }
      } else {
        setState(() {
          _apiError = 'Erreur: ' + (jsonDecode(response.body)['message']?.toString() ?? 'Inconnue');
        });
      }
    } catch (e) {
      setState(() {
        _apiError = 'Erreur réseau: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _proceedToAudienceCollection() {
    final Map<String, dynamic> registrationData = {
      'name': _name,
      'email': _email,
      'password': _password,
      'role': _role,
      'ageRange': _ageRange,
      'gender': _gender,
      'phone': _role == 'advertiser' ? _phoneController.text : null,
      'whatsapp_number': _role == 'ambassador' ? _whatsappController.text : null,
      'location': {
          'countryCode':_countryDialCode,
          'city': _role == 'ambassador' ? _cityController.text : null,
          'region': _role == 'ambassador' ? _regionController.text : null,
          'gps': {
            'lat': _role == 'ambassador' ? _lat: null,
            'lng': _role == 'ambassador' ? _lng : null
          }
      },
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AudienceCollectionPage(
          registrationData: registrationData,
        ),
      ),
    );
  }

  final _formKey = GlobalKey<FormState>();
  String? _name, _email, _password;
  String _role = 'ambassador';

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _ageRangeController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  String? _ageRange, _gender;
  double? _lat, _lng;
  String? _locationError;
  String _countryDialCode = '+237'; // Par défaut Cameroun

  Future<void> _detectLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _locationError = "Permission refusée");
        return;
      }
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locationError = null;
      });
      // Reverse geocoding pour ville, région et code pays
      List<Placemark> placemarks = await placemarkFromCoordinates(_lat!, _lng!);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
      debugPrint("Localisation détectée: ${place.isoCountryCode}",);
        setState(() {
          _cityController.text = place.locality ?? '';
          _regionController.text = place.administrativeArea!.replaceAll("Région du", '') ?? '';
          //_countryDialCode = getDialCodeFromCountry(place.isoCountryCode);
        });
      }
    } catch (e) {
      debugPrint("Erreur de géolocalisation: $e");
      setState(() => _locationError = "Erreur de localisation");
    }
  }

  // Utilise maintenant getDialCodeFromCountry du fichier utils/country_dial_codes.dart
  @override
  Widget build(BuildContext context) {
    setState(() {
    _countryDialCode='CM';
  });
  
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Créer un compte', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 24),
               
                  Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(
              _role == 'ambassador' ? AppColors.primaryBlue : Colors.grey,
            ),
            foregroundColor: MaterialStateProperty.all(Colors.white),
          ),
          onPressed: () => {
            setState(() => _role = 'ambassador'),
          },
          child: const Text('Ambassadeur'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(
              _role == 'advertiser' ? AppColors.primaryBlue : Colors.grey,
            ),
            foregroundColor: MaterialStateProperty.all(Colors.white),
          ),
          onPressed: () => {
            setState(() => _role = 'advertiser'),
          },
          child: const Text('Annonceur'),
        ),
      ],
    ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      prefixIcon: Icon(Icons.person, color: AppColors.primaryBlue),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                    onSaved: (v) => _name = v,
                  ),
                  
                  if (_role == 'advertiser')
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Téléphone',
                        prefixIcon: Icon(Icons.phone, color: AppColors.primaryBlue),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                    ),
                  //const SizedBox(height: 16),
                  if (_role == 'advertiser')
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email, color: AppColors.primaryBlue),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                      onSaved: (v) => _email = v,
                    ),
                  //const SizedBox(height: 16),
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: Icon(Icons.lock, color: AppColors.primaryBlue),
                    ),
                    validator: (v) => v == null || v.length < 6 ? '6 caractères min.' : null,
                    onSaved: (v) => _password = v,
                  ),
                 // const SizedBox(height: 16),
                  
                  if (_role == 'ambassador') ...[
                    
                   // const SizedBox(height: 16),
                    IntlPhoneField(
                      controller: _whatsappController,
                      initialCountryCode: _countryDialCode,
                      decoration: InputDecoration(
                        labelText: 'Numéro WhatsApp',
                        prefixIcon: Icon(Icons.chat, color: AppColors.primaryBlue),
                      ),
                      onChanged: (phone) => {
                         debugPrint("phone: ${phone.countryCode}"),
                          setState(() {
                          _countryDialCode = phone.countryCode;
                          })
                      },
                      onSaved: (phone) {
                        if (phone != null) {
                          setState(() {
                         _whatsappController.text = phone.number;
                          });
                        }
                      },
                      disableLengthCheck: false,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      value: _ageRange,
                      onChanged: (String? value) {
                        setState(() {
                          _ageRange = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Tranche d\'âge',
                        prefixIcon: Icon(Icons.person, color: AppColors.primaryBlue),
                      ),  
                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                      onSaved: (v) => _ageRange = v,
                      items: ['18-25', '26-35', '36-45', '46-55', '56+'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: TextStyle(color: AppColors.primaryBlue,fontSize: 12)),
                        );
                      }).toList(),
                      style: TextStyle(color: AppColors.primaryBlue,fontSize: 12),
                      dropdownColor: AppColors.white,
                      iconEnabledColor: AppColors.primaryBlue,
                      iconDisabledColor: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      value: _gender,
                      onChanged: (String? value) {
                        setState(() {
                          _gender = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Sexe',
                        prefixIcon: Icon(Icons.person, color: AppColors.primaryBlue),
                      ),  
                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                      onSaved: (v) => _gender = v,
                      items: ['M', 'F'].map((String value) {
                          return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: TextStyle(color: AppColors.primaryBlue)),
                        );
                      }).toList(),
                      style: TextStyle(color: AppColors.primaryBlue),
                      dropdownColor: AppColors.white,
                      iconEnabledColor: AppColors.primaryBlue,
                      iconDisabledColor: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityController,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Ville',
                        prefixIcon: Icon(Icons.location_city, color: AppColors.primaryBlue),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _regionController,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Région',
                        prefixIcon: Icon(Icons.map, color: AppColors.primaryBlue),
                      ),
                    ),
                     Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          child: Text( "Utiliser ma position", style: TextStyle(color: AppColors.primaryBlue,fontWeight: FontWeight.bold,fontSize: 16),),
                        ),
                       
                        IconButton(
                          icon: const Icon(Icons.my_location),
                          onPressed: _detectLocation,
                          tooltip: "Détecter ma position",
                          
                        ),
                      ],
                    ),
                    if (_locationError != null)
                      Text(_locationError!, style: const TextStyle(color: Colors.red)),
                  ] else ...[
                    // Rien à afficher (city, region, contacts cachés)
                  ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.people, color: AppColors.primaryBlue, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Statistiques d\'audience',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Vous serez redirigé vers une page pour collecter les statistiques de votre audience WhatsApp',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    // GPS optionnel (à brancher sur une vraie géoloc si besoin)
                   // const SizedBox(height: 16),
                   
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                if (_role == 'ambassador') {
                                  _proceedToAudienceCollection();
                                } else {
                                  // Pour les annonceurs, enregistrer directement
                                  final registrationData = {
                                    'name': _name,
                                    'email': _email,
                                    'password': _password,
                                    'role': _role,
                                    'phone': _phoneController.text,
                                    'ageRange': _ageRange,
                                    'gender': _gender,
                                    'location': {
                                      'countryCode': _countryDialCode,
                                      'city': null,
                                      'region': null,
                                      'gps': {
                                        'lat': null,
                                        'lng': null
                                      }
                                    },
                                  };
                                  _register(registrationData);
                                }
                              }
                            },
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Créer un compte'),
                    ),
                  ),
                  if (_apiError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(_apiError!, style: const TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: widget.onLoginTap,
                    child: const Text('J’ai déjà un compte'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
