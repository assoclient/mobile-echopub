# 🔍 Pagination et Recherche - Ambassador Home

## 📋 Vue d'ensemble

Ce document décrit les nouvelles fonctionnalités de pagination et de recherche ajoutées à la page `ambassador_home.dart` pour améliorer l'expérience utilisateur et les performances.

## ✨ Nouvelles Fonctionnalités

### **🔍 Recherche Avancée**
- **Recherche en temps réel** avec debounce de 500ms
- **Recherche dans le titre et la description** des campagnes
- **Indicateur de résultats** affichant le nombre de campagnes trouvées
- **Bouton de suppression** pour effacer rapidement la recherche
- **Recherche côté serveur** pour les vraies données API

### **📄 Pagination Intelligente**
- **Scroll infini** avec chargement automatique
- **Taille de page configurable** (actuellement 10 campagnes)
- **Indicateur de chargement** en bas de liste
- **Gestion des états** (chargement, erreur, fin des données)
- **Navigation entre pages** (précédent/suivant)

### **⚡ Optimisations de Performance**
- **Debounce sur la recherche** pour éviter les appels API excessifs
- **Chargement progressif** des données
- **Gestion de la mémoire** avec nettoyage des contrôleurs
- **Cache des contrôleurs vidéo** pour éviter la réinitialisation

## 🔧 Configuration Technique

### **Variables d'État Ajoutées**
```dart
// Pagination
int _currentPage = 1;
int _pageSize = 10;
bool _hasMoreData = true;
final ScrollController _scrollController = ScrollController();

// Recherche avec debounce
Timer? _searchDebounce;
String _lastSearchQuery = '';
```

### **Nouvelles Méthodes**
- `_setupScrollListener()` - Configuration du scroll infini
- `_onSearchChanged()` - Gestion de la recherche avec debounce
- `_resetPagination()` - Réinitialisation de la pagination
- `_loadMoreCampaigns()` - Chargement de plus de données
- `_buildLoadingIndicator()` - Indicateur de chargement
- `_buildPaginationInfo()` - Informations de pagination

## 🎯 Utilisation

### **1. Recherche**
- **Tapez dans la barre de recherche** pour filtrer les campagnes
- **Attendez 500ms** pour que la recherche se déclenche
- **Voyez le nombre de résultats** affiché sous la barre
- **Utilisez le bouton X** pour effacer la recherche

### **2. Pagination**
- **Scrollez vers le bas** pour charger plus de campagnes
- **Attendez le chargement** automatique des nouvelles données
- **Voyez l'indicateur** de chargement en bas
- **Utilisez les boutons** Précédent/Suivant si disponibles

### **3. Rafraîchissement**
- **Cliquez sur l'icône de rafraîchissement** dans l'AppBar
- **La pagination se réinitialise** automatiquement
- **Toutes les données sont rechargées** depuis le début

## 📱 Interface Utilisateur

### **Barre de Recherche Améliorée**
- **Icône de recherche** à gauche
- **Bouton de suppression** à droite (quand il y a du texte)
- **Placeholder dynamique** "Rechercher une campagne..."
- **Style cohérent** avec le thème de l'application

### **Indicateur de Statut de Recherche**
- **Affichage du nombre de résultats** trouvés
- **Nom de la recherche** actuelle
- **Style visuel distinctif** avec couleur primaire
- **Apparition/disparition** conditionnelle

### **Indicateur de Chargement**
- **Spinner circulaire** avec couleur primaire
- **Texte explicatif** "Chargement de plus de campagnes..."
- **Position en bas** de la liste
- **Gestion des états** (chargement, fin des données)

## 🔄 Flux de Données

### **Mode Debug (Données Simulées)**
1. **Chargement initial** : 4 campagnes
2. **Scroll infini** : 2 campagnes supplémentaires
3. **Fin des données** : Plus de campagnes disponibles

### **Mode API (Données Réelles)**
1. **Chargement initial** : 10 campagnes (page 1)
2. **Scroll infini** : 10 campagnes supplémentaires (page 2)
3. **Continuité** : Pages suivantes selon la disponibilité

## 🚀 API Backend

### **Paramètres de Requête**
```
GET /api/ambassador-campaigns/active-campaigns/
  ?page=1&limit=10&search=terme_recherche
```

### **Réponse Attendue**
```json
{
  "data": [...],
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
   - Vérifiez que `_hasMoreData` est correctement mis à jour
   - Vérifiez le ScrollController
   - Vérifiez les appels API

3. **Performances lentes**
   - Réduisez la taille de page
   - Augmentez le debounce de recherche
   - Vérifiez la qualité de la connexion

### **Debug**
```dart
debugPrint('Page actuelle: $_currentPage');
debugPrint('Recherche: $_search');
debugPrint('Plus de données: $_hasMoreData');
```

## 🔮 Évolutions Futures

- [ ] **Filtres avancés** (statut, date, localisation)
- [ ] **Tri des résultats** (date, popularité, gains)
- [ ] **Sauvegarde des préférences** de recherche
- [ ] **Mode hors ligne** avec cache local
- [ ] **Synchronisation** des données en arrière-plan

## 💡 Conseils d'Utilisation

1. **Utilisez des termes spécifiques** pour la recherche
2. **Laissez le scroll infini** charger automatiquement
3. **Utilisez le rafraîchissement** pour les nouvelles campagnes
4. **Surveillez l'indicateur** de chargement pour l'état
5. **Testez sur différents appareils** pour la performance

## 📚 Ressources

- **Flutter ScrollController** : [Documentation officielle](https://api.flutter.dev/flutter/widgets/ScrollController-class.html)
- **Flutter Timer** : [Documentation officielle](https://api.flutter.dev/flutter/dart-async/Timer-class.html)
- **Flutter ListView.builder** : [Documentation officielle](https://api.flutter.dev/flutter/widgets/ListView/ListView.builder.html)
- **Material Design** : [Guidelines de recherche](https://material.io/design/patterns/search.html)
