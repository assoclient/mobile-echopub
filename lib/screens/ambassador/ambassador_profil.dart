import 'package:mobile/services/auth_service.dart';

import '../../components/ambassador_bottom_nav.dart';
import 'ambassador_nav_helper.dart';
import 'package:flutter/material.dart';
import '../../theme.dart';

class AmbassadorProfilPage extends StatefulWidget {
  const AmbassadorProfilPage({Key? key}) : super(key: key);

  @override
  State<AmbassadorProfilPage> createState() => _AmbassadorProfilPageState();
}

class _AmbassadorProfilPageState extends State<AmbassadorProfilPage> {
  String _nom = 'Jean Dupont';
  String _telephone = '+237 699 00 00 00';
  String _ville = 'Douala';
  String _region = 'Littoral';
  double _latitude = 4.0511;
  double _longitude = 9.7679;

  Future<void> _updateLocation() async {
    // Simule la récupération de la position actuelle (remplacer par geolocator/geocoding en prod)
    setState(() {
      _latitude = 4.05 + (DateTime.now().second / 1000);
      _longitude = 9.76 + (DateTime.now().second / 1000);
      _ville = 'Ville MAJ';
      _region = 'Région MAJ';
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Localisation mise à jour.')));
  }

  void _deconnexion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AuthService.clear();
              // TODO: Rediriger vers la page de connexion
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Déconnecté.')));
            },
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                        child: const Icon(Icons.person, size: 48, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 20),
                      Text(_nom, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone, size: 18, color: AppColors.primaryBlue),
                          const SizedBox(width: 6),
                          Text(_telephone, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_city, size: 18, color: AppColors.primaryBlue),
                          const SizedBox(width: 6),
                          Text('Ville : $_ville', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.map, size: 18, color: AppColors.primaryBlue),
                          const SizedBox(width: 6),
                          Text('Région : $_region', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.my_location, size: 18, color: AppColors.primaryBlue),
                          const SizedBox(width: 6),
                          Text('Lat : ${_latitude.toStringAsFixed(5)}', style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 12),
                          Text('Long : ${_longitude.toStringAsFixed(5)}', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _updateLocation,
                        icon: const Icon(Icons.gps_fixed,color: Colors.white,),
                        label: const Text('Mettre à jour ma position'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(200, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _deconnexion,
                        icon: const Icon(Icons.logout,color: Colors.white,),
                        label: const Text('Se déconnecter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(180, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      bottomNavigationBar: AmbassadorBottomNav(
        currentIndex: 3,
        onTap: (index) => handleAmbassadorNav(context, 3, index),
      ),
    );
  }
}
