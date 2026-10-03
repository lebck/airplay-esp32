# Plan: GitHub-Releases auf dem Gerät anzeigen und installieren

Status: Etappe 1 ist teilweise umgesetzt. Die CI-Release-Matrix veröffentlicht
Full-Flash- und Application-OTA-Images; das Release-Manifest und die
Build-Identität sind ergänzt. Download, Installation, Weboberfläche und
Hardwareprüfung aus den Etappen 2–4 sind noch nicht implementiert.

## Ziel und bestehende Grundlage

Die Geräte-Webseite zeigt passende GitHub-Releases an und ermöglicht die
Installation einer ausgewählten Version. Der ESP32 übernimmt den Download und
die Installation; die Webseite zeigt Auswahl, Fortschritt und Ergebnis.

Bereits vorhanden sind der manuelle Upload über `POST /api/ota/update`, das
Schreiben in die nächste OTA-Partition und der anschließende Neustart. Die
installierte Version wird über die Geräteinformationen bereitgestellt.

Die aktuellen Release-Dateien sind zusammengeführte Flash-Images. Der bestehende
OTA-Code benötigt dagegen das reine Application-Image ohne Bootloader,
Partitionstabelle und SPIFFS. Die Webseite liegt derzeit in SPIFFS und wird durch
Application-OTA nicht aktualisiert.

## 1. Update-Paket und Kompatibilität festlegen

Jede Firmware erhält eine eindeutige Build-Varianten-ID, beispielsweise
`esp32s3`, `squeezeamp-bt`, `squeezeamp-4m` oder
`esparagus-audio-brick-bt`. Diese ID wird beim Build übernommen und über die
Geräte-API bereitgestellt. Boardname oder Chiptyp allein reichen nicht, da
Varianten unterschiedliche DACs, Flashgrößen und Funktionen verwenden können.

Für jedes installierbare Paket werden folgende Angaben benötigt:

| Feld | Zweck |
| --- | --- |
| Version | Anzeige und Vergleich mit der installierten Version |
| Build-Variante | Auswahl der passenden Firmware |
| Chip | Zusätzliche Kompatibilitätsprüfung |
| Größe | Prüfung gegen die verfügbare OTA-Partition |
| SHA-256 | Prüfung des vollständig heruntergeladenen Images |
| Assetname | Zuordnung zur veröffentlichten Datei |
| Update-Format | Unterscheidung unterstützter Paketformate |
| Layout-ID | Ausschluss inkompatibler Partitionierungsänderungen |

Beispiel für ergänzte Geräteinformationen:

```json
{
  "firmware_version": "0.2.1",
  "build_variant": "esparagus-audio-brick-bt",
  "chip": "esp32",
  "update_layout": "ota-3m-v1",
  "ota_partition_size": 3145728
}
```

Versionen, Größen und Layoutnamen in diesem Dokument sind Beispiele. Die
Release-Matrix setzt die Varianten-ID explizit; die PlatformIO-Vorkompilierung
leitet sie aus der Umgebung und das Layout aus der konfigurierten
Partitionstabelle ab. Native ESP-IDF-Builds können beide Werte über
`-DFIRMWARE_BUILD_VARIANT=<id>` und `-DFIRMWARE_UPDATE_LAYOUT=<id>` setzen.
Unmarkierte native Builds melden `custom` und `custom-unknown` und passen damit
zu keinem veröffentlichten Update-Paket.

## 2. Release-Pipeline um OTA-Dateien erweitern

Der Build-Workflow veröffentlicht zusätzlich für jede unterstützte Variante das
reine Application-Image. Vorgeschlagene Dateinamen:

```text
airplay2-receiver-esparagus-audio-brick-bt.bin
airplay2-receiver-esparagus-audio-brick-bt-ota.bin
update-manifest.json
```

Die erste Datei ist das vollständige Image für die Erstinstallation. Die zweite
wird für OTA verwendet. Nach den Builds erzeugt der Release-Workflow ein
gemeinsames Manifest:

