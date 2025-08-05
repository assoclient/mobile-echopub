import 'package:flutter/material.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CreateAdPage extends StatefulWidget {
  const CreateAdPage({Key? key}) : super(key: key);

  @override
  State<CreateAdPage> createState() => _CreateAdPageState();
}

class _CreateAdPageState extends State<CreateAdPage> {
  final _formKey = GlobalKey<FormState>();
  XFile? _mediaFile;
  String? _mediaType; // 'image' ou 'video'
  int? _budget=1000;
  double? _cpv=10;
  double? _cpc=20;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _locationType = 'city';
  List<String> _selectedLocations = [];
  List<Map<String, dynamic>> _cities = [];
  bool _loadingCities = true;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _targetLinkController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    final String data = await rootBundle.loadString('assets/cities_cm.json');
    final List<dynamic> jsonResult = json.decode(data);
    setState(() {
      _cities = jsonResult.map((e) => {
        'name': e['name'],
        'lat': e['lat'],
        'lng': e['lng'],
        'region': e['region'],
      }).toList();
      _loadingCities = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une annonce'),
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primaryBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                minLines: 3,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 12),
              // Upload image ou vidéo
              Text('Média (image ou vidéo)', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue,foregroundColor: Colors.white),
                      icon: const Icon(Icons.image,color: Colors.white,),
                      label: const Text('Image'),
                      onPressed: _mediaFile != null
                          ? null
                          : () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(source: ImageSource.gallery);
                              if (picked != null) {
                                setState(() {
                                  _mediaFile = picked;
                                  _mediaType = 'image';
                                });
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue,foregroundColor: Colors.white),
                      icon: const Icon(Icons.videocam,color: Colors.white,),
                      label: const Text('Vidéo'),
                      onPressed: _mediaFile != null
                          ? null
                          : () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickVideo(source: ImageSource.gallery);
                              if (picked != null) {
                                setState(() {
                                  _mediaFile = picked;
                                  _mediaType = 'video';
                                });
                              }
                            },
                    ),
                  ),
                  if (_mediaFile != null) ...[
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Supprimer le média',
                      onPressed: () {
                        setState(() {
                          _mediaFile = null;
                          _mediaType = null;
                        });
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (_mediaFile != null)
                _mediaType == 'image'
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(_mediaFile!.path), height: 160, fit: BoxFit.cover),
                      )
                    : AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          color: Colors.black12,
                          child: Center(
                            child: Text('Vidéo sélectionnée', style: TextStyle(color: Colors.blueGrey.shade700)),
                          ),
                        ),
                      ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _budget?.toString() ?? '',
                decoration: const InputDecoration(labelText: 'Budget (FCFA)', prefixIcon: Icon(Icons.monetization_on)),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ requis';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Entrez un montant valide';
                  return null;
                },
                onSaved: (v) => _budget = int.tryParse(v ?? ''),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _cpv?.toString() ?? '10' ,
                      decoration: const InputDecoration(labelText: 'CPV (min 10 FCFA)'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Champ requis';
                        final n = double.tryParse(v);
                        if (n == null || n < 10) return 'Min 10 FCFA';
                        return null;
                      },
                      onSaved: (v) => _cpv = double.tryParse(v ?? ''),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: _cpc?.toString() ?? '20',
                      decoration: const InputDecoration(labelText: 'CPC (min 20 FCFA)'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Champ requis';
                        final n = double.tryParse(v);
                        if (n == null || n < 20) return 'Min 20 FCFA';
                        return null;
                      },
                      onSaved: (v) => _cpc = double.tryParse(v ?? ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Date de début'),
                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          _startDateController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}' ;
                          _startDate = picked;
                        }
                      },
                      onSaved: (v) {
                        if (v != null && v.isNotEmpty) {
                          _startDate = DateTime.tryParse(v);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _endDateController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Date de fin'),
                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          _endDateController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}' ;
                          _endDate = picked;
                        }
                      },
                      onSaved: (v) {
                        if (v != null && v.isNotEmpty) {
                          _endDate = DateTime.tryParse(v);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Ciblage géographique', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _locationType,
                decoration: const InputDecoration(labelText: 'Type de ciblage'),
                items: const [
                  DropdownMenuItem(value: 'city', child: Text('Ville(s)')),
                  DropdownMenuItem(value: 'region', child: Text('Région(s)')),
                ],
                onChanged: (v) {
                  setState(() {
                    _locationType = v;
                    _selectedLocations.clear();
                  });
                },
                validator: (v) => v == null ? 'Champ requis' : null,
              ),
              const SizedBox(height: 8),
              _loadingCities
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sélectionnez ${_locationType == 'city' ? 'les villes' : 'les régions'} :'),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: SingleChildScrollView(
                            child: Wrap(
                              spacing: 8,
                              children: (_locationType == 'city'
                                  ? _cities.map((city) => city['name'] as String).toSet().toList()
                                  : _cities.map((city) => city['region'] as String).toSet().toList())
                                  .map((loc) => FilterChip(
                                        label: Text(loc),
                                        selected: _selectedLocations.contains(loc),
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedLocations.add(loc);
                                            } else {
                                              _selectedLocations.remove(loc);
                                            }
                                          });
                                        },
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                        if (_selectedLocations.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('Sélectionnez au moins une valeur.', style: TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
             /*  const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Rayon (Km à la ronde)'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                onSaved: (v) => _selectedRadius = v,
              ), */
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetLinkController,
                decoration: const InputDecoration(labelText: 'Lien cible'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ requis';
                  final urlPattern = r'^(https?:\/\/)?([\w\-]+\.)+[\w\-]+(\/.*)?$';
                  final regExp = RegExp(urlPattern);
                  if (!regExp.hasMatch(v)) return 'Entrez une URL valide (ex: https://...)';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Récupérer les valeurs des contrôleurs
                    final _title = _titleController.text;
                    final _description = _descriptionController.text;
                    final _targetLink = _targetLinkController.text;
                    _formKey.currentState!.save();
                    final storage = const FlutterSecureStorage();
                    final token = await storage.read(key: 'auth_token');
                    if (token == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non authentifié.')));
                      return;
                    }
                    var user =await  AuthService.getUser();
                    // Construction du body
                    final Map<String, dynamic> body = {
                      'advertiser': user?['_id'],
                      'title': _title,
                      'description': _description,
                      'target_link': _targetLink,
                      'cpv': _cpv,
                      'cpc': _cpc,
                      'start_date': _startDate?.toIso8601String(),
                      'end_date': _endDate?.toIso8601String(),
                      'budget': _budget,
                      'location_type': _locationType,
                      'target_location': _selectedLocations.map((loc) => {'value': loc}).toList(),
                    };

                    var request;
                    if (_mediaFile != null) {
                      // Envoi multipart si fichier
                      request = http.MultipartRequest('POST', Uri.parse('${dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000'}/api/campaigns'));
                      request.headers['Authorization'] = 'Bearer $token';
                      request.fields['data'] = json.encode(body);
                      request.files.add(await http.MultipartFile.fromPath('media', _mediaFile!.path));
                    } else {
                      // Envoi JSON simple
                      request = http.Request('POST', Uri.parse('${dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000'}/api/campaigns'));
                      request.headers['Authorization'] = 'Bearer $token';
                      request.headers['Content-Type'] = 'application/json';
                      request.body = json.encode(body);
                    }

                    // Envoi de la requête
                    final streamedResponse = await (request is http.MultipartRequest
                        ? request.send()
                        : (request as http.Request).send());
                    final response = await http.Response.fromStream(streamedResponse);

                    if (response.statusCode == 201 || response.statusCode == 200) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Annonce créée !')));
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: ${response.statusCode}\n${response.body}')),
                      );
                    }
                  }
                },
                child: const Text('Créer l\'annonce',style: TextStyle(color: Colors.white),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
