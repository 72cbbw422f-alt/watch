# Watchlist – IPA och testdistribution

## Automatisk byggning
När **iOS Build** har slutförts med resultatet success på `main`, startas **Build Watchlist IPA** automatiskt. Workflowet kontrollerar att CI-körningen avser senaste committen på `main`.

Det går även att starta IPA-workflowet manuellt via `workflow_dispatch`.

## Hämta IPA för FlareStore
1. Öppna repositoryts GitHub Actions.
2. Välj senaste lyckade körningen av **Build Watchlist IPA**.
3. Hämta artefakten `watchlist-ipa`.
4. Packa upp ZIP-filen. Den innehåller `Watchlist.ipa`.
5. Importera IPA-filen i FlareStore och signera där enligt FlareStores instruktioner.

IPA:n byggs för fysisk iOS-enhet, Release, arm64, med bundle identifier `se.niklas.watchlist` och minimum iOS 17.0.

## Viktigt
IPA-filen från GitHub är avsiktligt osignerad. Den är avsedd att signeras i FlareStore. GitHub-workflowet hanterar inte certifikat, provisioning-profiler eller privata nycklar.

## Kvalitetsgrindar
- Simulatorbygge och enhetstester ska vara gröna.
- Release-bygget för fysisk iOS-enhet ska lyckas.
- IPA-strukturen ska kunna packas upp.
- Bundle identifier, minimum iOS-version och arm64-exekverbar fil verifieras automatiskt.
- Efter FlareStore-signering ska appen installeras och starta på fysisk iPhone innan den betraktas som färdig testdistribution.
