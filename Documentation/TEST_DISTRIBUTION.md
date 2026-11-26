# Testdistribution – Watchlist

## Mål
Skapa en fysisk iOS Release-build i GitHub Actions, paketera den som en IPA och göra den tillgänglig som ett kortlivat byggartefakt.

## Skapa en osignerad IPA
1. Öppna repositoryts GitHub Actions.
2. Välj workflow **Prepare unsigned iOS IPA**.
3. Tryck **Run workflow** på grenen \`main\`.
4. Vänta tills jobbet är klart.
5. Öppna körningen och hämta artefakten \`watchlist-unsigned-ipa\`.

Workflow-filen är \`.github/workflows/unsigned-ipa.yml\`. Den bygger Release för \`generic/platform=iOS\` med \`CODE_SIGNING_ALLOWED=NO\`, paketerar \`WATCHLIST.app\` i en IPA och laddar upp artefakten i 14 dagar.

## Viktigt om installation
Den här IPA-filen är **osignerad**. Den är ett bygg- och paketeringstest, inte en installationsklar app. iOS kräver giltig signering och en distributionsmetod som enheten accepterar.

Innan installation behöver vi välja och konfigurera en signeringsväg:
- Apple Developer-signering med giltigt certifikat och provisioning profile, eller
- en separat signeringstjänst som FlareStore, om den erbjuder ett giltigt certifikat/provisioning för aktuell enhet och appens bundle identifier.

Lägg aldrig certifikat, privata nycklar, provisioning-profiler eller tokens i repot. Om signering automatiseras ska känsliga värden lagras som skyddade GitHub Actions secrets.

## Appidentitet
- Bundle identifier: \`se.niklas.watchlist\`
- Minimum iOS: 17.0
- Scheme: \`WATCHLIST\`
- Configuration: \`Release\`

## Kvalitetsgrindar
- Simulatorbygge och enhetstester ska vara gröna.
- Enhetsbygget ska lyckas.
- IPA-artefakten ska finnas och vara icke-tom.
- Signerad IPA ska installeras och starta på fysisk iPhone innan vi kallar den en användbar testversion.

## Begränsning i nuvarande läge
Det automatiska CI-arbetsflödet bygger och testar simulatorversionen. IPA-arbetsflödet startas separat manuellt. Ingen signering eller fysisk enhetsverifiering ingår ännu.
