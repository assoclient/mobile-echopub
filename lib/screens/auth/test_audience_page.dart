import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme.dart';

class TestAudiencePage extends StatefulWidget {
  const TestAudiencePage({Key? key}) : super(key: key);

  @override
  State<TestAudiencePage> createState() => _TestAudiencePageState();
}

class _TestAudiencePageState extends State<TestAudiencePage> {
  Map<String, dynamic> _audienceData = {};

  @override
  void initState() {
    super.initState();
    _generateSampleAudienceData();
  }

  void _generateSampleAudienceData() {
    // Exemple de données d'audience basées sur des contacts
    _audienceData = {
      'city': [
        {'pourcentage': 60, 'value': 'Douala'},
        {'pourcentage': 25, 'value': 'Yaoundé'},
        {'pourcentage': 15, 'value': 'Bafoussam'},
      ],
      'age': [
        {'pourcentage': 40, 'value': {'min': 18, 'max': 25}},
        {'pourcentage': 35, 'value': {'min': 26, 'max': 35}},
        {'pourcentage': 20, 'value': {'min': 36, 'max': 45}},
        {'pourcentage': 5, 'value': {'min': 46, 'max': 55}},
      ],
      'genre': [
        {'pourcentage': 55, 'value': 'M'},
        {'pourcentage': 45, 'value': 'F'},
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Test - Données d\'audience'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Structure des données d\'audience',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ces données seront envoyées au backend lors de l\'inscription d\'un ambassadeur :',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection('Villes', _audienceData['city']),
                    const SizedBox(height: 16),
                    _buildSection('Âges', _audienceData['age']),
                    const SizedBox(height: 16),
                    _buildSection('Genres', _audienceData['genre']),
                    const SizedBox(height: 24),
                    Card(
                      color: AppColors.softGreen,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'JSON complet',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                const JsonEncoder.withIndent('  ').convert(_audienceData),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            ...data.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: (item['pourcentage'] as num).toInt(),
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '${item['pourcentage']}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 100 - (item['pourcentage'] as num).toInt(),
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title == 'Âges' 
                        ? '${item['value']['min']}-${item['value']['max']} ans'
                        : item['value'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
} 