```json
{
  "schema_version": 1,
  "version": "0.2.2",
  "images": [
    {
      "variant": "esparagus-audio-brick-bt",
      "chip": "esp32",
      "layout": "ota-3m-v1",
      "asset": "airplay2-receiver-esparagus-audio-brick-bt-ota.bin",
      "size": 1835008,
      "sha256": "..."
    }
  ]
}
```

Der Release-Workflow erzeugt `update-manifest.json` aus Metadaten der
erfolgreichen Build-Artefakte. Derzeit veröffentlicht die CI-Matrix diese
Varianten: `esp32s3`, `seeed-xiao-esp32s3`, `waveshare-esp32s3`, `esp32s2`,
`squeezeamp-bt`, `squeezeamp-4m`, `esparagus-audio-brick-bt`, `smartamp` und
`esparagus-louder-s3`. Partitionen mit 3 MiB OTA-Slots erhalten `ota-3m-v1`,
4-MB-Layouts mit 1,875 MiB Slots `ota-1875k-v1`.

Der Workflow läuft außerdem bei Pushes auf Branches: Er baut dieselbe Matrix,
erzeugt das Manifest und lädt die Ergebnisse als Actions-Artefakt hoch, ohne
einen GitHub-Release anzulegen. Tags im Format
`MAJOR.MINOR.PATCH-test-NAME` (zum Beispiel
`0.4.0-test-release-display-001`) erzeugen einen GitHub-Prerelease. Der
Versionsanteil muss `version.txt` entsprechen. Normale stabile Releases behalten
das Format `vMAJOR.MINOR.PATCH`.

Der Workflow stellt sicher, dass:

- Größe und Hash aus den tatsächlich veröffentlichten OTA-Dateien entstehen.
- Jedes Manifest-Asset vorhanden ist.
- Manifest-Version und Release-Tag zusammenpassen.
- Nur erfolgreich gebaute Varianten enthalten sind.
- Jede Variante genau einmal vorkommt und der SHA-256-Hash über das
  Application-OTA-Image berechnet wird.
- Der Release erst veröffentlicht wird, wenn alle erforderlichen Dateien
  bereitstehen, beispielsweise zunächst als Draft.

Eine Variante ohne passendes Asset ist nicht installierbar. Die aktuelle
CI-Matrix deckt nicht sämtliche PlatformIO-Umgebungen ab. Es muss ausdrücklich
festgelegt werden, welche Varianten automatische Updates erhalten.

Betroffene Dateien: `.github/workflows/build.yml` und
`.github/workflows/release.yml`. Die bestehende Installation von
`idf-component-manager==2.5.2` bleibt Bestandteil aller Build-Pfade.

## 3. GitHub-Releases auf dem Gerät abrufen

Ein neues Modul, beispielsweise `main/network/update_service.c`, übernimmt:

- Abruf der Releases eines festgelegten Repositorys.
- Laden des Release-Manifests.
- Auswahl des Images für die eigene Build-Variante.
- Prüfung von Version und Kompatibilität.
- Begrenzte Zwischenspeicherung der Ergebnisse.
- Bereitstellung einer normalisierten Antwort für die Weboberfläche.

Die vollständige GitHub-Antwort wird nicht unverändert weitergereicht. Beispiel:

```json
{
  "current_version": "0.2.1",
  "variant": "esparagus-audio-brick-bt",
  "releases": [
    {
      "tag": "v0.2.2",
      "version": "0.2.2",
      "published_at": "...",
      "notes": "...",
      "compatible": true,
      "size": 1835008
    }
  ]
}
```

Antwortgröße, Anzahl der Releases und Länge der Release Notes werden begrenzt.
Die Speicheranforderungen müssen auch auf ESP32-Geräten ohne PSRAM tragbar sein.
Die Abfrage erfolgt bei Bedarf und verwendet einen zeitlich begrenzten Cache.
Pagination und die Anzahl zusätzlich geladener Manifeste erhalten feste Grenzen.

