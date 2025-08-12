import '../../components/ambassador_bottom_nav.dart';
import 'ambassador_nav_helper.dart';
import 'package:flutter/material.dart';
import '../../theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AmbassadorGainsPage extends StatefulWidget {
  const AmbassadorGainsPage({Key? key}) : super(key: key);

  @override
  State<AmbassadorGainsPage> createState() => _AmbassadorGainsPageState();
}

class _AmbassadorGainsPageState extends State<AmbassadorGainsPage> {
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  
  double _solde = 0.0;
  double _totalEarnings = 0.0;
  double _totalWithdrawn = 0.0;
  List<Map<String, dynamic>> _transactions = [];
  int _totalVues = 0;
  int _totalPublications = 0;
  
  // Pagination
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalPages = 1;
  bool _hasNextPage = false;
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    _loadGainsData();
    _setupScrollListener();
    _phoneController.text = '237';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
        if (_hasNextPage && !_isLoadingMore && !_isLoading) {
          _loadMoreTransactions();
        }
      }
    });
  }

  Future<void> _loadGainsData() async {
    if (!_isRefreshing) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Charger les statistiques de gains
      await _loadGainsStats();
      
      // Charger la première page des transactions
      _currentPage = 1;
      await _loadTransactions(reset: true);
      
    } catch (e) {
      debugPrint('Erreur lors du chargement des gains: $e');
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

  Future<void> _loadGainsStats() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('Token non trouvé');
    }

    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:5000';
    final response = await http.get(
      Uri.parse('$baseUrl/api/dashboard/ambassador-gains'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        final gainsData = data['data'];
        setState(() {
          _solde = (gainsData['solde'] ?? 0).toDouble();
          _amountController.text = _solde.toString();
          _totalEarnings = (gainsData['totalEarnings'] ?? 0).toDouble();
          _totalWithdrawn = (gainsData['totalWithdrawn'] ?? 0).toDouble();
          _totalVues = gainsData['totalVues'] ?? 0;
          _totalPublications = gainsData['totalPublications'] ?? 0;
        });
      }
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> _loadTransactions({bool reset = false}) async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('Token non trouvé');
    }

    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:5000';
    final response = await http.get(
      Uri.parse('$baseUrl/api/dashboard/ambassador-transactions?page=$_currentPage&pageSize=$_pageSize'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        debugPrint('data: $data');
        final newTransactions = (data['data'] as List? ?? [])
            .map((tx) => {
              'type': tx['type'],
              'label': tx['label'],
              'montant': (tx['amount'] ?? 0).toDouble(),
              'date': DateTime.parse(tx['createdAt']),
              'status': tx['status'],
              'campaignId': tx['campaign']?['_id'],
              'publicationId': tx['campaign']?['_id'],
              'transactionId': tx['transactionId'],
            })
            .toList();

        final pagination = data['pagination'];
        setState(() {
          if (reset) {
            _transactions = newTransactions;
          } else {
            _transactions.addAll(newTransactions);
          }
          _totalPages = pagination['totalPages'] ?? 1;
          _hasNextPage = pagination['hasNext'] ?? false;
        });
      }
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (!_hasNextPage || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;
      await _loadTransactions();
    } catch (e) {
      debugPrint('Erreur lors du chargement des transactions: $e');
      _currentPage--; // Revert page increment on error
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadGainsData();
  }
 
  void _retirerGains() {
    if (_solde <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Aucun gain disponible pour retrait.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Demande de retrait', style: TextStyle(fontWeight: FontWeight.w600)),
        content: Form(
          key: _formKey,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Votre solde actuel est de ${_solde.toStringAsFixed(0)} FCFA.'),
            const SizedBox(height: 4),
            const Text(
              'En confirmant, une demande de retrait sera créée et soumise pour validation.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            TextFormField(
              
              controller: _phoneController,
              validator:(v) {
                    if (v == null || v.isEmpty) return 'Champ requis';
                    if (!RegExp(r'^237[0-9]{9}').hasMatch(v)) return 'Format: 237XXXXXXXXX';
                    return null;
                  },
              decoration: const InputDecoration(labelText: 'Numéro de téléphone',hintText: '237XXXXXXXXX'),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ requis';
                    if (double.tryParse(v) == null) return 'Entrez un montant valide';
                    if (double.tryParse(v)! > _solde) return 'Le montant demandé est supérieur à votre solde';
                    return null;
                  },
              decoration: const InputDecoration(labelText: 'Montant'),
            ),
            const SizedBox(height: 4),
            ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _requestWithdrawal();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Demander le retrait'),
          ),
          ],
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          
        ],
      ),
    );
  }

  Future<void> _requestWithdrawal() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Token non trouvé');
      }

      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:5000';
      final response = await http.post(
        Uri.parse('$baseUrl/api/transactions/withdraw'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': _amountController.text,
          'type': 'withdrawal',
          'phone': _phoneController.text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Demande de retrait soumise avec succès !'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          // Recharger les données pour refléter la nouvelle transaction
          await _loadGainsData();
        }
      } else {
        throw Exception('Erreur lors de la demande de retrait');
      }
    } catch (e) {
      debugPrint('Erreur lors de la demande de retrait: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la demande de retrait: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mes gains',
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
        : Column(
        children: [
          // Balance Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
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
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Solde actuel',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_solde.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.remove_red_eye,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_totalVues',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const Text(
                              'Vues totales',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.article,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_totalPublications',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const Text(
                              'Publications',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _retirerGains,
                    icon: const Icon(Icons.account_balance_wallet, size: 20),
                    label: const Text(
                      'Retirer mes gains',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Transactions Section
          Expanded(
            child: Builder(
              builder: (context) {
                final List<Map<String, dynamic>> sortedTx = List<Map<String, dynamic>>.from(_transactions);
                sortedTx.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
                
                if (sortedTx.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune transaction',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Icon(Icons.history, size: 20, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Historique des transactions',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: sortedTx.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Indicateur de chargement en bas
                          if (index == sortedTx.length) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                              ),
                            );
                          }
                          final tx = sortedTx[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Icon Container
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: tx['type'] == 'payment'
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      tx['type'] == 'payment'
                                          ? Icons.trending_up
                                          : Icons.arrow_downward,
                                      color: tx['type'] == 'payment'
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Transaction Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx['type'] == 'payment' 
                                            ? (tx['label'] ?? 'Gain de campagne')
                                            :tx['type'] == 'withdrawal' ? 'Demande de retrait' : 'Divers',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 14,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${tx['date'].day}/${tx['date'].month}/${tx['date'].year}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Afficher le statut pour les retraits
                                        if (tx['type'] == 'withdrawal' && tx['status'] != null) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: tx['status'] == 'confirmed' 
                                                ? Colors.green.shade50
                                                : tx['status'] == 'pending'
                                                  ? Colors.orange.shade50
                                                  : Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              tx['status'] == 'confirmed' 
                                                ? 'Confirmé'
                                                : tx['status'] == 'pending'
                                                  ? 'En attente'
                                                  : 'Rejeté',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: tx['status'] == 'confirmed' 
                                                  ? Colors.green.shade700
                                                  : tx['status'] == 'pending'
                                                    ? Colors.orange.shade700
                                                    : Colors.red.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Amount
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        (tx['type'] == 'payment' ? '+' : '-') +
                                            (tx['montant'] as double).toStringAsFixed(0) +
                                            ' FCFA',
                                        style: TextStyle(
                                          color: tx['type'] == 'payment'
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: tx['type'] == 'payment'
                                              ? Colors.green.shade50
                                              : Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                        tx['type'] == 'payment' ? 'Gain' : 'Retrait',
                                          style: TextStyle(
                                            color: tx['type'] == 'payment'
                                                ? Colors.green.shade700
                                                : Colors.red.shade700,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
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
                    // Indicateur "Fin des transactions" quand toutes sont chargées
                    if (!_hasNextPage && _transactions.isNotEmpty && !_isLoading)
                      Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: Text(
                          'Toutes les transactions ont été chargées',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: AmbassadorBottomNav(
        currentIndex: 2,
        onTap: (index) => handleAmbassadorNav(context, 2, index),
      ),
    );
  }
}
