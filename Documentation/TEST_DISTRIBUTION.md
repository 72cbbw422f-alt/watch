# Testdistribution – Watchlist

## Mål
Skapa en fysisk iOS Release-build i GitHub Actions, paketera den som en IPA och göra den tillgänglig som ett kortlivat byggartefakt.

## Automatisk IPA-byggning
Efter att workflow **iOS Build** har slutförts med resultatet success på grenen `main`, startas **Prepare unsigned iOS IPA** automatiskt. IPA-jobbet kontrollerar dessutom att den lyckade körningens commit fortfarande är den senaste committen på `main`. Äldre, inaktuella CI-körningar ska därför inte skapa extra IPA-byggen.

Workflow-filen är `.github/workflows/unsigned-ipa.yml`. Den kan även startas manuellt via workflow_dispatch vid behov.

Byggsteget:
- genererar Xcode-projektet med XcodeGen
- bygger Release för `generic/platform=iOS` med `CODE_SIGNING_ALLOWED=NO`
- paketerar `WATCHLIST.app` i en IPA
- laddar upp artefakten `watchlist-unsigned-ipa` i 14 dagar

## Viktigt om installation
Den här IPA-filen är **osignerad**. Den är ett bygg- och paketeringstest, inte en installationsklar app. iOS kräver giltig signering och en distributionsmetod som enheten accepterar.

Innan installation behöver vi välja och konfigurera en signeringsväg:
- Apple Developer-signering med giltigt certifikat och provisioning profile, eller
- en separat signeringstjänst som FlareStore, om den erbjuder ett giltigt certifikat/provisioning för aktuell enhet och appens bundle identifier.

Lägg aldrig certifikat, privata nycklar, provisioning-profiler eller tokens i repot. Om signering automatiseras ska känsliga värden lagras som skyddade GitHub Actions secrets.

## Appidentitet
- Bundle identifier: `se.niklas.watchlist`
- Minimum iOS: 17.0
- Scheme: `WATCHLIST`
- Configuration: `Release`

## Kvalitetsgrindar
- Simulatorbygge och enhetstester ska vara gröna.
- Enhetsbygget ska lyckas.
- IPA-artefakten ska finnas och vara icke-tom.
- Signerad IPA ska installeras och starta på fysisk iPhone innan vi kallar den en användbar testversion.

## Nuvarande begränsning
CI bygger och testar simulatorversionen. Därefter skapas en osignerad fysisk Release-IPA automatiskt. Ingen signering eller fysisk enhetsverifiering ingår ännu.
