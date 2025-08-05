import '../../components/ambassador_bottom_nav.dart';
import 'ambassador_nav_helper.dart';
import 'package:flutter/material.dart';
import '../../theme.dart';

class AmbassadorGainsPage extends StatefulWidget {
  const AmbassadorGainsPage({Key? key}) : super(key: key);

  @override
  State<AmbassadorGainsPage> createState() => _AmbassadorGainsPageState();
}

class _AmbassadorGainsPageState extends State<AmbassadorGainsPage> {
  double _solde = 15000.0;
  List<Map<String, dynamic>> _transactions = [
    {'type': 'gain', 'label': 'Campagne Pizza Hut', 'montant': 5000.0, 'date': DateTime.now().subtract(const Duration(days: 1))},
    {'type': 'gain', 'label': 'Campagne Orange Money', 'montant': 10000.0, 'date': DateTime.now().subtract(const Duration(days: 2))},
    {'type': 'retrait', 'montant': 8000.0, 'date': DateTime.now().subtract(const Duration(days: 3))},
  ];
  int _totalVues = 120 + 0; // À remplacer par la somme réelle des vues
  int _totalPublications = 2; // À remplacer par le nombre réel de publications

 
  void _retirerGains() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retrait de gains'),
        content: Text('Votre solde actuel est de ${_solde.toStringAsFixed(0)} FCFA. Voulez-vous retirer vos gains ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (_solde > 0) {
                  _transactions.add({'type': 'retrait', 'montant': _solde, 'date': DateTime.now()});
                }
                _solde = 0;
                _transactions.removeWhere((tx) => tx['type'] == 'gain');
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Retrait effectué avec succès.')));
            },
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes gains', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.lightGrey,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const Text('Solde actuel', style: TextStyle(fontSize: 16)),
                Text('${_solde.toStringAsFixed(0)} FCFA', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        const Text('Vues totales', style: TextStyle(fontSize: 14)),
                        Text('$_totalVues', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Column(
                      children: [
                        const Text('Publications', style: TextStyle(fontSize: 14)),
                        Text('$_totalPublications', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _retirerGains,
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text('Retirer mes gains'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                final List<Map<String, dynamic>> sortedTx = List<Map<String, dynamic>>.from(_transactions);
                sortedTx.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
                if (sortedTx.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Text('Aucune transaction'),
                  ));
                }
                return ListView(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Text('Historique des transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    ...sortedTx.map((tx) => ListTile(
                          leading: tx['type'] == 'gain'
                              ? const Icon(Icons.trending_up, color: Colors.green)
                              : const Icon(Icons.arrow_downward, color: Colors.red),
                          title: Text(
                            tx['type'] == 'gain' ? tx['label'] : 'Retrait',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Date: ${tx['date'].day}/${tx['date'].month}/${tx['date'].year}'),
                          trailing: Text(
                            (tx['type'] == 'gain' ? '+' : '-') +
                                (tx['montant'] as double).toStringAsFixed(0) +
                                ' FCFA',
                            style: TextStyle(
                              color: tx['type'] == 'gain' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )),
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
