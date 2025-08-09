# Debug - Bouton Flottant Android

## 🔍 Diagnostics à Vérifier

### **1. Vérifier les Logs Android**
```bash
# Connecter le device et voir les logs en temps réel
adb logcat | grep -E "(ScreenshotService|MainActivity)"

# Ou filtrer uniquement notre app
adb logcat | grep "com.example.mobile"
```

### **2. Vérifier les Permissions**
```bash
# Vérifier si la permission overlay est accordée
adb shell dumpsys package com.example.mobile | grep -A 3 -B 3 "SYSTEM_ALERT_WINDOW"
```

### **3. Étapes de Test**

#### **Étape 1 : Démarrage du Service**
1. Ouvrir l'app Flutter
2. Aller dans Publications Ambassadeur
3. Cliquer "Remplacer" sur une preuve
4. Choisir "Capture automatique"
5. **Vérifier logs** : `"Bouton flottant démarré"`

#### **Étape 2 : Test du Clic**
1. Chercher le bouton flottant bleu sur l'écran
2. **Tap simple** (pas de glissement)
3. **Vérifier logs** : 
   - `"ACTION_UP - deltaX: X, deltaY: Y"`
   - `"Clic détecté sur le bouton flottant"`
   - `"Tentative de capture d'écran"`

#### **Étape 3 : MediaProjection**
1. Si pas de MediaProjection : Dialog de permission
2. **Accepter** la permission
3. **Vérifier logs** : 
   - `"MediaProjection obtenue et stockée"`
   - `"MediaProjection prête, tentative de capture"`

## 🛠️ Corrections Apportées

### **1. MediaProjectionManager Singleton**
- ✅ Stockage centralisé de MediaProjection
- ✅ Communication entre MainActivity et Service
- ✅ Nettoyage automatique des ressources

### **2. Logs de Debug Améliorés**
- ✅ Logs détaillés pour chaque étape
- ✅ Coordonnées de touch pour diagnostiquer
- ✅ États de MediaProjection tracés

### **3. Gestion d'Événements**
- ✅ Événement immédiat au clic pour feedback
- ✅ Gestion des erreurs améliorée
- ✅ Communication Flutter optimisée

## 🚨 Problèmes Possibles

### **A. Bouton Invisible**
- Vérifier permission `SYSTEM_ALERT_WINDOW`
- Bouton peut être hors écran (coordonnées initiales)
- Overlay peut être bloqué par d'autres apps

### **B. Clic Non Détecté**
- Seuil de détection trop strict (deltaX/Y < 10)
- TouchListener mal configuré
- View pas correctement attachée

### **C. MediaProjection Échoue**
- Permission refusée par l'utilisateur
- Service pas encore démarré
- Singleton pas initialisé

## 🔧 Tests Rapides

### **Test 1 : Visibilité du Bouton**
```kotlin
// Dans startFloatingButton(), ajouter temporairement :
Log.d(TAG, "Position bouton - x: ${params.x}, y: ${params.y}")
```

### **Test 2 : Touch Events**
```kotlin
// Dans onTouchListener, ajouter :
Log.d(TAG, "Touch event: ${event.action}")
```

### **Test 3 : MediaProjection Status**
```kotlin
// Dans takeScreenshot(), ajouter :
Log.d(TAG, "MediaProjection status: ${mediaProjection != null}")
```

## ✅ Actions Immédiates

1. **Lancer l'app** et tester
2. **Vérifier logs** avec `adb logcat`
3. **Confirmer permission** overlay dans Paramètres
4. **Tester clic simple** sur bouton bleu
5. **Accepter permission** MediaProjection si demandée

Si le bouton n'apparaît pas du tout → **Problème de permission**
Si le bouton apparaît mais clic ne fonctionne pas → **Problème TouchListener**
Si le clic fonctionne mais pas de capture → **Problème MediaProjection**
