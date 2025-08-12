import 'package:flutter/material.dart';

void handleAdvertiserNav(BuildContext context, int currentIndex, int newIndex) {
  if (currentIndex == newIndex) return;

  switch (newIndex) {
    case 0:
      Navigator.pushReplacementNamed(context, '/advertiser/dashboard');
      break;
    case 1:
      // Mes campagnes
      Navigator.pushReplacementNamed(context, '/advertiser');
      break;
    case 2:
      // Créer une campagne
      Navigator.pushReplacementNamed(context, '/advertiser/create-campaign');
      break;
    case 3:
      // Profil
      Navigator.pushReplacementNamed(context, '/advertiser/profile');
      break;
  }
}
