# WATCHLIST – produktkrav och utvecklingsplan

Senast uppdaterad: 2026-11-27

Detta dokument är projektets beständiga kravspecifikation. Nya utvecklingspass ska läsa och uppdatera dokumentet i stället för att förlita sig på lösryckta chattmeddelanden.

## Produktvision

WATCHLIST ska vara en komplett, personlig film- och serietjänst: upptäckt, bibliotek, tittarhistorik, serieprogress, premiärbevakning och rik titelinformation. Det ska kännas som en färdig premiumapp, inte en enkel lista med filmaffischer.

## Visuell riktning

- iPhone först; iPad ska fungera responsivt.
- Mörk, filmisk premiumdesign.
- Bas: svart, grafit och kolgrått. Accent: orange.
- Ingen grön accent som del av WATCHLISTs visuella profil.
- Tydlig typografisk hierarki, högkvalitativa affischer/bakgrunder, väl avvägd luft och konsekventa komponenter.
- Inspireras av BingeBases informationsdjup och navigering, men kopiera inte deras gränssnitt. Behåll WATCHLISTs egen identitet.
- Vågräta hyllor/karuseller där det minskar vertikal överbelastning.

## Startsida

- Hero-karusell med flera populära, nya och kommande filmer och serier; inte en enda statisk titel.
- Balansera filmer och serier i alla rekommendationsytor.
- Sektioner: Fortsätt titta, Pågående serier, Up Next, Ikväll kanske?, Trendande, Populärt, För dig, Dolda pärlor, Nya på streaming, Kommande premiärer och Din lista.
- Varje hylla ska kunna öppnas via Visa alla till en egen fullständig lista med relevant sortering och filter.
- Fortsätt titta visar titlar med statusen Tittar på och för serier visas nästa osedda avsnitt utifrån sparad avsnittsprogress.\n- Up Next visar osedda filmer och serier som sparats i biblioteket (Vill se och Bevakar), men inte titlar som redan är Tittar på eller Sedd.
- Visa nästa avsnitt, avsnittsdatum och progress där uppgifterna finns.
- Fortsätt titta ska kunna återuppta rätt serie/avsnitt.
- Hero och rekommendationshyllor ska länka till detaljsidan.

## Detaljsida

Bygg en rik men tydligt strukturerad detaljsida. Undvik en enda oändlig vy; använd kompakt titelheader och tydlig intern navigering/flikar, exempelvis Översikt, Avsnitt, Rollista och Recensioner.

### Titelheader och status
- Stor bakgrundsbild, affisch, titel, tagline, typ och grundmetadata.
- Status: Kommande, Vill se, Bevakar, Tittar på, Sedd och relevanta statusar för avslutade/nedlagda serier.
- Snabbåtgärder: Track/status, favorit, egna listor, personlig recension/betyg och mer.
- Bilden får avsiktligt gå kant till kant; övrigt innehåll får inte orsaka horisontell overflow eller hamna bakom navigation/tab bar.

### Betyg
- Visa TMDB, IMDb och Rotten Tomatoes när verifierbara uppgifter och tillåtna datakällor finns.
- Visa källans namn/logotyp, betygsskala och antal röster när tillgängligt.
- Eget WATCHLIST-betyg separat.
- Hitta aldrig på saknade värden och märk aldrig om en källa till en annan. Undersök licens/API-villkor innan extern integration.

### Metadata och innehåll
- Synopsis/tagline, genre, premiärdatum, speltid, språk, land, nätverk/streamingtjänst.
- Rollista och produktion: skådespelarbilder, rollnamn, regissör, manusförfattare, skapare, produktionsbolag.
- Streaming, hyr- och köpalternativ med svensk region där det finns data.
- Trailer/video med stor förhandsbild och inbäddad uppspelning när leverantören tillåter det; erbjud extern öppning som reserv.
- Recensioner i vågrät karusell, med möjlighet att läsa hela recensionen.
- Liknande filmer/serier och relaterade titlar.

## Säsonger och avsnitt