Standardmäßig werden stabile Releases angeboten. Vorabversionen können später
über eine ausdrückliche Einstellung hinzukommen. Versionsnummern werden numerisch
verglichen: `0.10.0` ist neuer als `0.9.0`. Gleiche oder ältere Versionen werden
entsprechend gekennzeichnet; eine Downgrade-Policy ist vor der Umsetzung
festzulegen.

Öffentliche Releases können ohne Token abgefragt werden. Ein privates Repository
würde ein separates Authentifizierungskonzept erfordern. GitHub nennt derzeit
60 unauthentifizierte API-Anfragen pro Stunde je öffentlicher IP.

Quellen:

- [GitHub Releases API](https://docs.github.com/en/rest/releases/releases)
- [GitHub API-Limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api)

## 4. Geräte-Endpunkte ergänzen

| Endpunkt | Funktion |
| --- | --- |
| `GET /api/updates` | Verfügbare und kompatible Releases anzeigen |
| `POST /api/updates/install` | Installation eines Releases starten |
| `GET /api/updates/status` | Fortschritt und Ergebnis abfragen |

Der Installationsaufruf enthält den ausgewählten Release-Tag:

```json
{
  "tag": "v0.2.2"
}
```

Das Gerät ermittelt und prüft das Asset selbst. Die Webseite übergibt keine
beliebige Download-URL. Release-Tag und Asset werden auf das konfigurierte
Repository beschränkt.

Die Installation läuft in einem Hintergrundtask. Der POST-Aufruf bestätigt den
Start; die Oberfläche fragt danach den Status ab. Der HTTP-Server bleibt während
des Downloads erreichbar. Auch eine möglicherweise langsame Release-Abfrage
darf den Server nicht dauerhaft blockieren.

Beispielstatus:

```json
{
  "state": "downloading",
  "target_version": "0.2.2",
  "bytes_received": 524288,
  "bytes_total": 1835008,
  "progress": 28
}
```

Zustände: `idle`, `checking`, `downloading`, `validating`, `rebooting` und
`error`. Fehler enthalten einen stabilen Fehlercode und eine verständliche
Beschreibung. Es läuft jeweils nur ein Update. Manueller Upload und
GitHub-Installation verwenden dieselbe Sperre.

## 5. HTTPS-Download und OTA-Schreiben implementieren

Upload und Download sollen gemeinsame Prüfungen und Flash-Funktionen verwenden.
Der Installationsablauf:

1. Release und Manifest auflösen oder einen gültigen Cache verwenden.
2. Build-Variante, Chip, Layout und Imagegröße prüfen.
3. Verfügbare OTA-Partition ermitteln.
4. Audio-Wiedergabe kontrolliert stoppen, einschließlich aktiver
   Bluetooth-Wiedergabe, soweit unterstützt.
5. HTTPS-Download mit Zertifikatsprüfung starten.
6. GitHub-Weiterleitungen mit einer begrenzten Anzahl verfolgen. HTTPS bleibt
   erforderlich; erlaubte Download-Ziele werden anhand der tatsächlichen
   GitHub-Download-Kette festgelegt.
7. Image in kleinen Blöcken in die inaktive OTA-Partition schreiben.
8. Parallel SHA-256 berechnen.
9. Vollständigkeit, Hash und ESP-Image prüfen.
10. Erst danach die neue Boot-Partition setzen.
11. Installationsergebnis speichern und neu starten.

Der Download funktioniert ohne vollständigen PSRAM-Puffer. Netzwerk-Timeouts,
maximale Downloadgröße und ein begrenztes Wiederholungsverhalten werden explizit
festgelegt. Die TLS-Vertrauensquelle und Anforderungen an die Gerätezeit müssen
in der Implementierung geklärt werden.

Bei Fehlern wird OTA abgebrochen und die aktive Firmware bleibt ausgewählt.
Gestoppte Dienste werden wieder gestartet, soweit das ohne Neustart möglich ist.

SHA-256 prüft die Integrität der Datei. Eine kryptografische Signatur wäre eine
zusätzliche Ausbaustufe mit eigener Schlüssel- und Vertrauensstrategie.

Betroffene Dateien: `main/network/ota.c`, `main/network/ota.h`,
`main/network/web_server.c`, das neue Update-Modul und die zugehörige
Komponentenregistrierung.

## 6. Weboberfläche erweitern

Der Firmware-Bereich in `data/www/index.html` erhält:

- Installierte Version und erkannte Build-Variante.
- Schaltfläche „Nach Updates suchen“.
- Liste kompatibler Releases mit Datum und Versionsnummer.
- Release Notes.
- Schaltfläche „Installieren“.
- Fortschritt und aktuelle Installationsphase.
- Konkrete Fehlermeldungen und eine erneute Versuchsmöglichkeit.

Vor der Installation zeigt die Seite die Zielversion und den Hinweis auf die
Unterbrechung der Wiedergabe und den Neustart. Release Notes werden als Text oder
mit einer sicheren Markdown-Darstellung ausgegeben. GitHub-Inhalte dürfen nicht
ungeprüft als HTML eingefügt werden.

Nach dem Neustart versucht die Seite mit einem begrenzten Zeitfenster, das Gerät
wieder zu erreichen. Erfolg wird erst angezeigt, wenn die Geräte-API die
erwartete Version zurückmeldet. Ein Timeout liefert einen unbestätigten Status
mit einer Möglichkeit zur erneuten Abfrage.

Der bestehende manuelle Upload wird ebenfalls korrigiert: HTTP-Fehler werden
ausgewertet; ein Verbindungsabbruch allein gilt nicht als erfolgreiche
Installation.

## 7. Aktualisierung der Webdateien lösen

Die Oberfläche liegt aktuell in SPIFFS. Application-OTA aktualisiert sie nicht.
Empfehlung: HTML-, CSS- und JavaScript-Dateien künftig in das Application-Image
einbetten, damit Firmware und Oberfläche gemeinsam aktualisiert werden.

Dafür sind erforderlich:

- Webdateien beim Build einbetten.
- Entsprechende HTTP-Routen auf eingebettete Dateien umstellen.
- Größe des Application-Images gegen alle unterstützten OTA-Partitionen prüfen.
- Eine Strategie für Änderungen an anderen SPIFFS-Inhalten, insbesondere
  DSP-Dateien, festlegen.

Bestehende Geräte erhalten zunächst über den vorhandenen manuellen OTA-Upload
eine Firmware mit eingebetteter Oberfläche. Danach ist die GitHub-Auswahl
verfügbar, sofern das neue Application-Image in die vorhandene OTA-Partition
passt und das bestehende Layout kompatibel ist.

Alternativ können Webdateien in SPIFFS bleiben. Dann ist ein separates Verfahren
für deren Aktualisierung, die Kompatibilität mit der Firmware und die
Wiederherstellung nach unterbrochenem Schreiben erforderlich. Diese Alternative
erhöht den Umfang deutlich.

## 8. Neustart und Rückfall absichern

Zuerst prüfen, ob Bootloader und bestehende Gerätekonfigurationen OTA-Rollback
bereits unterstützen. Bei aktiviertem Rollback wird die neue Firmware erst nach
erfolgreichen grundlegenden Startprüfungen als gültig markiert:

- Einstellungen können gelesen werden.
- Erforderliche Komponenten starten.
- Der Webserver startet erfolgreich.

Fehlender Internetzugang allein darf die Firmware nicht als fehlerhaft markieren.
Wenn Rollback eine geänderte Bootloader-Konfiguration voraussetzt, ist eventuell
ein vollständiger Flash nötig. Für bestehende Geräte darf die Funktion daher
nicht vorausgesetzt werden.

## 9. Gezielte Prüfung und Abnahmekriterien

| Fall | Erwartetes Ergebnis |
| --- | --- |
| Passender neuer Release | Installation und bestätigte Zielversion |
| Andere Boardvariante | Installation wird verweigert |
| Inkompatibles Layout | Installation wird verweigert |
| Image zu groß | Abbruch vor dem Schreiben |
| Hash falsch | Neue Boot-Partition wird nicht aktiviert |
| Download unterbrochen | Alte Firmware bleibt bootfähig |
| GitHub nicht erreichbar oder Rate-Limit | Verständliche Meldung und erneuter Versuch |
| Fehlendes oder ungültiges Manifest | Release wird nicht zur Installation angeboten |
| Zwei Installationsaufrufe | Zweiter Auftrag wird abgelehnt |
| Neustart nach Installation | Oberfläche erkennt die neue Version |
| Gerät ohne PSRAM | Download funktioniert mit begrenztem Speicher |
| Stromausfall während OTA | Gerät startet mit einer gültigen Firmware |
| Fehler nach Stoppen der Wiedergabe | Dienste werden wiederhergestellt oder der erforderliche Neustart wird gemeldet |

Versionsvergleich, Manifest-Auswahl und Zustandsübergänge werden auf dem Host
geprüft. Download, Flashen, Speicherverbrauch und Stromausfallverhalten benötigen
Hardwareprüfung, mindestens auf einem ESP32 und einem ESP32-S3. Die unterstützten
Build-Varianten müssen erfolgreich gebaut werden. Für C/H-Änderungen gelten die
Formatierungs- und Prüfanforderungen aus `AGENTS.md`.

## Umsetzung in Etappen

1. **Paketformat und Build-Identität:** OTA-Assets, Manifest und
   Geräteinformationen. Abnahme: Ein Release enthält eindeutig zuordenbare,
   verifizierbare OTA-Images.
2. **Download und Installation:** Hintergrundtask, gemeinsame OTA-Prüfungen,
   Status-API und Fehlerbehandlung. Abnahme: Ein kompatibler Release lässt sich
   über die API installieren; Fehler aktivieren kein unvollständiges Image.
3. **Weboberfläche:** Release-Auswahl, Fortschritt und Bestätigung nach dem
   Neustart; Webdateien in das Application-Image integrieren. Abnahme: Der
   vollständige Ablauf ist auf der Geräte-Webseite nutzbar.
4. **Hardwareprüfung und Einführung:** Bestehende Geräte aktualisieren,
   unterstützte Varianten dokumentieren und einen vollständigen Release
   installieren. Abnahme: Die oben genannten Hardwarefälle sind geprüft und
   bekannte Einschränkungen dokumentiert.

## Offene Entscheidungen vor der Umsetzung

- Welche Build-Varianten erhalten veröffentlichte OTA-Assets?
- Wie wird die Varianten-ID für PlatformIO und native ESP-IDF-Builds festgelegt?
- Welche Partitionierungsvarianten sind miteinander kompatibel?
- Passen Firmware und eingebettete Webdateien in alle unterstützten OTA-Slots?
- Wie werden Änderungen an DSP-Dateien verteilt?
- Werden ältere Versionen zur Installation angeboten?
- Welche Bestandsgeräte unterstützen Rollback bereits?
- Welches feste GitHub-Repository wird als Update-Quelle verwendet?

Die größten offenen Punkte sind weiterhin der Platz in den jeweiligen
OTA-Partitionen und die Verteilung bisheriger SPIFFS-Inhalte. Die hier
aufgeführten Varianten sind die gegenwärtige CI-Release-Matrix; weitere
PlatformIO- und native Konfigurationen sind dadurch noch nicht automatisch
für Updates freigegeben.
