# v5 – Wasserdicht (Deliverable)

- Datenmodell: `workouts` (Summaries), `workouts/{id}/exercises` (Sets), `exercises` (Katalog), `pr_*`.
- Streams überall (Home, Detail, Dashboard, PR-Feed) → sofortiges Refresh.
- Quick Log: Autocomplete, optimistisches Save, Snackbars.
- Katalog: Duplikate unmöglich (DocID=normalisiert), CRUD + Direkt ins aktive Workout.
- Vorlagen beim Start (Push/Pull/Legs/Full Body).
- Rest-Timer pro Übung (90s).
- Summaries (exercisesCount/setsCount/volume) transaktional gepflegt → schnelles Dashboard.
- Offline-Persistence an; Lade-UX ohne Endlos-Spinner (Snackbars/Feedback).