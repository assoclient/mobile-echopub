import 'package:flutter/material.dart';
import 'ambassador_home.dart';
import 'ambassador_publications.dart';
import 'ambassador_gains.dart';
import 'ambassador_profil.dart';

void handleAmbassadorNav(BuildContext context, int currentIndex, int newIndex) {
  if (currentIndex == newIndex) return;
  switch (newIndex) {
    case 0:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AmbassadorHome()),
      );
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
}
