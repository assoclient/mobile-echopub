import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
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
  String? _error;
  List<Map<String, dynamic>> _campaigns = [];
  final Map<int, VideoPlayerController> _videoControllers = {};

  // Pour stocker la capture temporairement
  File? _pendingProof;

  int _bottomNavIndex = 0;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchCampaigns();
  }

  @override
  void dispose() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchCampaigns() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Récupérer l'ID ambassadeur et le token
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      // Remplacer par la vraie méthode si tu utilises AuthService
      final user = await AuthService.getUser();
      final ambassadorId = user?['_id'];
      if (ambassadorId == null) throw Exception('Utilisateur non connecté');
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
      final url = Uri.parse('$apiUrl/api/campaigns/active-campaigns/');
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
      setState(() {
        _isLoading = false;
        _error = 'Erreur réseau ou parsing: $e';
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

  @override
  Widget build(BuildContext context) {
    Widget bodyWidget;
    if (_isLoading) {
      bodyWidget = const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
    } else if (_error != null) {
      bodyWidget = Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    } else {
      final filteredCampaigns = _campaigns.where((c) {
        final query = _search.trim().toLowerCase();
        if (query.isEmpty) return true;
        return (c['title']?.toString().toLowerCase().contains(query) ?? false) ||
               (c['description']?.toString().toLowerCase().contains(query) ?? false);
      }).toList();
      bodyWidget = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une campagne...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primaryBlue),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              ),
              style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w500),
              cursorColor: AppColors.primaryBlue,
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredCampaigns.isEmpty
                ? const Center(child: Text('Aucune campagne trouvée'))
                : ListView.separated(
                    padding: const EdgeInsets.all(0),
                    itemCount: filteredCampaigns.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final c = filteredCampaigns[i];
                      final locationType = c['location_type'];
                      final locationValue = c['target_location'].map((e) => e['value']).join(', ');
                      final cpv = c['cpv'];
                      final cpc = c['cpc'];
                      final endDate = c['end_date'] is DateTime ? c['end_date'] : null;
                      return Card(
                        elevation: 0,
                        color: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(0),
                          onTap: () {
                            // TODO: Naviguer vers le détail ou accepter la campagne
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Ici, le contenu de la carte campagne reste inchangé
                              if (c['media_url'] != null && c['media_url'].toString().isNotEmpty)
                                c['media_url'].toString().endsWith('.mp4')
                                    ? FutureBuilder<VideoPlayerController>(
                                        future: _getVideoController(i, c['media_url']),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                            final controller = snapshot.data!;
                                            return ClipRRect(
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
                                              child: AspectRatio(
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
                                      )
                                    : c['media_url'].toString().startsWith('http')
                                        ? ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
                                            child: Image.network(
                                              c['media_url'],
                                              height: 160,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                height: 160,
                                                color: Colors.grey.shade200,
                                                child: const Icon(Icons.image, size: 48, color: Colors.grey),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            height: 100,
                                            alignment: Alignment.center,
                                            color: Colors.grey.shade100,
                                            child: Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Text(
                                                c['media_url'],
                                                style: Theme.of(context).textTheme.bodyLarge,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.transparent,
                                          child: ClipOval(
                                            child: Icon(Icons.person, size: 24, color: Colors.grey),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          c['advertiser']['name'] ?? '',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(c['title'] ?? '', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text(c['description'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                                    const SizedBox(height: 8),
                                    if (c['target_link'] != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.link, size: 18, color: Colors.blueGrey),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: GestureDetector(
                                              onTap: () async {
                                                final url = c['target_link'];
                                                if (url != null) {
                                                  // TODO: Utiliser url_launcher pour ouvrir le lien
                                                }
                                              },
                                              child: Text(
                                                c['target_link'],
                                                style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (cpv != null)
                                          Chip(
                                            label: Text('CPV: ${cpv.toString()} FCFA', style: const TextStyle(color: Colors.white)),
                                            backgroundColor: Colors.green.shade700,
                                          ),
                                        if (cpc != null)
                                          Chip(
                                            label: Text('CPC: ${cpc.toString()} FCFA', style: const TextStyle(color: Colors.white)),
                                            backgroundColor: Colors.orange.shade700,
                                          ),
                                        if (locationType != null && locationValue != null && locationType == 'city')
                                          Chip(
                                            label: Text('Ville: $locationValue', style: const TextStyle(color: Colors.white)),
                                            backgroundColor: AppColors.darkGrey,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (endDate != null)
                                          Row(
                                            children: [
                                              const Icon(Icons.timer, size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                () {
                                                  final now = DateTime.now();
                                                  final diff = endDate.difference(now).inDays;
                                                  if (diff < 0) return 'Campagne terminée';
                                                  if (diff == 0) return 'Dernier jour';
                                                  if (diff == 1) return '1 jour restant';
                                                  return '$diff jours restants';
                                                }(),
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.lightGrey,
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final title = c['description'] ?? '';
                                        final description = c['description'] ?? '';
                                        final mediaUrl = c['media_url'] ?? '';
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
                                          content += '\n$link';
                                        }
                                        if (files.isNotEmpty) {
                                          await Share.shareXFiles(files.map((e) => XFile(e)).toList(), text: content, subject: title);
                                        } else {
                                          await Share.share(content, subject: title);
                                        }
                                      },
                                      icon: const Icon(Icons.campaign, color: Colors.white),
                                      label: const Text('Partager',style: TextStyle(color: Colors.white),),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryBlue,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final picker = ImagePicker();
                                        final picked = await picker.pickImage(source: ImageSource.gallery);
                                        if (picked != null) {
                                          setState(() {
                                            _pendingProof = File(picked.path);
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Capture enregistrée. Elle sera envoyée au serveur plus tard.')),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Aucune capture prise.')),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.upload_file, color: Colors.white),
                                      label: const Text('Preuve', style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.lightBlue,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campagnes pour vous ',style: TextStyle(color: Colors.white),),
        backgroundColor: AppColors.primaryBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCampaigns,
            tooltip: 'Rafraîchir',
            color: AppColors.primaryBlue,
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
}
