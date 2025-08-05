import '../../components/ambassador_bottom_nav.dart';
import 'ambassador_nav_helper.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../theme.dart';

class AmbassadorPublicationsPage extends StatefulWidget {
  const AmbassadorPublicationsPage({Key? key}) : super(key: key);

  @override
  State<AmbassadorPublicationsPage> createState() => _AmbassadorPublicationsPageState();
}

class _AmbassadorPublicationsPageState extends State<AmbassadorPublicationsPage> {
  List<Map<String, dynamic>> _publications = [
    {
      'title': 'Statut Pizza Hut',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'Publié',
      'validation': 'Validée',
      'views': 120,
      'gain': 2400,
      'capture1': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80',
      'capture2': null,
    },
    {
      'title': 'Offre Orange Money',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'status': 'Publié',
      'validation': 'En attente',
      'views': 0,
      'gain': 0,
      'capture1': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=400&q=80',
      'capture2': null,
    },
  ];

  String _search = '';
  DateTime? _dateStart;
  DateTime? _dateEnd;

  Future<void> _pickCapture(int index, int captureNum) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _publications[index]['capture$captureNum'] = picked.path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Capture ${captureNum == 1 ? "initiale" : "18h"} enregistrée.')),
      );
    }
  }

  void _deletePublication(int index) {
    setState(() {
      _publications.removeAt(index);
    });
  }

  void _editPublication(int index) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _publications[index]['title']);
        return AlertDialog(
          title: const Text('Modifier la publication'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Titre'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _publications[index]['title'] = result;
      });
    }
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
      appBar: AppBar(
        title: const Text('Mes publications', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Rechercher par titre...',
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
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: Text(_dateStart == null ? 'Début' : '${_dateStart!.day}/${_dateStart!.month}/${_dateStart!.year}'),
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
                          minimumSize: const Size(40, 40),
                          foregroundColor: AppColors.primaryBlue,
                          side: const BorderSide(color: AppColors.primaryBlue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: Text(_dateEnd == null ? 'Fin' : '${_dateEnd!.day}/${_dateEnd!.month}/${_dateEnd!.year}'),
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
                          minimumSize: const Size(40, 40),
                          foregroundColor: AppColors.primaryBlue,
                          side: const BorderSide(color: AppColors.primaryBlue),
                        ),
                      ),
                    ),
                    if (_dateStart != null || _dateEnd != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Réinitialiser dates',
                        color: AppColors.primaryBlue,
                        onPressed: () => setState(() {
                          _dateStart = null;
                          _dateEnd = null;
                        }),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Aucune publication'))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, i) {
                      final pub = filtered[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pub['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text('Date: ${pub['date'].day}/${pub['date'].month}/${pub['date'].year} - ${pub['status']}'),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: pub['validation'] == 'Validée'
                                          ? Colors.green.shade100
                                          : pub['validation'] == 'Refusée'
                                              ? Colors.red.shade100
                                              : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      pub['validation'] ?? 'En attente',
                                      style: TextStyle(
                                        color: pub['validation'] == 'Validée'
                                            ? Colors.green.shade800
                                            : pub['validation'] == 'Refusée'
                                                ? Colors.red.shade800
                                                : Colors.orange.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  if (pub['validation'] == 'Validée') ...[
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.remove_red_eye, size: 16, color: Colors.blueGrey),
                                        const SizedBox(width: 2),
                                        Text('${pub['views'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.monetization_on, size: 16, color: Colors.green),
                                        const SizedBox(width: 2),
                                        Text('${pub['gain'] ?? 0} FCFA', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        pub['capture1'] != null
                                            ? Column(
                                                children: [
                                                  Image.network(
                                                    pub['capture1'],
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                  ),
                                                  TextButton.icon(
                                                    onPressed: () => _pickCapture(_publications.indexOf(pub), 1),
                                                    icon: const Icon(Icons.refresh),
                                                    label: const Text('Remplacer preuve initiale'),
                                                  ),
                                                ],
                                              )
                                            : Column(
                                                children: [
                                                  const Text('Aucune preuve initiale'),
                                                  TextButton.icon(
                                                    onPressed: () => _pickCapture(_publications.indexOf(pub), 1),
                                                    icon: const Icon(Icons.camera_alt),
                                                    label: const Text('Ajouter preuve initiale'),
                                                  ),
                                                ],
                                              ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        pub['capture2'] != null
                                            ? Image.network(
                                                pub['capture2'],
                                                height: 80,
                                                fit: BoxFit.cover,
                                              )
                                            : const Text('Aucune preuve 18h'),
                                        TextButton.icon(
                                          onPressed: () => _pickCapture(_publications.indexOf(pub), 2),
                                          icon: const Icon(Icons.camera_alt_outlined),
                                          label: const Text('Ajouter preuve 18h'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.orange),
                                    onPressed: () => _editPublication(_publications.indexOf(pub)),
                                    tooltip: 'Modifier',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deletePublication(_publications.indexOf(pub)),
                                    tooltip: 'Supprimer',
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
        ],
      ),
      bottomNavigationBar: AmbassadorBottomNav(
        currentIndex: 1,
        onTap: (index) => handleAmbassadorNav(context, 1, index),
      ),
    );
  }
}
