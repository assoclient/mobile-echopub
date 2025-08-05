import 'package:flutter/material.dart';
import 'package:mobile/theme.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
class EditAdPage extends StatefulWidget {
  final Map<String, dynamic> ad;
  const EditAdPage({Key? key, required this.ad}) : super(key: key);

  @override
  State<EditAdPage> createState() => _EditAdPageState();
}

class _EditAdPageState extends State<EditAdPage> {
  XFile? _pickedMedia;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _targetLinkController;
  late TextEditingController _budgetController;
  late TextEditingController _cpvController;
  late TextEditingController _cpcController;
  late TextEditingController _cityController;
  late TextEditingController _regionController;
  late TextEditingController _radiusController;
  String? _targetType; // 'city', 'region', 'radius'
  String? _format; // 'image', 'video', 'texte'
  DateTime? _startDate;
  DateTime? _endDate;
  String? _mediaUrl;
List<Map<String, dynamic>> _cities = [];
  bool _loadingCities = true;
  @override
  void initState() {
    super.initState();
    _loadCities();
    final ad = widget.ad;
    _titleController = TextEditingController(text: ad['title'] ?? '');
    _descriptionController = TextEditingController(text: ad['description'] ?? '');
    _targetLinkController = TextEditingController(text: ad['target_link'] ?? '');
    _budgetController = TextEditingController(text: ad['budget']?.toString() ?? '');
    _cpvController = TextEditingController(text: ad['cpv']?.toString() ?? '');
    _cpcController = TextEditingController(text: ad['cpc']?.toString() ?? '');
    _cityController = TextEditingController(
      text: (ad['target_location'] != null && ad['target_location']['city'] != null)
          ? ad['target_location']['city']?.toString() ?? ''
          : '',
    );
    _regionController = TextEditingController(
      text: (ad['target_location'] != null && ad['target_location']['region'] != null)
          ? ad['target_location']['region']?.toString() ?? ''
          : '',
    );
    _radiusController = TextEditingController(
      text: (ad['target_location'] != null && ad['target_location']['type'] == 'radius')
          ? (ad['target_location']['value'] != null ? ad['target_location']['value'].toString() : '')
          : '',
    );
    _targetType = ad['target_location']?['type'] ?? 'city';
    _format = ad['format'] ?? 'image';
    _startDate = ad['start_date'] is DateTime
        ? ad['start_date']
        : (ad['start_date'] != null ? DateTime.tryParse(ad['start_date'].toString()) : null);
    _endDate = ad['end_date'] is DateTime
        ? ad['end_date']
        : (ad['end_date'] != null ? DateTime.tryParse(ad['end_date'].toString()) : null);
    _mediaUrl = ad['media_url']?.toString();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetLinkController.dispose();
    _budgetController.dispose();
    _cpvController.dispose();
    _cpcController.dispose();
    _cityController.dispose();
    _regionController.dispose();
    //_radiusController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
      final url = Uri.parse('$apiUrl/api/campaigns/${widget.ad['_id']}');

      http.Response response;
      if (_pickedMedia != null) {
        // Envoi multipart si un nouveau média est choisi
        var request = http.MultipartRequest('PUT', url);
        request.headers['Authorization'] = 'Bearer $token';
        request.fields['title'] = _titleController.text;
        request.fields['description'] = _descriptionController.text;
        request.fields['target_link'] = _targetLinkController.text;
        request.fields['budget'] = _budgetController.text;
        if (_cpvController.text.isNotEmpty) request.fields['cpv'] = _cpvController.text;
        if (_cpcController.text.isNotEmpty) request.fields['cpc'] = _cpcController.text;
        request.fields['format'] = _format ?? '';
        if (_startDate != null) request.fields['start_date'] = _startDate!.toIso8601String();
        if (_endDate != null) request.fields['end_date'] = _endDate!.toIso8601String();
        request.fields['target_location'] = json.encode({
          'city': _cityController.text,
          'region': _regionController.text,
        });
        request.files.add(await http.MultipartFile.fromPath('media', _pickedMedia!.path));
        var streamed = await request.send();
        response = await http.Response.fromStream(streamed);
        if (response.statusCode == 200) {
          final resp = json.decode(response.body);
          setState(() {
            _mediaUrl = resp['media_url'] ?? _mediaUrl;
          });
        }
      } else {
        // Sinon, envoi JSON classique
        final Map<String, dynamic> data = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'target_link': _targetLinkController.text,
          'budget': int.tryParse(_budgetController.text) ?? 0,
          'cpv': int.tryParse(_cpvController.text) ?? null,
          'cpc': int.tryParse(_cpcController.text) ?? null,
          'format': _format,
          'start_date': _startDate?.toIso8601String(),
          'end_date': _endDate?.toIso8601String(),
          'media_url': _mediaUrl,
          'target_location': {
            'city':  _cityController.text,
            'region': _regionController.text,
          },
        };
        final body = json.encode(data);
        response = await http.put(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: body,
        );
      }
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Annonce modifiée.')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
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
        title: const Text('Modifier l\'annonce'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
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
                minLines: 3,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _budgetController,
                      decoration: const InputDecoration(labelText: 'Budget (FCFA)', prefixIcon: Icon(Icons.monetization_on)),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Champ requis';
                        final n = int.tryParse(v);
                        if (n == null || n <= 0) return 'Entrez un montant valide';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _cpvController,
                      decoration: const InputDecoration(labelText: 'CPV (FCFA)'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (_cpcController.text.isEmpty && (v == null || v.isEmpty)) return 'CPV ou CPC requis';
                        if (v != null && v.isNotEmpty && int.tryParse(v)! < 10) return 'Min 10 FCFA';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _cpcController,
                      decoration: const InputDecoration(labelText: 'CPC (FCFA)'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (_cpvController.text.isEmpty && (v == null || v.isEmpty)) return 'CPV ou CPC requis';
                        if (v != null && v.isNotEmpty && int.tryParse(v)! < 20) return 'Min 20 FCFA';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _format,
                decoration: const InputDecoration(labelText: 'Format'),
                items: const [
                  DropdownMenuItem(value: 'image', child: Text('Image')),
                  DropdownMenuItem(value: 'video', child: Text('Vidéo')),
                  DropdownMenuItem(value: 'texte', child: Text('Texte')),
                ],
                onChanged: (v) => setState(() => _format = v),
                validator: (v) => v == null ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child:_loadingCities
                  ? const Center(child: CircularProgressIndicator())
                  : Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<String>.empty();
                        }
                      // Remplacer par la liste des villes de ton projet
                      final cityNames = _cities.map((city) => city['name'] as String).toList();
                      return cityNames.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        controller.text = _cityController.text;
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(labelText: 'Ville'),
                          enabled: true,
                          validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                          onChanged: (v) {
                            debugPrint('Ville sélectionnée: $v');
                            final match = _cities.firstWhere(
                              (city) => (city['name'] as String).toLowerCase() == (v ?? '').toLowerCase(),
                              orElse: () => {},
                            );
                            debugPrint('Match trouvé: $match');
                            if (match.isNotEmpty) {
                              _cityController.text = v ?? '';
                              _regionController.text = match['region'] ?? '';
                            } else {
                              _cityController.text = '';
                              _regionController.text = '';
                            }
                          },
                        );
                      },
                      onSelected: (String selection) {
                        setState(() {
                          _cityController.text = selection;
                          // Optionnel : auto-remplir la région si la ville est sélectionnée
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _regionController,
                      decoration: const InputDecoration(labelText: 'Région'),
                      enabled: false, // La région est auto-remplie
                      validator: (v) => _targetType == 'region' && (v == null || v.isEmpty) ? 'Champ requis' : null,
                    ),
                  ),
                 /*  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _radiusController,
                      decoration: const InputDecoration(labelText: 'Rayon (km)'),
                      enabled: true,
                      keyboardType: TextInputType.number,
                      validator: (v) => _targetType == 'radius' && (v == null || v.isEmpty) ? 'Champ requis' : null,
                    ),
                  ), */
                ],
              ),
              const SizedBox(height: 8),
             /*  DropdownButtonFormField<String>(
                value: _targetType,
                decoration: const InputDecoration(labelText: 'Type de ciblage'),
                items: const [
                  DropdownMenuItem(value: 'city', child: Text('Ville')),
                  DropdownMenuItem(value: 'region', child: Text('Région')),
                  DropdownMenuItem(value: 'radius', child: Text('Rayon GPS (km)')),
                ],
                onChanged: (v) => setState(() => _targetType = v),
                validator: (v) => v == null ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12), */
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _startDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Date de début'),
                        child: Text(_startDate != null ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}' : 'Choisir'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final DateTime minDate = _startDate ?? DateTime.now();
                        final DateTime initial = (_endDate != null && !_endDate!.isBefore(minDate)) ? _endDate! : minDate;
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: minDate,
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _endDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Date de fin'),
                        child: Text(_endDate != null ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}' : 'Choisir'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_pickedMedia != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nouveau média sélectionné :', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    _format == 'image'
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_pickedMedia!.path),
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          )
                        : _format == 'video'
                            ? Container(
                                height: 120,
                                color: Colors.black12,
                                child: Center(child: Text('Vidéo: ${_pickedMedia!.name}')),
                              )
                            : const SizedBox.shrink(),
                  ],
                )
              else if (_mediaUrl != null && _mediaUrl!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Média actuel :', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    _format == 'image'
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(_mediaUrl!, height: 120, fit: BoxFit.cover),
                          )
                        : _format == 'video'
                            ? Container(
                                height: 120,
                                color: Colors.black12,
                                child: Center(child: Text('Vidéo: $_mediaUrl')),
                              )
                            : const SizedBox.shrink(),
                  ],
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Changer le média'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black),
                    onPressed: () async {
                      final source = _format == 'image' ? ImageSource.gallery : ImageSource.gallery;
                      final picked = await _picker.pickImage(
                        source: source,
                        imageQuality: 90,
                        maxWidth: 1200,
                        maxHeight: 1200,
                      );
                      if (picked != null) {
                        setState(() {
                          _pickedMedia = picked;
                        });
                      }
                    },
                  ),
                  if (_pickedMedia != null)
                    TextButton(
                      onPressed: () => setState(() => _pickedMedia = null),
                      child: const Text('Annuler', style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue,foregroundColor: Colors.white  ),
                onPressed: _submit,
                child: const Text('Enregistrer les modifications'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
