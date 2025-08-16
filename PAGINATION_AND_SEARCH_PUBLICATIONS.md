# 🔍 Pagination et Recherche - Ambassador Publications

## 📋 Vue d'ensemble

Ce document décrit les nouvelles fonctionnalités de pagination et de recherche ajoutées à la page `ambassador_publications.dart` pour améliorer l'expérience utilisateur et les performances lors de la consultation des publications.

## ✨ Nouvelles Fonctionnalités

### **🔍 Recherche Avancée**
- **Recherche en temps réel** avec debounce de 500ms
- **Recherche dans le titre** des campagnes publiées
- **Indicateur de résultats** affichant le nombre de publications trouvées
- **Bouton de suppression** (X) pour effacer rapidement la recherche
- **Recherche côté serveur** pour les vraies données API

### **📄 Pagination Intelligente**
- **Scroll infini** avec chargement automatique
- **Taille de page configurable** (actuellement 10 publications)
- **Indicateur de chargement** en bas de liste
- **Gestion des états** (chargement, erreur, fin des données)
- **Navigation entre pages** (précédent/suivant)
- **Informations de pagination** en bas d'écran

### **⚡ Optimisations de Performance**
- **Debounce sur la recherche** pour éviter les appels API excessifs
- **Chargement progressif** des données
- **Gestion de la mémoire** avec nettoyage des contrôleurs
- **Cache des données** pour éviter les rechargements inutiles

## 🔧 Configuration Technique

### **Variables d'État Ajoutées**
```dart
// Pagination
bool _isLoadingMore = false;
int _pageSize = 10;
final ScrollController _scrollController = ScrollController();

// Recherche avec debounce
Timer? _searchDebounce;
String _lastSearchQuery = '';
```

### **Nouvelles Méthodes**
- `_setupScrollListener()` - Configuration du scroll infini
- `_onSearchChanged()` - Gestion de la recherche avec debounce
- `_resetPagination()` - Réinitialisation de la pagination
- `_loadMorePublications()` - Chargement de plus de données
- `_buildLoadingIndicator()` - Indicateur de chargement
- `_buildPaginationInfo()` - Informations de pagination

## 🎯 Utilisation

### **1. Recherche**
- **Tapez dans la barre de recherche** pour filtrer les publications
- **Attendez 500ms** pour que la recherche se déclenche
- **Voyez le nombre de résultats** affiché sous la barre
- **Utilisez le bouton X** pour effacer la recherche

### **2. Pagination**
- **Scrollez vers le bas** pour charger plus de publications
- **Attendez le chargement** automatique des nouvelles données
- **Voyez l'indicateur** de chargement en bas
- **Utilisez les boutons** Précédent/Suivant si disponibles

### **3. Filtres de Date**
- **Sélectionnez une date de début** pour filtrer par période
- **Sélectionnez une date de fin** pour délimiter la recherche
- **Utilisez le bouton de réinitialisation** pour effacer les filtres
- **Combinez avec la recherche** pour des résultats précis

### **4. Rafraîchissement**
- **Cliquez sur l'icône de rafraîchissement** dans l'AppBar
- **La pagination se réinitialise** automatiquement
- **Toutes les données sont rechargées** depuis le début

## 📱 Interface Utilisateur

### **Barre de Recherche Améliorée**
- **Icône de recherche** à gauche
- **Bouton de suppression** à droite (quand il y a du texte)
- **Placeholder dynamique** "Rechercher par titre..."
- **Style cohérent** avec le thème de l'application

### **Indicateur de Statut de Recherche**
- **Affichage du nombre de résultats** trouvés
- **Nom de la recherche** actuelle
- **Style visuel distinctif** avec couleur primaire
- **Apparition/disparition** conditionnelle

### **Indicateur de Chargement**
- **Spinner circulaire** avec couleur primaire
- **Texte explicatif** "Chargement de plus de publications..."
- **Position en bas** de la liste
- **Gestion des états** (chargement, fin des données)

### **Informations de Pagination**
- **Page actuelle** et nombre total de publications
- **Boutons de navigation** (Précédent/Suivant)
- **Style cohérent** avec le reste de l'interface
- **Position en bas** de l'écran