- Säsongskort med antal avsnitt, sedda avsnitt och progress.
- Avsnittsbild från TMDB bredvid avsnittsnamn och metadata.
- Visa avsnittsnummer, titel, datum, längd, beskrivning och avsnittsbetyg när det finns.
- Markera/avmarkera enskilt avsnitt.
- Markera hela säsongen som sedd.
- Återställ hela säsongen.
- Tydlig progress för hela serien och per säsong.
- Up Next ska hitta nästa osedda relevanta avsnitt och visa kommande avsnitt när datum finns.
- Åtgärder för omtittning får inte oavsiktligt ändra vanlig sedd-status.

## Bibliotek och historik

- Statusfilter: Vill se, Bevakar, Tittar på och Sedd; filter för filmer/serier.
- Omslag ska visa diskret sedd-markering och serieprogress.
- Grid/listvy, sökning och sortering.
- Egna listor och favoriter.
- Tittarhistorik ska visa separata visningstillfällen.
- Kunna ta bort en enskild omtittning, ångra felregistrering och rensa alla omtittningar för en titel med tydlig bekräftelse.
- En feltryckning får aldrig radera hela historiken.
- Spara ändringar robust och visa begripliga fel. Skydda befintliga SwiftData-poster och användardata.

## Premiärkalender

- Ersätt den nuvarande trånga månadsvyn där premiärlistan får för lite höjd.
- Kompakt datum-/veckoväljare högst upp och en stor premiärlista som får huvuddelen av skärmen.
- Agenda/vecka/månad som alternativa lägen.
- Gruppera premiärer per datum.
- Visa affisch, titel, typ, premiärdatum och betyg.
- Filter för film, serie, digital premiär och biopremiär.
- Påminnelser med tydlig status och möjlighet att ändra/ta bort.
- Svensk region när datakällan stödjer den.

## Dataintegritet och teknik

- Nuvarande app använder SwiftUI och SwiftData; bevara befintliga modeller och användardata.
- Ingen destruktiv schemaändring eller databasradering som felsökningsgenväg.
- Vid sparfel: rollbacka ändringar säkert och rapportera begripligt.
- Undvik dubbelregistrering i historik vid bulkåtgärder.
- Testa migrationer och återställning om datamodeller måste ändras.
- TMDB-data ska tydligt attribueras. Externa betygskällor kräver separat verifierad integration.
- iOS Build och enhets-IPA ska passera innan en ny IPA levereras.
- Leverera den verifierade .ipa-filen direkt, inte enbart ett ZIP-arkiv.

## Prioriterad utvecklingsordning

1. Stabilisera detaljsidan och lagringsfel (inklusive tidigare `default.store`-fel).
2. Säsongshantering: bulkmarkering, återställning, avsnittsbilder och korrekt progress.
3. Pågående serier och Up Next på startsidan.
4. Rikare detaljsida: flikar, metadata, rollista, videospelare och recensioner.
5. Hero-karusell och blandade film-/seriehyllor.
6. Fullständiga Visa alla-sidor för startsidans hyllor.
7. Bibliotekets sedd-markeringar och historikåtgärder.
8. Premiärkalender med större premiäryta.
9. Externa betygskällor efter verifiering av API/licensvillkor.

## Status vid dokumentets skapande

- Repository: `72cbbw422f-alt/watch`.
- Senast levererade IPA: 137.
- Senaste större detaljsidesändring: inbyggd YouTube-spelare, horisontell TMDB-recensionskarusell och avsnittsbilder.
- Senaste kodändring efter IPA 137: säsongsmeny med Markera hela säsongen som sedd och Återställ säsongen.
- Commit: `7fd4a5eb1cb4249ec054e5b1a276b18c71d68d57`.
- iOS Build #441 startad; simulatorbygget har passerat och enhetstester körs.
- Tidigare rapporterat fel `default.store` är ännu inte verifierat löst och ska felsökas separat utan risk för användardata.
\n\n## Senaste status – 2026-11-28\n\n- IPA #140 byggd och verifierad för commit `ae9aaa334c627eda1603b6003019c3102c5a04c1`. Bulkmarkering av säsong skapar historikhändelser utan dubbletter.\n- Up Next på startsidan begränsas nu till serier med status `Tittar på` eller `Bevakar`. Serier som enbart har status `Vill se` ska inte räknas som aktivt följda.\n\n\n## Progressuppdatering – Fortsätt titta 2026-11-28

