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

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _apiError = null;
    });
    
    final registrationData = {
      'name': _name,
      'email': _email,
      'password': _password,
      'role': _role,
      'phone': _role == 'advertiser' ? _phoneController.text : null,
      'whatsapp_number': _role == 'ambassador' ? _whatsappController.text : null,
      'contacts_count': _role == 'ambassador' ? _contactsController.text : null,
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

    // Si c'est un ambassadeur, naviguer vers la page de collecte d'audience
    if (_role == 'ambassador') {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AudienceCollectionPage(
            userCity: _cityController.text,
            userAgeRange: _ageRange,
            userGender: _gender,
            registrationData: registrationData,
          ),
        ),
      );
      
      if (result != null) {
        // Procéder à l'inscription avec les données d'audience
        await _performRegistration(result);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      // Pour les annonceurs, procéder directement à l'inscription
      await _performRegistration(registrationData);
    }
  }

  Future<void> _performRegistration(Map<String, dynamic> data) async {
    final url = Uri.parse('${dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000'}/api/auth/register');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
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

  final _formKey = GlobalKey<FormState>();
  String? _name, _email, _password;
  String _role = 'ambassador';
  String _ageRange = '18-25';
  String _gender = 'M';

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _contactsController = TextEditingController();
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
          _regionController.text = place.administrativeArea ?? '';
          _countryDialCode = getDialCodeFromCountry(place.isoCountryCode);
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Nombre de vue moyenne sur whatsapp',
                        prefixIcon: Icon(Icons.people, color: AppColors.primaryBlue),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _ageRange,
                      decoration: InputDecoration(
                        labelText: 'Tranche d\'âge',
                        prefixIcon: Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                      ),
                      items: const [
                        DropdownMenuItem(value: '18-25', child: Text('18-25 ans')),
                        DropdownMenuItem(value: '26-35', child: Text('26-35 ans')),
                        DropdownMenuItem(value: '36-45', child: Text('36-45 ans')),
                        DropdownMenuItem(value: '46-55', child: Text('46-55 ans')),
                        DropdownMenuItem(value: '56+', child: Text('56+ ans')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _ageRange = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: InputDecoration(
                        labelText: 'Genre',
                        prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryBlue),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'M', child: Text('Masculin')),
                        DropdownMenuItem(value: 'F', child: Text('Féminin')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _gender = value;
                          });
                        }
                      },
                    ),
                    // GPS optionnel (à brancher sur une vraie géoloc si besoin)
                   // const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(_lat != null ? "Lat: $_lat" : "Lat: -"),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_lng != null ? "Lon: $_lng" : "Lon: -"),
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                _register();
                              }
                            },
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Continuer >>'),
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
