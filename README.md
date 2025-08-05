# mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Application Flutter Ambassadeur & Annonceur

Ce projet Flutter propose une base pour deux rôles : ambassadeur et annonceur.

## Fonctionnalités prévues
- Authentification JWT (connexion via API backend Node.js)
- Navigation dédiée selon le rôle (accueil ambassadeur ou annonceur)
- Structure modulaire (séparation des écrans et services par rôle)
- Intégration API pour les campagnes, statuts, transactions, etc.

## Lancement du projet

1. Installez les dépendances :
   ```
   flutter pub get
   ```
2. Lancez l’application :
   ```
   flutter run
   ```

## Structure recommandée
- `lib/screens/ambassador/` : écrans ambassadeur
- `lib/screens/advertiser/` : écrans annonceur
- `lib/services/` : appels API, gestion auth, etc.
- `lib/widgets/` : composants réutilisables

## Personnalisation
Adaptez les écrans, la navigation et les services selon vos besoins métier.

---

Pour toute question sur l’architecture ou l’intégration, demandez à Copilot !
