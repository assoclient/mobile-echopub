  import 'package:flutter/material.dart';
import 'package:mobile/components/advertiser_bottom_nav.dart';
import 'package:mobile/screens/advertiser/advertiser_dashboard.dart';
import 'package:mobile/screens/advertiser/advertiser_nav_helper.dart';
import 'package:mobile/screens/advertiser/advertiser_profile_page.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:video_player/video_player.dart';
import 'package:mobile/theme.dart';
import 'package:mobile/components/custom_bottom_nav_bar.dart';
import 'package:mobile/screens/advertiser/create_ad_page.dart';
import 'package:mobile/screens/advertiser/edit_ad_page.dart';
import 'package:mobile/screens/advertiser/deposit_form_page.dart';
import 'package:mobile/screens/advertiser/ad_details_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class AdvertiserHome extends StatefulWidget {
  const AdvertiserHome({Key? key}) : super(key: key);

  @override
  State<AdvertiserHome> createState() => _AdvertiserHomeState();
}

class _AdvertiserHomeState extends State<AdvertiserHome> {

  String _statusLabel(dynamic status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'paused':
        return 'En pause';
      case 'completed':
        return 'Terminé';
      case 'draft':
        return 'Brouillon';
      case 'submitted':
        return 'Soumise';
      default:
        return status?.toString() ?? 'Inconnu';
    }
  }
  final Map<int, VideoPlayerController> _videoControllers = {};
  final TextEditingController _searchController = TextEditingController();
  DateTime? _filterStart;
  DateTime? _filterEnd;

  List<Map<String, dynamic>> _allAds = [];
  bool _loadingAds = true;
  bool _loadingMore = false;
  String? _errorAds;
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalCount = 0;
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> get _ads {
    String search = _searchController.text.trim().toLowerCase();
    return _allAds.where((ad) {
      final title = (ad['title'] ?? '').toString().toLowerCase();
      final desc = (ad['description'] ?? '').toString().toLowerCase();
      final matchText = search.isEmpty || title.contains(search) || desc.contains(search);
      DateTime? start;
      DateTime? end;
      try {
        start = ad['start_date'] is DateTime
            ? ad['start_date']
            : DateTime.tryParse(ad['start_date']?.toString() ?? '');
        end = ad['end_date'] is DateTime
            ? ad['end_date']
            : DateTime.tryParse(ad['end_date']?.toString() ?? '');
      } catch (_) {
        start = DateTime(2000);
        end = DateTime(2100);
      }
      final matchStart = _filterStart == null || (start != null && !start.isBefore(_filterStart!));
      final matchEnd = _filterEnd == null || (end != null && !end.isAfter(_filterEnd!));
      return matchText && matchStart && matchEnd;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchAds(reset: true);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_loadingMore && _allAds.length < _totalCount) {
      _fetchAds();
    }
  }

  Future<void> _fetchAds({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loadingAds = true;
        _errorAds = null;
        _currentPage = 1;
        _allAds = [];
        _totalCount = 0;
      });
    } else {
      setState(() {
        _loadingMore = true;
      });
    }
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final user =await  AuthService.getUser();
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
      final url = Uri.parse('$apiUrl/api/campaigns/my-campaigns?page=$_currentPage&pageSize=$_pageSize&search=$_searchQuery');
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> dataList;
        int totalCount = 0;
        int page = 1;
        int pageSize = 10;
        if (decoded is Map && decoded.containsKey('data')) {
          dataList = decoded['data'] as List<dynamic>;
          totalCount = decoded['totalCount'] ?? 0;
          page = decoded['page'] ?? 1;
          pageSize = decoded['pageSize'] ?? 10;
        } else if (decoded is List) {
          dataList = decoded;
          totalCount = dataList.length;
        } else {
          throw Exception('Format de réponse inattendu: ${response.body}');
        }
        final newAds = dataList.map<Map<String, dynamic>>((e) {
          return {
            ...e,
            'start_date': e['start_date'] != null ? DateTime.tryParse(e['start_date']) : null,
            'end_date': e['end_date'] != null ? DateTime.tryParse(e['end_date']) : null,
          };
        }).toList();
        setState(() {
          if (reset) {
            _allAds = newAds;
          } else {
            _allAds.addAll(newAds);
          }
          _totalCount = totalCount;
          _pageSize = pageSize;
          _currentPage = page + 1;
          _loadingAds = false;
          _loadingMore = false;
        });
      } else {
        setState(() {
          _errorAds = 'Erreur serveur: ${response.statusCode}';
          _loadingAds = false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching ads: $e');
      setState(() {
        _errorAds = 'Erreur réseau ou parsing: $e';
        _loadingAds = false;
        _loadingMore = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<VideoPlayerController> _getVideoController(int index, String url) async {
    if (_videoControllers[index] != null) return _videoControllers[index]!;
    final controller = VideoPlayerController.network(url);
    await controller.initialize();
    _videoControllers[index] = controller;
    return controller;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes annonces',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher une annonce...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    onChanged: (v) => setState(() {
                      _searchQuery = v.trim().toLowerCase();
                      _fetchAds(reset: true);
                    }),
                  ),
                ),
                /* const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDateRange: _filterStart != null && _filterEnd != null
                          ? DateTimeRange(start: _filterStart!, end: _filterEnd!)
                          : null,
                    );
                    if (picked != null) {
                      setState(() {
                        _filterStart = picked.start;
                        _filterEnd = picked.end;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          _filterStart != null && _filterEnd != null
                              ? '${_filterStart!.day}/${_filterStart!.month}/${_filterStart!.year} - ${_filterEnd!.day}/${_filterEnd!.month}/${_filterEnd!.year}'
                              : 'Filtrer dates',
                          style: const TextStyle(fontSize: 13, color: Colors.blue),
                        ),
                        if (_filterStart != null && _filterEnd != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _filterStart = null;
                                _filterEnd = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ), */
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loadingAds
                  ? const Center(child: CircularProgressIndicator())
                  : _errorAds != null
                      ? Center(child: Text(_errorAds!, style: const TextStyle(color: Colors.red)))
                      : _ads.isEmpty
                          ? const Center(child: Text('Aucune annonce pour le moment.'))
                          : NotificationListener<ScrollNotification>(
                              onNotification: (scrollInfo) {
                                if (!_loadingMore && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 && _allAds.length < _totalCount) {
                                  _fetchAds();
                                }
                                return false;
                              },
                              child: ListView.separated(
                                controller: _scrollController,
                                itemCount: _ads.length + (_loadingMore ? 1 : 0),
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, i) {
                                  if (i >= _ads.length) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  }
                                  final ad = _ads[i];
                                  return InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AdDetailsPage(campaignId: ad['_id'].toString()),
                                        ),
                                      );
                                    },
    child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ad['status'] == 'active'
                        ? Colors.green.shade100
                        : ad['status'] == 'paused'
                            ? Colors.orange.shade100
                            : ad['status'] == 'completed'
                                ? Colors.blue.shade100
                                : ad['status'] == 'submitted'
                                    ? Colors.purple.shade100
                                    : Colors.lightBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(ad['status']),
                    style: TextStyle(
                      color: ad['status'] == 'active'
                          ? Colors.green.shade800
                          : ad['status'] == 'paused'
                              ? Colors.orange.shade800
                              : ad['status'] == 'completed'
                                  ? Colors.blue.shade800
                                  : ad['status'] == 'submitted'
                                      ? Colors.purple.shade800
                                      : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(ad['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (ad['description'] != null) ...[
              const SizedBox(height: 4),
              Text(ad['description'], style: const TextStyle(fontSize: 15, color: Colors.black87)),
            ],
            if (ad['media_url'] != null && ad['media_url'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final url = ad['media_url'].toString();
                  if (url.endsWith('.mp4') || url.endsWith('.webm') || url.endsWith('.avi') || url.endsWith('.mov')) {
                    return FutureBuilder<VideoPlayerController>(
                      future: _getVideoController(i, url),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                          final controller = snapshot.data!;
                          return AspectRatio(
                            aspectRatio: controller.value.aspectRatio > 0 ? controller.value.aspectRatio : 16 / 9,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                VideoPlayer(controller),
                                if (!controller.value.isPlaying)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black26,
                                      child: Center(
                                        child: IconButton(
                                          icon: const Icon(Icons.play_circle, size: 48, color: Colors.white),
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
                          );
                        } else {
                          return Container(
                            height: 160,
                            color: Colors.black12,
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        }
                      },
                    );
                  } else if (url.startsWith('http') && (url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.png') || url.endsWith('.webp'))) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, size: 48, color: Colors.grey),
                        ),
                      ),
                    );
                  } else {
                    return Text('Média : $url', style: const TextStyle(fontSize: 13, color: Colors.blueGrey));
                  }
                },
              ),
            ],
            if (ad['target_link'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.link, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(ad['target_link'], style: const TextStyle(fontSize: 14, color: Colors.blue, decoration: TextDecoration.underline), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
            if (ad['target_location'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    ad['location_type'] != 'city'
                        ? 'Region: ${ad['target_location'].map((e) => e['value']).join(', ')}'
                        : 'Ville: ${ad['target_location'].map((e) => e['value']).join(', ')}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.campaign, size: 18, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text('Publications: ${ad['publications']}', style: const TextStyle(fontSize: 15)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.remove_red_eye, size: 18, color: Colors.green),
                    const SizedBox(width: 4),
                    Text('Vues: ${ad['views']}', style: const TextStyle(fontSize: 15)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.touch_app, size: 18, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text('Clics: ${ad['clics'] ?? ad['clicks'] ?? 0}', style: const TextStyle(fontSize: 15)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, size: 18, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text('Budget: ${ad['budget']} FCFA', style: const TextStyle(fontSize: 15)),
                  ],
                ),
               /*  Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.paid, size: 18, color: Colors.deepPurple),
                    const SizedBox(width: 4),
                    Text('Dépensé: ${ad['spent']} FCFA', style: const TextStyle(fontSize: 15)),
                  ],
                ), */
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.flag, size: 18, color: Colors.orange),
                const SizedBox(width: 4),
              
                if (ad['cpv'] != null)
                  Text('Objectif minimum: ${ad['expected_views']} vues', style: const TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                    
                  
                /* if (ad['cpc'] != null)
                  Chip(
                    label: Text('CPC: ${ad['cpc']} FCFA', style: const TextStyle(color: Colors.white)),
                    backgroundColor: Colors.orange.shade700,
                  ), */
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (ad['start_date'] != null)
                  Text('Début: ${ad['start_date'].day}/${ad['start_date'].month}/${ad['start_date'].year}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                if (ad['end_date'] != null) ...[
                  const SizedBox(width: 12),
                  Text('Fin: ${ad['end_date'].day}/${ad['end_date'].month}/${ad['end_date'].year}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ],
            ),
            if (ad['status'] == 'draft')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditAdPage(ad: ad),
                        ),
                      );
                      if (updated == true) {
                        _fetchAds(reset: true);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Supprimer l\'annonce'),
                          content: const Text('Voulez-vous vraiment supprimer ce brouillon ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _deleteAd(ad['_id']);
                      }
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, color: Colors.white, size: 18),
                    label: const Text('Soumettre', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Soumettre l\'annonce'),
                          content: const Text('Voulez-vous vraiment soumettre cette annonce ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Soumettre', style: TextStyle(color: Colors.purple)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DepositFormPage(
                              userId: ad['advertiser']?.toString() ?? '',
                              campaignId: ad['_id']?.toString() ?? '',
                            ),
                            settings: RouteSettings(arguments: ad),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            if (ad['status'] == 'active')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.pause, color: Colors.orange),
                    tooltip: 'Mettre en pause',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Mettre en pause'),
                          content: const Text('Voulez-vous vraiment mettre cette annonce en pause ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Mettre en pause', style: TextStyle(color: Colors.orange)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _pauseAd(ad['_id']);
                      }
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
     /*  floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateAdPage()),
          );
        },
        child: const Icon(Icons.add,color: Colors.white,),
        tooltip: 'Créer une annonce',
      ), */
      // bottomNavigationBar supprimé pour éviter le doublon
      bottomNavigationBar: AdvertiserBottomNav(
        currentIndex: 1,
        onTap: (index) => handleAdvertiserNav(context, 1, index),
      )
    );
  }

  Future<void> _deleteAd(dynamic adId) async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
      final url = Uri.parse('$apiUrl/api/campaigns/$adId');
      final response = await http.delete(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Annonce supprimée.')));
        _fetchAds(reset: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression: [200b${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression: $e')));
    }
  }
  // Duplicate _deleteAd removed. All helper methods should be inside the _AdvertiserHomeState class.

  Future<void> _reactivateAd(dynamic adId) async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
      final url = Uri.parse('$apiUrl/api/campaigns/changestatus/$adId');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': 'active'}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Annonce réactivée.')));
        _fetchAds(reset: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur réactivation: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur réactivation: $e')));
    }
  }
}
extension _AdvertiserHomeStateSubmitAd on _AdvertiserHomeState {
  Future<void> _submitAd(dynamic adId) async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
      final url = Uri.parse('$apiUrl/api/campaigns/changestatus/$adId');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': 'submitted'}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Annonce soumise.')));
        _fetchAds(reset: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur soumission: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur soumission: $e')));
    }
  }
  // Duplicate _deleteAd removed. All helper methods should be inside the _AdvertiserHomeState class.

  Future<void> _pauseAd(dynamic adId) async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
      final url = Uri.parse('$apiUrl/api/campaigns/changestatus/$adId');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': 'paused'}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Annonce mise en pause.')));
        _fetchAds(reset: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur pause: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur pause: $e')));
    }
  }

}  

