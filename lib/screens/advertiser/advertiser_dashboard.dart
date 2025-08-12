import 'package:flutter/material.dart';
import '../../theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../components/advertiser_bottom_nav.dart';
import 'advertiser_nav_helper.dart';

class AdvertiserDashboardPage extends StatefulWidget {
  const AdvertiserDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdvertiserDashboardPage> createState() => _AdvertiserDashboardPageState();
}

class _AdvertiserDashboardPageState extends State<AdvertiserDashboardPage> {
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  bool _isRefreshing = false;

  // Statistiques générales
  int _totalCampaigns = 0;
  int _activeCampaigns = 0;
  int _totalAmbassadors = 0;
  int _totalViews = 0;
  double _totalSpent = 0.0;

  // Top campagnes virales
  List<Map<String, dynamic>> _topViralAds = [];

  // Campagnes récentes
  List<Map<String, dynamic>> _recentCampaigns = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Token non trouvé');
      }

      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:5000';
      final response = await http.get(
        Uri.parse('$baseUrl/api/dashboard/advertiser-stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final dashboardData = data['data'];
          final stats = dashboardData['stats'];
          
          setState(() {
            _totalCampaigns = stats['totalCampaigns'] ?? 0;
            _activeCampaigns = stats['activeCampaigns'] ?? 0;
            _totalAmbassadors = stats['totalAmbassadors'] ?? 0;
            _totalViews = stats['totalViews'] ?? 0;
            _totalSpent = (stats['totalSpent'] ?? 0).toDouble();
            
            _topViralAds = List<Map<String, dynamic>>.from(dashboardData['topViralAds'] ?? []);
            _recentCampaigns = List<Map<String, dynamic>>.from(dashboardData['recentCampaigns'] ?? []);
          });
        }
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du dashboard: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des données: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadDashboardData();
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'draft':
        return 'Brouillon';
      case 'completed':
        return 'Terminée';
      case 'paused':
        return 'En pause';
      case 'submitted':
        return 'Soumise';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'draft':
        return Colors.grey;
      case 'completed':
        return Colors.blue;
      case 'paused':
        return Colors.orange;
      case 'submitted':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Tableau de bord',
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
            onPressed: _isLoading ? null : _refreshData,
            icon: _isRefreshing 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
          )
        : RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistiques générales
                  _buildStatsSection(),
                  const SizedBox(height: 24),
                  
                  // Top 5 campagnes virales
                  if (_topViralAds.isNotEmpty) ...[
                    _buildTopViralAdsSection(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Campagnes récentes
                  if (_recentCampaigns.isNotEmpty) ...[
                    _buildRecentCampaignsSection(),
                  ],
                ],
              ),
            ),
          ),
      bottomNavigationBar: AdvertiserBottomNav(
        currentIndex: 0,
        onTap: (index) => handleAdvertiserNav(context, 0, index),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Vue d\'ensemble',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Grille de statistiques
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  Icons.campaign,
                  'Campagnes',
                  '$_totalCampaigns',
                  Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  Icons.play_circle,
                  'Actives',
                  '$_activeCampaigns',
                  Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  Icons.people,
                  'Ambassadeurs',
                  '$_totalAmbassadors',
                  Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  Icons.remove_red_eye,
                  'Vues totales',
                  '${_totalViews.toStringAsFixed(0)}',
                  Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  Icons.account_balance_wallet,
                  'Dépensé',
                  '${_totalSpent.toStringAsFixed(0)} FCFA',
                  Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(), // Placeholder pour équilibrer la grille
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopViralAdsSection() {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, size: 20, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Top 5 campagnes virales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _topViralAds.length,
            itemBuilder: (context, index) {
              final ad = _topViralAds[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ad['title'] ?? 'Sans titre',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(ad['status'] ?? '').withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStatusLabel(ad['status'] ?? ''),
                            style: TextStyle(
                              color: _getStatusColor(ad['status'] ?? ''),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildViralStat(
                            Icons.remove_red_eye,
                            'Vues',
                            '${ad['totalViews'] ?? 0}',
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildViralStat(
                            Icons.touch_app,
                            'Clics',
                            '${ad['totalClicks'] ?? 0}',
                            Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _buildViralStat(
                            Icons.people,
                            'Ambassadeurs',
                            '${ad['ambassadorCount'] ?? 0}',
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    
                    if (ad['engagementRate'] != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Taux d\'engagement',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            '${ad['engagementRate']}%',
                            style: TextStyle(
                              color: ad['engagementRate'] >= 80 ? Colors.green : 
                                     ad['engagementRate'] >= 50 ? Colors.orange : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViralStat(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCampaignsSection() {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 20, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Campagnes récentes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentCampaigns.length,
            itemBuilder: (context, index) {
              final campaign = _recentCampaigns[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            campaign['title'] ?? 'Sans titre',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(campaign['status'] ?? '').withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStatusLabel(campaign['status'] ?? ''),
                            style: TextStyle(
                              color: _getStatusColor(campaign['status'] ?? ''),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildRecentStat(
                            Icons.remove_red_eye,
                            'Vues',
                            '${campaign['views'] ?? 0}',
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildRecentStat(
                            Icons.touch_app,
                            'Clics',
                            '${campaign['clicks'] ?? 0}',
                            Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _buildRecentStat(
                            Icons.timeline,
                            'Progression',
                            '${campaign['progress'] ?? 0}%',
                            campaign['progress'] >= 80 ? Colors.green : 
                            campaign['progress'] >= 50 ? Colors.orange : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentStat(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