- Uppdateringsnyckeln för Fortsätt titta omfattar nu även sparad avsnittsprogress.
- När användaren markerar eller återställer ett avsnitt ska startsidans nästa-avsnittsinformation laddas om, även om listan över aktiva serier är oförändrad.
- Ändringen ska verifieras i CI tillsammans med hero-karusellen.

## Utvecklingsstatus – hero 2026-11-28

- Startsidan har nu en första implementation av en horisontell hero-karusell med upp till fem utvalda titlar.
- Urvalet växlar mellan film och serie när datatillgången tillåter det, med bibehållen starttitel från trendflödet.
- Varje hero-kort öppnar titelns detaljsida och använder bakgrundsbild med gradient, metadata och tydlig CTA.
- Simulatorbygge och enhetstester ska verifieras i CI innan ändringen betraktas som tekniskt godkänd. Ingen IPA-testning planeras för denna ändring.

## Startsida – förtydligande 2026-11-28\n\n- `Fortsätt titta` är användarens aktiva pågående titlar (`Tittar på`). För serier visas första avsnittet som ännu inte markerats som sett.\n- `Up Next` är en horisontell posterhylla med osedda filmer och serier sparade som `Vill se` eller `Bevakar`. Den ska inte vara en lista över kommande TV-sändningar.\n

## Import från Seenr – krav och verifierat källformat 2026-11-28

Målet är en separat Seenr-importör som konverterar exportformatet `seenr-export/2` till WATCHLISTs befintliga backup-/importmodell. Den ska inte ändra eller ersätta den generella JSON-backupimporten.

### Verifierat i användarens export
- Exportfilen är JSON, cirka 11,3 MB, med formatidentifieraren `seenr-export/2`.
- Biblioteket innehåller separata `shows` och `movies`-arrayer. Titelposter har bland annat `tmdb_id`, `title`, `year`, `status`, `rating`, `review`, `favorite`, `added_at`, samt för serier `episodes_watched` och `plays`.
- `episode_watches` innehåller avsnittsprogress med `show_tmdb_id`, säsong, avsnittsnummer, avsnitts-ID, visningsdatum, antal visningar och datumlista.
- `viewings` innehåller individuella film- och avsnittsvisningar. Avsnitt har `work.tmdb_id`, `work.show_tmdb_id`, `work.season`, `work.episode`, titel och `watched_at`.
- Exporten innehåller också andra Seenr-moduler och metadata. De ska inte importeras som om de vore film-/seriedata.

### Importregler
- Kontrollera formatversion och obligatoriska fält innan någon ändring i SwiftData.
- Mappa Seenr-statusar uttryckligen; okända statusvärden ska redovisas och inte gissas.
- Bevara TMDB-ID, titel, år, personligt betyg, recension, favorit och datum när målfälten stöder dem.
- Skapa avsnittsprogress från `episode_watches`; använd inte enbart summeringen `episodes_watched` för att hitta på avsnittsidentiteter.
- Skapa separata historikhändelser från `viewings`. Omtittningar måste förbli separata händelser och stabila identiteter måste förhindra dubbelimport.
- Om en visning saknar datum eller obligatorisk identitet ska den räknas som ej importerbar och visas i rapporten.
- Förhandsgranskning ska visa bibliotekstitlar, avsnittsprogress, filmvisningar, avsnittsvisningar, dubbletter, okända statusar och poster som inte kan mappas.
- Importen ska vara additiv och transaktionell: lokala poster får inte skrivas över eller raderas. Samma export ska kunna importeras två gånger utan att skapa dubbletter.
- Stora filer ska läsas effektivt och UI får inte blockeras under analysen.

