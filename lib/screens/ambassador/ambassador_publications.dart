import '../../components/ambassador_bottom_nav.dart';
import 'ambassador_nav_helper.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../theme.dart';
import 'package:exif/exif.dart';
import '../../widgets/screenshot_capture_widget.dart';
import '../../plugins/screenshot_service.dart';

class AmbassadorPublicationsPage extends StatefulWidget {
  const AmbassadorPublicationsPage({Key? key}) : super(key: key);

  @override
  State<AmbassadorPublicationsPage> createState() => _AmbassadorPublicationsPageState();
}

class _AmbassadorPublicationsPageState extends State<AmbassadorPublicationsPage> {
  List<Map<String, dynamic>> _publications = [];
  bool _isLoading = true;
  String? _error;
  String _search = '';
  DateTime? _dateStart;
  DateTime? _dateEnd;
  int _currentPage = 1;
  int _totalCount = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadPublications();
  }

  Future<void> _loadPublications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _publications.clear();
        _currentPage = 1;
        _hasMore = true;
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
      final url = Uri.parse('$apiUrl/api/ambassador-publications/my-publications?page=$_currentPage&pageSize=10');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> publications = data['data'] ?? [];
        
        setState(() {
          _isLoading = false;
          _totalCount = data['totalCount'] ?? 0;
          _hasMore = publications.length >= 10; // Si on a reçu 10 éléments, il y en a peut-être plus
          
          // Convertir les données du backend au format attendu par l'UI
          final convertedPublications = publications.map<Map<String, dynamic>>((pub) {
            return {
              'id': pub['_id'], // ID de l'AmbassadorCampaign
              'campaignId': pub['campaign']?['_id'], // ID de la campagne
              'title': pub['campaign']?['title'] ?? 'Campagne sans titre',
              'date': pub['createdAt'] != null ? DateTime.tryParse(pub['createdAt']) ?? DateTime.now() : DateTime.now(),
              'status': _getStatusText(pub['status']),
              'validation': _getValidationText(pub['status']),
              'views': pub['views_count'] ?? 0,
              'gain': pub['amount_earned'] ?? 0,
              'capture1': pub['screenshot_url'],
              'capture2': pub['screenshot_url2'],
              'originalStatus': pub['status'], // Garder le statut original pour référence
            };
          }).toList();
          
          if (refresh) {
            _publications = convertedPublications;
          } else {
            _publications.addAll(convertedPublications);
          }
          
          _currentPage++;
        });
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'published':
        return 'Publié';
      case 'submitted':
        return 'Soumis';
      case 'validated':
        return 'Publié';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  String _getValidationText(String? status) {
    switch (status) {
      case 'published':
        return 'Publié';
      case 'submitted':
        return 'En cours de validation';
      case 'validated':
        return 'Validée';
      case 'rejected':
        return 'Refusée';
      default:
        return 'En attente';
    }
  }

  Future<void> _pickCapture(int index, int captureNum) async {
    final pub = _publications[index];
    debugPrint('pub: $pub');
    
    // Vérifier les conditions pour le remplacement de la première preuve
    if (captureNum == 1 && pub['capture2'] != null && pub['capture2'].isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Impossible de remplacer la première preuve : la deuxième preuve a déjà été soumise'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
      return;
    }

    // Afficher le choix entre capture automatique et galerie
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${captureNum == 1 ? "Première" : "Deuxième"} preuve'),
        content: const Text('Comment voulez-vous obtenir la capture d\'écran ?'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'auto'),
            icon: const Icon(Icons.camera_alt),
            label: Text(Platform.isAndroid 
                ? 'Capture automatique' 
                : 'Détecter capture'),
          ),
          /* TextButton.icon(
            onPressed: () => Navigator.pop(context, 'gallery'),
            icon: const Icon(Icons.photo_library),
            label: const Text('Galerie'),
          ), */
        ],
      ),
    );

    if (choice == null) return;

    if (choice == 'auto') {
      // Utiliser le nouveau système de capture automatique
      _showScreenshotCaptureDialog(pub, captureNum);
    } else {
      // Utiliser l'ancienne méthode de galerie
      _pickFromGallery(pub, captureNum);
    }
  }

  void _showScreenshotCaptureDialog(Map<String, dynamic> pub, int captureNum) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ScreenshotCaptureWidget(
          campaignId: pub['campaignId'] ?? '',
          campaignTitle: pub['title'] ?? 'Campagne',
          onScreenshotCaptured: (imagePath) async {
            // Fermer le dialog de capture manuellement pour contrôler l'affichage
            if (mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            // Uploader et afficher le résultat
            await _uploadCapturedScreenshot(pub, imagePath, captureNum);
          },
          onTimeout: () {
            if (mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Timeout atteint - Veuillez recommencer'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            }
          },
          onError: () {
            if (mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Erreur lors de la capture - Essayez la galerie'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _pickFromGallery(Map<String, dynamic> pub, int captureNum) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    
    if (picked == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune image sélectionnée.')),
        );
      }
      return;
    }

    final imageFile = File(picked.path);
    
    // Confirmation avant upload
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer le remplacement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Voulez-vous remplacer la ${captureNum == 1 ? "première" : "deuxième"} preuve pour cette campagne ?'),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Remplacer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _uploadReplacementProof(pub, imageFile, captureNum);
    }
  }

  Future<void> _uploadCapturedScreenshot(Map<String, dynamic> pub, String imagePath, int captureNum) async {
    final imageFile = File(imagePath);
    
    // Confirmation avant upload
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la capture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Voulez-vous utiliser cette capture comme ${captureNum == 1 ? "première" : "deuxième"} preuve ?'),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Refuser'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _uploadReplacementProof(pub, imageFile, captureNum);
    }
  }

  Future<void> _uploadReplacementProof(Map<String, dynamic> pub, File imageFile, int captureNum) async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
      Uri uri;
      
      // Choisir l'endpoint en fonction du numéro de capture
      if (captureNum == 1) {
        // Pour la première preuve, utiliser l'ID de campagne
        final campaignId = pub['campaignId']; // L'ID de la campagne
        if (campaignId == null) {
          throw Exception('ID de campagne manquant');
        }
        uri = Uri.parse('$apiUrl/api/upload/screenshot/$campaignId');
      } else {
        // Pour la deuxième preuve, utiliser l'ID de l'AmbassadorCampaign
        final ambassadorCampaignId = pub['id']; // L'ID de l'AmbassadorCampaign
        uri = Uri.parse('$apiUrl/api/upload/screenshot2/$ambassadorCampaignId');
      }

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      
      // Ajouter le fichier
      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      );
      request.files.add(multipartFile);

      // Afficher l'indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: AppColors.primaryBlue),
              const SizedBox(width: 20),
              const Text('Upload en cours...'),
            ],
          ),
        ),
      );

      // Envoyer la requête
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

            // Fermer le dialog de chargement
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Preuve remplacée avec succès !'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
        
        // Recharger les publications pour mettre à jour l'affichage
        _loadPublications(refresh: true);
        
        // Retourner à l'app après un délai pour que l'utilisateur voie le message
        Future.delayed(const Duration(seconds: 2), () {
          ScreenshotService.returnToApp();
        });
        
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Erreur lors du remplacement';
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    } catch (e) {
      // Fermer le dialog de chargement en cas d'erreur
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _loadMorePublications() async {
    if (!_hasMore || _isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    await _loadPublications();
  }

  @override
  Widget build(BuildContext context) {
    // Filtrage
    final filtered = _publications.where((pub) {
      final matchSearch = _search.isEmpty || pub['title'].toLowerCase().contains(_search.toLowerCase());
      final matchDate = (_dateStart == null && _dateEnd == null)
        || (_dateStart != null && _dateEnd == null && pub['date'].isAfter(_dateStart!.subtract(const Duration(days: 1))))
        || (_dateStart == null && _dateEnd != null && pub['date'].isBefore(_dateEnd!.add(const Duration(days: 1))))
        || (_dateStart != null && _dateEnd != null &&
            !pub['date'].isBefore(_dateStart!) && !pub['date'].isAfter(_dateEnd!));
      return matchSearch && matchDate;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mes publications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadPublications(refresh: true),
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher par titre...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: Icon(Icons.search, color: AppColors.primaryBlue, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w500),
                    cursorColor: AppColors.primaryBlue,
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(height: 16),
                // Date Filters
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.date_range, size: 18, color: AppColors.primaryBlue),
                          label: Text(
                            _dateStart == null ? 'Début' : '${_dateStart!.day}/${_dateStart!.month}/${_dateStart!.year}',
                            style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w500),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dateStart ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) setState(() => _dateStart = picked);
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(40, 44),
                            foregroundColor: AppColors.primaryBlue,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.date_range, size: 18, color: AppColors.primaryBlue),
                          label: Text(
                            _dateEnd == null ? 'Fin' : '${_dateEnd!.day}/${_dateEnd!.month}/${_dateEnd!.year}',
                            style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w500),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dateEnd ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) setState(() => _dateEnd = picked);
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(40, 44),
                            foregroundColor: AppColors.primaryBlue,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    if (_dateStart != null || _dateEnd != null)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          tooltip: 'Réinitialiser dates',
                          color: AppColors.primaryBlue,
                          onPressed: () => setState(() {
                            _dateStart = null;
                            _dateEnd = null;
                          }),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading && _publications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primaryBlue),
                        const SizedBox(height: 16),
                        Text(
                          'Chargement des publications...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : _error != null && _publications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Erreur lors du chargement',
                              style: const TextStyle(color: Colors.red, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadPublications(refresh: true),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.article_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _publications.isEmpty 
                                    ? 'Aucune publication trouvée'
                                    : 'Aucune publication ne correspond aux filtres',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_publications.isEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Commencez à publier des campagnes pour les voir ici !',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification scrollInfo) {
                              if (!_isLoading &&
                                  _hasMore &&
                                  scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                                _loadMorePublications();
                              }
                              return false;
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filtered.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, i) {
                                // Si c'est le dernier élément et qu'on a plus de données à charger
                                if (i >= filtered.length) {
                                  return Container(
                                    padding: const EdgeInsets.all(20),
                                    child: Center(
                                      child: CircularProgressIndicator(color: AppColors.primaryBlue),
                                    ),
                                  );
                                }
                                
                                final pub = filtered[i];
                                return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                  // Header with title
                                  Text(
                                    pub['title'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: Colors.black87,
                                    ),
                                  ),
                              const SizedBox(height: 12),
                              // Status and date
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${pub['date'].day}/${pub['date'].month}/${pub['date'].year}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: pub['validation'] == 'Validée'
                                          ? Colors.green.shade50
                                          : pub['validation'] == 'Refusée'
                                              ? Colors.red.shade50
                                              : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: pub['validation'] == 'Validée'
                                            ? Colors.green.shade200
                                            : pub['validation'] == 'Refusée'
                                                ? Colors.red.shade200
                                                : Colors.orange.shade200,
                                      ),
                                    ),
                                    child: Text(
                                      pub['validation'] ?? 'En attente',
                                      style: TextStyle(
                                        color: pub['validation'] == 'Validée'
                                            ? Colors.green.shade700
                                            : pub['validation'] == 'Refusée'
                                                ? Colors.red.shade700
                                                : Colors.orange.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Stats for validated publications
                              if (pub['validation'] == 'Validée') ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(Icons.remove_red_eye, size: 18, color: Colors.blue.shade700),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${pub['views'] ?? 0} vues',
                                              style: TextStyle(
                                                color: Colors.blue.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(Icons.monetization_on, size: 18, color: Colors.green.shade700),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${pub['gain'] ?? 0} FCFA',
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              // Proof images section
                              Text(
                                'Preuves de publication',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildProofSection(
                                      title: 'Preuve 1',
                                      imageUrl: pub['capture1'],
                                      onTap: () => _pickCapture(i, 1),
                                      isInitial: true,
                                      isUploading: !(pub['capture2'] != null && pub['capture2'].isNotEmpty),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildProofSection(
                                      title: 'Preuve 2',
                                      imageUrl: pub['capture2'],
                                      onTap: () => _pickCapture(i, 2),
                                      isInitial: false,
                                      isUploading: (pub['capture1'] != null && pub['capture1'].isNotEmpty)&&(pub['originalStatus'] == 'published'||pub['originalStatus'] == 'submitted'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                              },
                            ),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: AmbassadorBottomNav(
        currentIndex: 1,
        onTap: (index) => handleAmbassadorNav(context, 1, index),
      ),
    );
  }

  Widget _buildProofSection({
    required String title,
    required String? imageUrl,
    required VoidCallback onTap,
    required bool isInitial,
    bool isUploading = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          if (imageUrl != null && imageUrl.isNotEmpty)
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.startsWith('http') 
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.broken_image, color: Colors.grey[400], size: 32),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                    )
                  : Image.network(
                      '${dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000'}$imageUrl',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.broken_image, color: Colors.grey[400], size: 32),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                    ),
              ),
            )
          else
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.image_outlined,
                color: Colors.grey[400],
                size: 32,
              ),
            ),
          const SizedBox(height: 8),
          if(isUploading)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(
                imageUrl != null ? Icons.refresh : Icons.camera_alt,
                size: 16,
              ),
              label: Text(
                imageUrl != null ? 'Remplacer' : 'Ajouter',
                style: const TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: BorderSide(color: AppColors.primaryBlue.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
