import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

// Test pour vérifier le calcul des statistiques d'audience
void main() {
  group('Audience Statistics Calculation', () {
    test('should calculate correct percentages for city distribution', () {
      // Simuler des données de contacts
      final mockContacts = [
        {'name': 'Contact 1', 'city': 'Douala', 'ageRange': '18-25', 'gender': 'M'},
        {'name': 'Contact 2', 'city': 'Douala', 'ageRange': '26-35', 'gender': 'F'},
        {'name': 'Contact 3', 'city': 'Yaoundé', 'ageRange': '18-25', 'gender': 'M'},
        {'name': 'Contact 4', 'city': 'Douala', 'ageRange': '36-45', 'gender': 'F'},
      ];

      // Calculer les statistiques
      final Map<String, Map<String, int>> stats = {
        'city': {},
        'age': {},
        'genre': {},
      };

      for (final contact in mockContacts) {
        stats['city']![contact['city']!] = (stats['city']![contact['city']!] ?? 0) + 1;
        stats['age']![contact['ageRange']!] = (stats['age']![contact['ageRange']!] ?? 0) + 1;
        stats['genre']![contact['gender']!] = (stats['genre']![contact['gender']!] ?? 0) + 1;
      }

      final int totalContacts = mockContacts.length;
      
      // Convertir en pourcentages
      final List<Map<String, dynamic>> cityStats = stats['city']!.entries.map((entry) {
        return {
          'pourcentage': ((entry.value / totalContacts) * 100).round(),
          'value': entry.key,
        };
      }).toList();

      // Vérifications
      expect(cityStats.length, 2); // Douala et Yaoundé
      
      final doualaStats = cityStats.firstWhere((stat) => stat['value'] == 'Douala');
      final yaoundeStats = cityStats.firstWhere((stat) => stat['value'] == 'Yaoundé');
      
      expect(doualaStats['pourcentage'], 75); // 3/4 = 75%
      expect(yaoundeStats['pourcentage'], 25); // 1/4 = 25%
    });

    test('should calculate correct percentages for age distribution', () {
      final mockContacts = [
        {'name': 'Contact 1', 'city': 'Douala', 'ageRange': '18-25', 'gender': 'M'},
        {'name': 'Contact 2', 'city': 'Douala', 'ageRange': '26-35', 'gender': 'F'},
        {'name': 'Contact 3', 'city': 'Yaoundé', 'ageRange': '18-25', 'gender': 'M'},
        {'name': 'Contact 4', 'city': 'Douala', 'ageRange': '36-45', 'gender': 'F'},
      ];

      final Map<String, Map<String, int>> stats = {
        'age': {},
      };

      for (final contact in mockContacts) {
        stats['age']![contact['ageRange']!] = (stats['age']![contact['ageRange']!] ?? 0) + 1;
      }

      final int totalContacts = mockContacts.length;
      
      final List<Map<String, dynamic>> ageStats = stats['age']!.entries.map((entry) {
        final ageRange = entry.key;
        final parts = ageRange.split('-');
        return {
          'pourcentage': ((entry.value / totalContacts) * 100).round(),
          'value': {
            'min': int.parse(parts[0]),
            'max': parts[1] == '+' ? 100 : int.parse(parts[1]),
          },
        };
      }).toList();

      expect(ageStats.length, 3); // 18-25, 26-35, 36-45
      
      final age18_25 = ageStats.firstWhere((stat) => stat['value']['min'] == 18 && stat['value']['max'] == 25);
      final age26_35 = ageStats.firstWhere((stat) => stat['value']['min'] == 26 && stat['value']['max'] == 35);
      final age36_45 = ageStats.firstWhere((stat) => stat['value']['min'] == 36 && stat['value']['max'] == 45);
      
      expect(age18_25['pourcentage'], 50); // 2/4 = 50%
      expect(age26_35['pourcentage'], 25); // 1/4 = 25%
      expect(age36_45['pourcentage'], 25); // 1/4 = 25%
    });

    test('should generate correct JSON structure', () {
      final mockContacts = [
        {'name': 'Contact 1', 'city': 'Douala', 'ageRange': '18-25', 'gender': 'M'},
        {'name': 'Contact 2', 'city': 'Douala', 'ageRange': '26-35', 'gender': 'F'},
      ];

      final Map<String, Map<String, int>> stats = {
        'city': {},
        'age': {},
        'genre': {},
      };

      for (final contact in mockContacts) {
        stats['city']![contact['city']!] = (stats['city']![contact['city']!] ?? 0) + 1;
        stats['age']![contact['ageRange']!] = (stats['age']![contact['ageRange']!] ?? 0) + 1;
        stats['genre']![contact['gender']!] = (stats['genre']![contact['gender']!] ?? 0) + 1;
      }

      final int totalContacts = mockContacts.length;
      
      final List<Map<String, dynamic>> cityStats = stats['city']!.entries.map((entry) {
        return {
          'pourcentage': ((entry.value / totalContacts) * 100).round(),
          'value': entry.key,
        };
      }).toList();

      final List<Map<String, dynamic>> ageStats = stats['age']!.entries.map((entry) {
        final ageRange = entry.key;
        final parts = ageRange.split('-');
        return {
          'pourcentage': ((entry.value / totalContacts) * 100).round(),
          'value': {
            'min': int.parse(parts[0]),
            'max': parts[1] == '+' ? 100 : int.parse(parts[1]),
          },
        };
      }).toList();

      final List<Map<String, dynamic>> genreStats = stats['genre']!.entries.map((entry) {
        return {
          'pourcentage': ((entry.value / totalContacts) * 100).round(),
          'value': entry.key,
        };
      }).toList();

      final result = {
        'audience': {
          'city': cityStats,
          'age': ageStats,
          'genre': genreStats,
        },
      };

      // Vérifier la structure JSON
      final jsonString = jsonEncode(result);
      final decoded = jsonDecode(jsonString);
      
      expect(decoded['audience'], isNotNull);
      expect(decoded['audience']['city'], isList);
      expect(decoded['audience']['age'], isList);
      expect(decoded['audience']['genre'], isList);
      
      // Vérifier que tous les pourcentages totalisent 100%
      final cityTotal = decoded['audience']['city'].fold<int>(0, (sum, item) => sum + item['pourcentage']);
      final ageTotal = decoded['audience']['age'].fold<int>(0, (sum, item) => sum + item['pourcentage']);
      final genreTotal = decoded['audience']['genre'].fold<int>(0, (sum, item) => sum + item['pourcentage']);
      
      expect(cityTotal, 100);
      expect(ageTotal, 100);
      expect(genreTotal, 100);
    });
  });
}