### Testplan
1. Fixture-tester för ett minimalt Seenr-exempel med film, serie, avsnittsprogress, flera visningar av samma film/avsnitt, betyg, recension och favorit.
2. Test för verklig exportstruktur och formatidentifierare.
3. Idempotens: importera samma fixture två gånger och verifiera oförändrat antal poster efter första importen.
4. Testa okänd status, saknade datum, felaktiga TMDB-ID:n och korrupt JSON.
5. Testa stor export och verifiera att förhandsgranskningen inte låser gränssnittet.
6. Kör full CI innan en IPA lämnas ut för fysisk testning.

### Nästa implementation
- Lägg till `SeenrExportDecoder` / `SeenrImportService` som ett fristående lager.
- Utöka förhandsgranskningen med Seenr-specifika räknare och importvarningar.
- Koppla importörens resultat till befintlig additiv merge först efter validering.
- Behåll den befintliga WATCHLIST-backupimporten oförändrad.


### Seenr-import – implementation status 2026-11-28

- Added `SeenrExportDecoder` for `seenr-export/2`, with explicit format validation, title/episode/viewing decoding and warnings for malformed records.
- Added a separate `SeenrImportService` with additive SwiftData merge and deterministic history-event identities.
- Connected Seenr detection to the existing JSON file-import flow. Existing WATCHLIST backup import remains a separate path.
- Preview now reports new/matching titles, episode states, episode/movie viewing events, skipped titles and unknown-status warnings.
- Episode progress is derived from both `episode_watches` and individual episode viewings; duplicate dates across the two sources are collapsed.
- Movie and episode viewing dates from both `viewings` and title/episode date arrays are merged with stable identities.
- Added decoder tests and a merge/idempotency test covering duplicate source records and rewatch dates.
- CI for the first integrated flow at commit `d25ed82` passed. Follow-up history reconciliation and additional merge tests are in the current CI queue; do not mark the importer release-ready until the latest commit's tests pass.
- Known limitation to resolve before release: Seenr statuses without a direct WATCHLIST equivalent (for example dropped titles) are intentionally skipped and reported. The current WATCHLIST model has no dropped status.
- The Seenr file is now read and decoded in a background task; the security-scoped file access remains active until that work finishes. The existing WATCHLIST backup path is also read off the main thread before its normal decode/preview.


### Seenr-import follow-up – 2026-11-28

- Added persistent storage for season- and episode-level Seenr ratings, including score, review, spoiler flag and timestamp. These records are preserved for later presentation in detail pages; they are not yet displayed as rating UI.
- Added rating fixture data to decoder and merge/idempotency tests. The tests now verify that a rating is imported once and not duplicated by a second import.
- The import preview and completion summary now include the count of imported season/episode ratings.
- File reading and Seenr decoding now run in a detached background task. Security-scoped access is held until the task completes, and the existing WATCHLIST backup import remains supported.
- Latest iOS Build/test runs are queued for the new changes. Do not mark the importer release-ready until the newest accumulated commit passes CI and a migration/startup check is completed.


### Seenr-import validation additions – 2026-11-28

- Movie history now includes the Seenr `first_watched_at` field when the `dates` array is empty or does not contain that date.
- Added a fixture assertion for this fallback.
- Added a SwiftData store-opening test that creates a store using the pre-rating model set, then opens it using the current model set with `ImportedWorkRating`. CI must confirm whether this additive schema change opens cleanly.
- The current importer remains in validation; no IPA should be produced for user testing until the latest full test run passes.


### Senaste importskydd – 2026-11-28

- Förhandsgranskningen visar importvarningar innan användaren bekräftar sammanslagningen.
- Importen räknar felaktiga titel- och betygsposter och redovisar att de har hoppats över.
- Om Seenrs antal visningar överstiger antalet faktiska sparade datum visas en varning. Importören skapar inte påhittade historikhändelser för visningar utan datum.
