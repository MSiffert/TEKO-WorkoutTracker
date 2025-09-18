# Workout Tracker – Patch Notes

**Was wurde gefixt/optimiert (Kurzfassung):**
- Saubere Themes (Material 3, Light/Dark, `ColorScheme.fromSeed`).
- Splash/Wartezustand im `AuthGate` hinzugefügt.
- Login als echtes `Form` mit Validierung, Fehlerausgabe, Controller-Dispose, anonymem Login-Button.
- Stabiles `HomeScreen`-Layout mit `NavigationBar` + `IndexedStack` für State-Persistenz.
- `pubspec.yaml` bereinigt: Firebase-Libs in `dependencies`, `flutter_lints` aktiviert.
- `analysis_options.yaml` hinzugefügt (striktere Lints).
- Vorbereitet für Riverpod/GoRouter (noch nicht zwingend genutzt, um simpel zu bleiben).

**Was du tun musst:**
1) In diesem Ordner `flutter pub get`.
2) iOS/Android-Firebase-Setup sicherstellen (Google-Services-Dateien vorhanden).
3) App starten.

**Nächste sinnvolle Schritte:**
- Firestore-Zugriffe in Repositories bündeln (bereits teilweise vorhanden).
- Einheitliche UX-Patterns (Snackbars, Dialoge, Loading-States) in Widgets extrahieren.
- E2E-Test für Auth-Flow und ein Minimallog.
