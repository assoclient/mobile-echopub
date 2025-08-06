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
        SnackBar(
          content: Text('Capture ${captureNum == 1 ? "initiale" : "18h"} enregistrée.'),
          backgroundColor: AppColors.primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Modifier la publication', style: TextStyle(fontWeight: FontWeight.w600)),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Titre',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
            child: filtered.isEmpty
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
                          'Aucune publication',
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
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
                              // Header with title and actions
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      pub['title'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editPublication(_publications.indexOf(pub));
                                      } else if (value == 'delete') {
                                        _deletePublication(_publications.indexOf(pub));
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, color: Colors.orange, size: 20),
                                            SizedBox(width: 8),
                                            Text('Modifier'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.red, size: 20),
                                            SizedBox(width: 8),
                                            Text('Supprimer'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
                                      title: 'Preuve initiale',
                                      imageUrl: pub['capture1'],
                                      onTap: () => _pickCapture(_publications.indexOf(pub), 1),
                                      isInitial: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildProofSection(
                                      title: 'Preuve 18h',
                                      imageUrl: pub['capture2'],
                                      onTap: () => _pickCapture(_publications.indexOf(pub), 2),
                                      isInitial: false,
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
          if (imageUrl != null)
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
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
