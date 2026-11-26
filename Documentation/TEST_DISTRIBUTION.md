# Testdistribution – Watchlist

## Automatisk byggkedja
Efter att **iOS Build** har slutförts med resultatet success på `main`, startas **Prepare iOS IPA** automatiskt. Jobbet kontrollerar att CI-körningen avser den senaste committen på `main`, så äldre körningar inte ska skapa inaktuella paket.

Workflow-filen är `.github/workflows/unsigned-ipa.yml`. Den bygger först en osignerad Release-IPA och laddar upp artefakten `watchlist-unsigned-ipa` i 14 dagar.

## Automatisk signering (valfri)
Om samtliga tre GitHub Actions-secrets finns konfigurerade försöker samma workflow även skapa och verifiera en signerad IPA. Signeringen sker lokalt på GitHub Actions macOS-runnern; P12 och provisioning-profil skickas inte till någon extern signeringstjänst.

Lägg till följande repository secrets under **Settings → Secrets and variables → Actions**:

| Secret | Innehåll |
|---|---|
| `IOS_P12_BASE64` | P12-filen kodad som Base64 |
| `IOS_P12_PASSWORD` | Lösenordet till P12-filen |
| `IOS_PROVISION_PROFILE_BASE64` | Mobile Provision-profilen kodad som Base64 |

Base64 kan skapas på macOS/Linux med `base64 -i fil.p12` och `base64 -i fil.mobileprovision`. På Windows PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("fil.p12"))` respektive motsvarande profilfil. Klistra in hela resultatet i respektive secret. Ladda aldrig upp certifikaten eller lösenordet i repot, issues eller vanlig chatt.

Workflowet importerar P12 i en temporär låst keychain, läser profilens UUID och Team ID, väljer exportmetod utifrån profilen (Ad Hoc eller Enterprise), arkiverar och exporterar appen och verifierar signaturen. Den temporära keychainen och lokala signeringsfiler tas bort efter jobbet.

Om secrets saknas produceras fortfarande den osignerade IPA-filen. Om signeringen misslyckas ska vi kontrollera att:
- P12-certifikatet är giltigt och inte återkallat.
- Mobile Provision-profilen är giltig och matchar appens bundle ID `se.niklas.watchlist`.
- Profilen omfattar Niklas iPhones UDID om det är en Ad Hoc-profil.
- P12-lösenordet är korrekt och certifikatet innehåller en användbar privat nyckel.

## Appidentitet
- Bundle identifier: `se.niklas.watchlist`
- Minimum iOS: 17.0
- Scheme: `WATCHLIST`
- Configuration: `Release`

## Kvalitetsgrindar
- Simulatorbygge och enhetstester ska vara gröna.
- Enhetsbygget ska lyckas.
- IPA-artefakten ska finnas och vara icke-tom.
- Signerad IPA ska passera codesign-verifiering.
- Appen ska installeras och starta på fysisk iPhone innan vi kallar den en fungerande testversion.

## Viktig begränsning
En lyckad codesign-verifiering garanterar inte att iOS accepterar OTA-installation eller att appen fungerar på enheten. Det sista steget måste verifieras på den faktiska iPhonen.
