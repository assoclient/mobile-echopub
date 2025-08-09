# Collecte des Statistiques d'Audience - Fonctionnalité Mobile

## Vue d'ensemble

Cette fonctionnalité permet aux ambassadeurs de collecter automatiquement les statistiques d'audience de leur réseau WhatsApp lors de l'inscription. L'application accède aux contacts de l'utilisateur et génère des statistiques détaillées sur la démographie de leur audience.

## Fonctionnalités

### 1. Demande de Permission
- L'application demande l'accès aux contacts de l'utilisateur
- Gestion des cas où la permission est refusée
- Interface utilisateur claire pour expliquer l'utilisation des données

### 2. Collecte des Données
- **Nom du contact**: Récupéré automatiquement depuis les contacts
- **Tranche d'âge**: Pré-remplie avec "18-25" (modifiable)
  - Options: 18-25, 26-35, 36-45, 46-55, 56+
- **Genre**: Pré-rempli avec "M" (modifiable)
  - Options: M, F
- **Ville**: Pré-remplie avec "Douala" (modifiable)
  - Liste complète des villes du Cameroun depuis `cities_cm.json`

### 3. Interface Utilisateur
- Liste scrollable des contacts (limité à 50 contacts)
- Dropdowns modifiables pour chaque contact
- Interface intuitive avec des cartes pour chaque contact
- Bouton de validation pour terminer l'inscription

### 4. Calcul des Statistiques
L'application génère automatiquement un objet JSON avec la structure suivante:

```json
{
  "audience": {
    "city": [
      {"pourcentage": 25, "value": "Douala"},
      {"pourcentage": 15, "value": "Yaoundé"}
    ],
    "age": [
      {"pourcentage": 40, "value": {"min": 18, "max": 25}},
      {"pourcentage": 30, "value": {"min": 26, "max": 35}}
    ],
    "genre": [
      {"pourcentage": 60, "value": "M"},
      {"pourcentage": 40, "value": "F"}
    ]
  }
}
```

## Flux d'Utilisation

### Pour les Ambassadeurs:
1. Remplir le formulaire d'inscription de base
2. Cliquer sur "Créer un compte"
3. Être redirigé vers la page de collecte d'audience
4. Autoriser l'accès aux contacts
5. Modifier les données selon les connaissances de l'utilisateur
6. Cliquer sur "Terminer l'inscription"
7. Les données sont envoyées au backend avec les statistiques d'audience

### Pour les Annonceurs:
1. Remplir le formulaire d'inscription
2. Cliquer sur "Créer un compte"
3. Inscription directe sans collecte d'audience

## Permissions Requises

### Android:
```xml
<uses-permission android:name="android.permission.READ_CONTACTS"/>
```

### iOS:
```xml
<key>NSContactsUsageDescription</key>
<string>Cette application a besoin d'accéder à vos contacts pour collecter les statistiques d'audience de votre réseau WhatsApp.</string>
```

## Dépendances Ajoutées

```yaml
dependencies:
  flutter_contacts: ^1.1.7+1
  permission_handler: ^11.3.1
```

## Structure des Fichiers

- `lib/screens/auth/audience_collection_page.dart` - Page principale de collecte
- `lib/screens/auth/register_page.dart` - Modifié pour intégrer la collecte
- `assets/cities_cm.json` - Liste des villes du Cameroun

## Gestion des Erreurs

- Permission refusée: Affichage d'un message d'erreur avec option de réessayer
- Erreur de chargement des contacts: Message d'erreur explicite
- Erreur de chargement des villes: Utilisation de valeurs par défaut

## Sécurité et Confidentialité

- Les contacts ne sont utilisés que localement pour calculer les statistiques
- Aucune donnée personnelle n'est stockée ou transmise
- Seules les statistiques agrégées sont envoyées au backend
- L'utilisateur peut modifier toutes les données avant soumission

## Intégration Backend

Les données d'audience sont automatiquement ajoutées à la requête d'inscription:

```json
{
  "name": "Nom de l'ambassadeur",
  "email": "email@example.com",
  "password": "motdepasse",
  "role": "ambassador",
  "whatsapp_number": "+237XXXXXXXXX",
  "location": {...},
  "audience": {
    "city": [...],
    "age": [...],
    "genre": [...]
  }
}
```

## Avantages

1. **Automatisation**: Collecte automatique des contacts
2. **Précision**: Données démographiques détaillées
3. **Flexibilité**: Possibilité de modifier toutes les données
4. **Simplicité**: Interface intuitive et facile à utiliser
5. **Intégration**: S'intègre parfaitement au flux d'inscription existant