## 🔄 Flux de Données

### **Chargement Initial**
1. **Première page** : 10 publications
2. **Mise à jour de l'état** : `_currentPage = 1`, `_hasMore = true`
3. **Affichage des données** avec indicateurs de statut

### **Scroll Infini**
1. **Détection du scroll** vers le bas (200px avant la fin)
2. **Chargement automatique** de la page suivante
3. **Ajout des nouvelles données** à la liste existante
4. **Mise à jour de l'état** : `_currentPage++`, vérification de `_hasMore`

### **Recherche avec Debounce**
1. **Saisie utilisateur** dans la barre de recherche
2. **Annulation du timer précédent** (500ms)
3. **Démarrage d'un nouveau timer** de 500ms
4. **Exécution de la recherche** si le texte a changé
5. **Réinitialisation de la pagination** et rechargement

## 🚀 API Backend

### **Paramètres de Requête**
```
GET /api/ambassador-publications/my-publications
  ?page=1&pageSize=10&search=terme_recherche
```

### **Réponse Attendue**
```json
{
  "data": [...],
  "totalCount": 45,
  "pagination": {
    "currentPage": 1,
    "totalPages": 5,
    "hasMore": true
  }
}
```

## 🎨 Personnalisation

### **Modifier la Taille de Page**
```dart
int _pageSize = 20; // Au lieu de 10
```

### **Modifier le Debounce de Recherche**
```dart
Timer(const Duration(milliseconds: 1000), () { // Au lieu de 500
```

### **Modifier le Seuil de Scroll**
```dart
if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) { // Au lieu de 200
```

## 🔍 Dépannage

### **Problèmes Courants**

1. **Recherche ne fonctionne pas**
   - Vérifiez que le debounce est configuré
   - Vérifiez la connexion API
   - Vérifiez les paramètres de recherche

2. **Pagination bloquée**
   - Vérifiez que `_hasMore` est correctement mis à jour
   - Vérifiez le ScrollController
   - Vérifiez les appels API

3. **Performances lentes**
   - Réduisez la taille de page
   - Augmentez le debounce de recherche
   - Vérifiez la qualité de la connexion

4. **Filtres de date non fonctionnels**
   - Vérifiez le format des dates
   - Vérifiez la logique de filtrage
   - Vérifiez la conversion des dates

### **Debug**
```dart
debugPrint('Page actuelle: $_currentPage');
debugPrint('Recherche: $_search');
debugPrint('Plus de données: $_hasMore');
debugPrint('Total: $_totalCount');
```

## 🔮 Évolutions Futures

- [ ] **Filtres avancés** (statut de validation, gains, vues)
- [ ] **Tri des résultats** (date, popularité, gains)
- [ ] **Sauvegarde des préférences** de recherche et filtres
- [ ] **Mode hors ligne** avec cache local
- [ ] **Synchronisation** des données en arrière-plan
- [ ] **Export des données** (PDF, Excel)

## 💡 Conseils d'Utilisation

1. **Utilisez des termes spécifiques** pour la recherche
2. **Laissez le scroll infini** charger automatiquement
3. **Utilisez les filtres de date** pour des recherches ciblées
4. **Utilisez le rafraîchissement** pour les nouvelles publications
5. **Surveillez l'indicateur** de chargement pour l'état
6. **Testez sur différents appareils** pour la performance

## 📚 Ressources

- **Flutter ScrollController** : [Documentation officielle](https://api.flutter.dev/flutter/widgets/ScrollController-class.html)
- **Flutter Timer** : [Documentation officielle](https://api.flutter.dev/flutter/dart-async/Timer-class.html)
- **Flutter ListView.builder** : [Documentation officielle](https://api.flutter.dev/flutter/widgets/ListView/ListView.builder.html)
- **Material Design** : [Guidelines de recherche](https://material.io/design/patterns/search.html)
- **Flutter DatePicker** : [Documentation officielle](https://api.flutter.dev/flutter/material/showDatePicker.html)
