import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../../theme.dart';
import '../../components/ambassador_bottom_nav.dart';
import 'ambassador_publications.dart';
import 'ambassador_gains.dart';
import 'ambassador_profil.dart';

class AmbassadorHome extends StatefulWidget {
  const AmbassadorHome({Key? key}) : super(key: key);

  @override
  State<AmbassadorHome> createState() => _AmbassadorHomeState();
}

class _AmbassadorHomeState extends State<AmbassadorHome> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  List<Map<String, dynamic>> _campaigns = [];
  final Map<int, VideoPlayerController> _videoControllers = {};

  // Supprimé _pendingProof car maintenant on upload directement

  // États pour l'upload
  final Map<String, bool> _uploadingProofs = {};
  final Map<String, String?> _uploadErrors = {};

  int _bottomNavIndex = 0;
  String _search = '';
  
  // Pagination
  int _currentPage = 1;
  int _pageSize = 10;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  
  // Recherche avec debounce
  Timer? _searchDebounce;
  String _lastSearchQuery = '';

  // Debug flag - Set to false to use real API, true for test data
  static const bool is_debug = false;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
    _setupScrollListener();
  }
  
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore && _hasMoreData) {
          _loadMoreCampaigns();
        }
      }
    });
  }
  
  void _onSearchChanged(String query) {
    _search = query;
    
    // Annuler le timer précédent
    _searchDebounce?.cancel();
    
    // Démarrer un nouveau timer
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (_search != _lastSearchQuery) {
        _lastSearchQuery = _search;
        _resetPagination();
        _loadCampaigns();
      }
    });
  }
  
  void _resetPagination() {
    setState(() {
      _currentPage = 1;
      _campaigns.clear();
      _hasMoreData = true;
    });
  }
  
  Future<void> _loadMoreCampaigns() async {
    if (_isLoadingMore || !_hasMoreData) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      if (is_debug) {
        await _loadMoreDefaultCampaigns();
      } else {
        await _fetchMoreCampaignsFromAPI();
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de plus de campagnes: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _uploadProof(String campaignId, File imageFile) async {
    setState(() {
      _uploadingProofs[campaignId] = true;
      _uploadErrors[campaignId] = null;
    });

    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
      final uri = Uri.parse('$apiUrl/api/upload/screenshot/$campaignId');

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      
      // Ajouter le fichier
      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      );
      request.files.add(multipartFile);

      // Envoyer la requête
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Preuve uploadée avec succès !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        
        // Recharger les campagnes pour mettre à jour les statuts
        Navigator.push(context, MaterialPageRoute(builder: (context) => AmbassadorPublicationsPage()));
        
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Erreur lors de l\'upload';
        
        setState(() {
          _uploadErrors[campaignId] = errorMessage;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      final errorMessage = 'Erreur de connexion: $e';
      setState(() {
        _uploadErrors[campaignId] = errorMessage;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      setState(() {
        _uploadingProofs[campaignId] = false;
      });
    }
  }

  Future<void> _loadCampaigns() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (is_debug) {
      await _loadDefaultCampaigns();
    } else {
      await _fetchCampaignsFromAPI();
    }
  }

  Future<void> _loadDefaultCampaigns() async {
    // Simulate loading delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Default sample data
    final defaultCampaigns = [
      {
        'id': '1',
        'title': 'Campagne Pizza Hut - Nouveau Menu',
        'description': 'Découvrez notre nouveau menu avec des pizzas exclusives. Partagez cette offre et gagnez de l\'argent !',
        'media_url': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80',
        'target_link': 'https://pizzahut.com/nouveau-menu',
        'expected_views': 500,
        'expected_earnings': 2500,
        'cpv': 5.0,
        'start_date': DateTime.now().subtract(const Duration(days: 5)),
        'end_date': DateTime.now().add(const Duration(days: 10)),
        'location_type': 'city',
        'target_location': [
          {'value': 'Abidjan'},
          {'value': 'Yamoussoukro'}
        ],
        'advertiser': {
          'name': 'Pizza Hut Côte d\'Ivoire',
          'logo': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=400&q=80'
        }
      },
      {
        'id': '2',
        'title': 'Offre Orange Money - Transfert Gratuit',
        'description': 'Envoyez de l\'argent gratuitement avec Orange Money. Partagez cette offre et gagnez des commissions !',
        'media_url': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=400&q=80',
        'target_link': 'https://orange-money.ci/transfert-gratuit',
        'expected_views': 300,
        'expected_earnings': 1500,
        'cpv': 5.0,
        'start_date': DateTime.now().subtract(const Duration(days: 3)),
        'end_date': DateTime.now().add(const Duration(days: 7)),
        'location_type': 'city',
        'target_location': [
          {'value': 'Abidjan'},
          {'value': 'Bouaké'}
        ],
        'advertiser': {
          'name': 'Orange Money',
          'logo': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=400&q=80'
        }
      },
      {
        'id': '3',
        'title': 'Promotion MTN - Forfaits 4G',
        'description': 'Découvrez nos nouveaux forfaits 4G illimités. Partagez et gagnez de l\'argent !',
        'media_url': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=400&q=80',
        'target_link': 'https://mtn.ci/forfaits-4g',
        'expected_views': 400,
        'expected_earnings': 2000,
        'cpv': 5.0,
        'start_date': DateTime.now().subtract(const Duration(days: 1)),
        'end_date': DateTime.now().add(const Duration(days: 15)),
        'location_type': 'city',
        'target_location': [
          {'value': 'Abidjan'},
          {'value': 'San-Pédro'}
        ],
        'advertiser': {
          'name': 'MTN Côte d\'Ivoire',
          'logo': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=400&q=80'
        }
      },
      {
        'id': '4',
        'title': 'Nouveau Restaurant - Saveurs Locales',
        'description': 'Découvrez notre restaurant avec des saveurs locales authentiques. Partagez et gagnez !',
        'media_url': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80',
        'target_link': 'https://saveurs-locales.ci',
        'expected_views': 200,
        'expected_earnings': 1000,
        'cpv': 5.0,
        'start_date': DateTime.now().subtract(const Duration(days: 2)),
        'end_date': DateTime.now().add(const Duration(days: 20)),
        'location_type': 'city',
        'target_location': [
          {'value': 'Abidjan'}
        ],
        'advertiser': {
          'name': 'Saveurs Locales',
          'logo': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=400&q=80'
        }
      }
    ];

    setState(() {
      _isLoading = false;
      _campaigns = defaultCampaigns;
    });
  }
  
  Future<void> _loadMoreDefaultCampaigns() async {
    // Simuler un délai de chargement
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Données supplémentaires pour la pagination (simulation)
    final moreCampaigns = [
      {
        'id': '5',
        'title': 'Campagne Supplémentaire 1',
        'description': 'Description de la campagne supplémentaire pour tester la pagination.',
        'media_url': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80',
        'target_link': 'https://example.com/campaign1',
        'expected_views': 150,
        'expected_earnings': 750,
        'cpv': 5.0,
        'start_date': DateTime.now().subtract(const Duration(days: 1)),
        'end_date': DateTime.now().add(const Duration(days: 5)),
        'location_type': 'city',
        'target_location': [{'value': 'Abidjan'}],
        'advertiser': {
          'name': 'Entreprise Test 1',
          'logo': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=400&q=80'
        }
      },
      {
        'id': '6',
        'title': 'Campagne Supplémentaire 2',
        'description': 'Autre campagne pour tester la pagination et le scroll infini.',
        'media_url': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=400&q=80',
        'target_link': 'https://example.com/campaign2',
        'expected_views': 200,
        'expected_earnings': 1000,
        'cpv': 5.0,
        'start_date': DateTime.now(),
        'end_date': DateTime.now().add(const Duration(days: 8)),
        'location_type': 'city',
        'target_location': [{'value': 'Yamoussoukro'}],
        'advertiser': {
          'name': 'Entreprise Test 2',
          'logo': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=400&q=80'
        }
      }
    ];
    
    setState(() {
      _campaigns.addAll(moreCampaigns);
      _currentPage++;
      // Simuler qu'il n'y a plus de données après la page 2
      if (_currentPage >= 2) {
        _hasMoreData = false;
      }
    });
  }

  Future<void> _fetchCampaignsFromAPI() async {
    try {
      // Récupérer l'ID ambassadeur et le token
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      // Remplacer par la vraie méthode si tu utilises AuthService
      final user = await AuthService.getUser();
      final ambassadorId = user?['_id'];
      if (ambassadorId == null) throw Exception('Utilisateur non connecté');
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
      final url = Uri.parse('$apiUrl/api/ambassador-campaigns/active-campaigns/?page=$_currentPage&limit=$_pageSize&search=$_search');
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> dataList;
        if (decoded is Map && decoded.containsKey('data')) {
          debugPrint('dataList: $decoded');
          dataList = decoded['data'] as List<dynamic>;
        } else if (decoded is List) {
          dataList = decoded;
        } else {
          throw Exception('Format de réponse inattendu: ${response.body}');
        }
        setState(() {
          _isLoading = false;
          
          _campaigns = dataList.map<Map<String, dynamic>>((e) {
            // Conversion des dates si besoin
            return {
              ...e,
              'start_date': e['start_date'] != null ? DateTime.tryParse(e['start_date']) : null,
              'end_date': e['end_date'] != null ? DateTime.tryParse(e['end_date']) : null,
            };
          }).toList();
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Erreur serveur: ${response.statusCode}';
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des campagnes: $e');
      setState(() {
        _isLoading = false;
        _error = 'Erreur réseau ou parsing: $e';
      });
    }
  }
  
  Future<void> _fetchMoreCampaignsFromAPI() async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final user = await AuthService.getUser();
      final ambassadorId = user?['_id'];
      
      if (ambassadorId == null) throw Exception('Utilisateur non connecté');
      
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
      final url = Uri.parse('$apiUrl/api/ambassador-campaigns/active-campaigns/?page=${_currentPage + 1}&limit=$_pageSize&search=$_search');
      
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> dataList;
        
        if (decoded is Map && decoded.containsKey('data')) {
          dataList = decoded['data'] as List<dynamic>;
        } else if (decoded is List) {
          dataList = decoded;
        } else {
          throw Exception('Format de réponse inattendu: ${response.body}');
        }
        
        if (dataList.isNotEmpty) {
          final newCampaigns = dataList.map<Map<String, dynamic>>((e) {
            return {
              ...e,
              'start_date': e['start_date'] != null ? DateTime.tryParse(e['start_date']) : null,
              'end_date': e['end_date'] != null ? DateTime.tryParse(e['end_date']) : null,
            };
          }).toList();
          
          setState(() {
            _campaigns.addAll(newCampaigns);
            _currentPage++;
            _hasMoreData = dataList.length >= _pageSize;
          });
        } else {
          setState(() {
            _hasMoreData = false;
          });
        }
      } else {
        debugPrint('Erreur API lors du chargement de plus de campagnes: ${response.statusCode}');
        setState(() {
          _hasMoreData = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de plus de campagnes: $e');
      setState(() {
        _hasMoreData = false;
      });
    }
  }

  Future<VideoPlayerController> _getVideoController(int index, String url) async {
    if (_videoControllers[index] != null) return _videoControllers[index]!;
    final controller = VideoPlayerController.network(url);
    await controller.initialize();
    _videoControllers[index] = controller;
    return controller;
  }
  
  Widget _buildLoadingIndicator() {
    if (!_hasMoreData) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Aucune autre campagne disponible',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chargement de plus de campagnes...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyWidget;
    if (_isLoading) {
      bodyWidget = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryBlue),
            const SizedBox(height: 16),
            Text(
              'Chargement des campagnes...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    } else if (_error != null) {
      bodyWidget = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCampaigns,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    } else {
      final filteredCampaigns = _campaigns.where((c) {
        final query = _search.trim().toLowerCase();
        if (query.isEmpty) return true;
        return (c['title']?.toString().toLowerCase().contains(query) ?? false) ||
               (c['description']?.toString().toLowerCase().contains(query) ?? false);
      }).toList();
      bodyWidget = Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une campagne...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: AppColors.primaryBlue, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: () {
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w500),
              cursorColor: AppColors.primaryBlue,
              onChanged: _onSearchChanged,
              controller: TextEditingController(text: _search),
            ),                
          ),
          
          // Search Status
          if (_search.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search,
                    size: 16,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${filteredCampaigns.length} résultat${filteredCampaigns.length != 1 ? 's' : ''} pour "$_search"',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: filteredCampaigns.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.campaign_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune campagne trouvée',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredCampaigns.length + (_hasMoreData ? 1 : 0),
                    itemBuilder: (context, i) {
                      // Afficher l'indicateur de chargement en bas
                      if (i == filteredCampaigns.length) {
                        return _buildLoadingIndicator();
                      }
                      final c = filteredCampaigns[i];
                      
                      final campaignId = c['id']?.toString() ?? c['_id']?.toString()??'';
                      final locationType = c['location_type'];
                      final locationValue = c['target_location'].map((e) => e['value'] ?? '').join(', ');
                      debugPrint('Campaign ID: $campaignId');
                      // Supprimé cpv et cpc car non utilisés
                      final endDate = c['end_date'] is DateTime ? c['end_date'] : null;
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Media Section
                            if (c['media_url'] != null && c['media_url'].toString().isNotEmpty)
                              c['media_url'].toString().endsWith('.mp4')
                                  ? FutureBuilder<VideoPlayerController>(
                                      future: _getVideoController(i, c['media_url']),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                          final controller = snapshot.data!;
                                          return ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                            child: AspectRatio(
                                              aspectRatio: controller.value.aspectRatio > 0 ? controller.value.aspectRatio : 16 / 9,
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  VideoPlayer(controller),
                                                  if (!controller.value.isPlaying)
                                                    Positioned.fill(
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color: Colors.black.withOpacity(0.3),
                                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                                        ),
                                                        child: Center(
                                                          child: IconButton(
                                                            icon: const Icon(Icons.play_circle, size: 64, color: Colors.white),
                                                            onPressed: () {
                                                              controller.play();
                                                              setState(() {});
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        } else {
                                          return Container(
                                            height: 200,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                            ),
                                            child: const Center(child: CircularProgressIndicator()),
                                          );
                                        }
                                      },
                                    )
                                  : c['media_url'].toString().startsWith('http')
                                      ? ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                          child: Image.network(
                                            c['media_url'],
                                            height: 600,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              height: 200,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                              ),
                                              child: Icon(Icons.image, size: 48, color: Colors.grey[400]),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          height: 120,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                          ),
                                          child: Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Text(
                                                c['media_url'],
                                                style: Theme.of(context).textTheme.bodyLarge,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ),
                            // Content Section
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Advertiser Info
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.business,
                                          size: 20,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          c['advertiser']['name'] ?? '',
                                          style: TextStyle(
                                            color: AppColors.primaryBlue,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Title
                                  Text(
                                    c['title'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Description
                                  Text(
                                    c['description'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Target Link
                                  if (c['campaign_test'] == true)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.warning, size: 16, color: Colors.orange.shade700),
                                          const SizedBox(width: 8),
                                          Expanded(
                                             child: Text(
                                                'Cette campagne est une campagne test, vous devez la publier pour que nous mesurions votre performance et ensuite on pourra vous envoyer des campagnes rémunérées.',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.visible,
                                              ),
                                            
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  // Stats Row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.green.shade200),
                                          ),
                                          child: Column(
                                            children: [
                                              Text('Objectif', style: TextStyle(color: Colors.green.shade700,fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${c['expected_views']} vues',
                                                style: TextStyle(
                                                  color: Colors.green.shade700,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.orange.shade200),
                                          ),
                                          child: Column(
                                            children: [
                                              Text('A gagner', style: TextStyle(color: Colors.orange.shade700,fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${c['expected_earnings']} FCFA',
                                                style: TextStyle(
                                                  color: Colors.orange.shade700,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Location and Time
                                  Row(
                                    children: [
                                      if (locationType != null && locationValue != null && locationType == 'city')
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          child: Wrap(
                                              spacing: 4,
                                              runSpacing: 4,
                                              children: [
                                                 Icon(Icons.location_city, size: 14, color: Colors.blue.shade700),
                                                Text(
                                                  locationValue,
                                                  style: TextStyle(
                                                    color: Colors.blue.shade700,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      if (endDate != null) ...[
                                        if (locationType != null && locationValue != null) const SizedBox(width: 8),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.timer, size: 14, color: Colors.grey.shade700),
                                                const SizedBox(width: 4),
                                                Text(
                                                  () {
                                                    final now = DateTime.now();
                                                    final diff = endDate.difference(now).inDays;
                                                    if (diff < 0) return 'Terminée';
                                                    if (diff == 0) return 'Dernier jour';
                                                    if (diff == 1) return '1 jour';
                                                    return '$diff jours';
                                                  }(),
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Action Buttons
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _uploadingProofs[campaignId] == true ? null : () async {
                                        // Afficher un dialogue pour choisir la source
                                        final source = await showDialog<ImageSource>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Choisir une source'),
                                            content: const Text('D\'où voulez-vous prendre la capture d\'écran ?'),
                                            actions: [
                                              
                                              TextButton.icon(
                                                onPressed: () => Navigator.pop(context, ImageSource.gallery),
                                                icon: const Icon(Icons.photo_library),
                                                label: const Text('Galerie'),
                                              ),
                                            ],
                                          ),
                                        );
                                        
                                        if (source != null) {
                                        final picker = ImagePicker();
                                          final picked = await picker.pickImage(source: source);
                                          
                                        if (picked != null) {
                                            final imageFile = File(picked.path);
                                            // campaignId déjà défini plus haut
                                            
                                            // Confirmation avant upload
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Confirmer l\'upload'),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Text('Voulez-vous envoyer cette preuve pour la campagne ?'),
                                                    const SizedBox(height: 16),
                                                    Container(
                                                      height: 250,
                                                      width: double.infinity,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: Colors.grey.shade300),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: Image.file(
                                                          imageFile,
                                                          fit: BoxFit.contain,
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
                                                    child: const Text('Envoyer', style: TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            );
                                            
                                            if (confirm == true) {
                                              await _uploadProof(campaignId, imageFile);
                                            }
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Aucune image sélectionnée.')),
                                            );
                                          }
                                        }
                                      },
                                      icon: _uploadingProofs[campaignId] == true 
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.upload_file, size: 18),
                                      label: Text(_uploadingProofs[campaignId] == true ? 'Envoi...' : 'Preuve'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _uploadingProofs[campaignId] == true 
                                          ? Colors.grey 
                                          : AppColors.primaryBlue,
                                        side: BorderSide(
                                          color: _uploadingProofs[campaignId] == true 
                                            ? Colors.grey.withOpacity(0.5)
                                            : AppColors.primaryBlue.withOpacity(0.5)
                                        ),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final title = c['title'] ?? '';
                                        final description = c['description'] ?? '';
                                        final mediaUrl = c['media_url'] ?? '';
                                        final shortLink = c['shortLink'] ?? '';
                                        final link = c['target_link'] ?? '';
                                        String content = '\n$description';
                                        List<String> files = [];
                                        final isVideo = mediaUrl.toString().endsWith('.mp4');
                                        final isImage = mediaUrl.toString().startsWith('http') && (
                                          mediaUrl.toString().endsWith('.jpg') ||
                                          mediaUrl.toString().endsWith('.jpeg') ||
                                          mediaUrl.toString().endsWith('.png') ||
                                          mediaUrl.toString().endsWith('.webp')
                                        );
                                        if (isVideo || isImage) {
                                          try {
                                            final response = await http.get(Uri.parse(mediaUrl));
                                            if (response.statusCode == 200) {
                                              final tempDir = await getTemporaryDirectory();
                                              final ext = mediaUrl.toString().split('.').last;
                                              final file = File('${tempDir.path}/media_${DateTime.now().millisecondsSinceEpoch}.$ext');
                                              await file.writeAsBytes(response.bodyBytes);
                                              files.add(file.path);
                                            }
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors du téléchargement du média.')));
                                            return;
                                          }
                                        } else if (mediaUrl.toString().startsWith('http')) {
                                          content += '\n$mediaUrl';
                                        } else if (mediaUrl.toString().isNotEmpty) {
                                          content += '\n$mediaUrl';
                                        }
                                        if (link.isNotEmpty) {
                                          final user = await AuthService.getUser();
                                          final ambassadorId = user?['_id'];
                                          content += '\n$shortLink/$ambassadorId';
                                        }
                                        if (files.isNotEmpty) {
                                          Share.shareXFiles(files.map((e) => XFile(e)).toList(), text: content, subject: title);
                                        } else {
                                          Share.share(content, subject: title);
                                        }
                                      },
                                      icon: const Icon(Icons.share, size: 18,color: Colors.white),
                                      label: const Text('Publier'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryBlue,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Afficher les erreurs d'upload s'il y en a
                            if (_uploadErrors[campaignId] != null) 
                              Container(
                                margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, 
                                         color: Colors.red.shade700, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _uploadErrors[campaignId]!,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _uploadErrors.remove(campaignId);
                                        });
                                      },
                                      icon: Icon(Icons.close, 
                                               color: Colors.red.shade700, size: 16),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Campagnes pour vous',
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
            onPressed: () {
              _resetPagination();
              _loadCampaigns();
            },
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: bodyWidget,
      bottomNavigationBar: AmbassadorBottomNav(
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          if (index == _bottomNavIndex) return;
          setState(() {
            _bottomNavIndex = index;
          });
          switch (index) {
            case 0:
              // Déjà sur la page campagne
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AmbassadorPublicationsPage()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AmbassadorGainsPage()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AmbassadorProfilPage()),
              );
              break;
          }
        },
      ),
    );
  }
  
  // Méthode pour afficher les informations de pagination
  Widget _buildPaginationInfo() {
    if (_campaigns.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page $_currentPage',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              if (_currentPage > 1)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentPage--;
                      _campaigns = _campaigns.take((_currentPage - 1) * _pageSize).toList();
                      _hasMoreData = true;
                    });
                  },
                  child: Text(
                    'Précédent',
                    style: TextStyle(color: AppColors.primaryBlue),
                  ),
                ),
              if (_currentPage > 1 && _hasMoreData) const SizedBox(width: 8),
              if (_hasMoreData)
                TextButton(
                  onPressed: _loadMoreCampaigns,
                  child: Text(
                    'Suivant',
                    style: TextStyle(color: AppColors.primaryBlue),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
