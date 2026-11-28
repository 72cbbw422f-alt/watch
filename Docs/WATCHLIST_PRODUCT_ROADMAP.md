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