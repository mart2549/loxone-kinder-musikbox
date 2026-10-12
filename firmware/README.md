# Firmware

ESPHome-Firmware für den Seeed XIAO ESP32C3. Eine Firmware für alle Boxen: Loxone-Adresse, Port und Name werden auf der Statusseite der Box eingestellt und bleiben bei Updates erhalten.

## Dateien

| Datei | Zweck |
|---|---|
| `musikbox.yaml` | Quelltext, normale Variante mit eigenen Passwörtern (empfohlen) |
| `musikbox_einsteiger.yaml` | Quelltext der Einsteiger-Variante ohne Passwörter |
| `ereignislog.h`, `udp_lx.h` | gehören zu beiden `.yaml` |
| `secrets.example.yaml` | Vorlage für die eigene `secrets.yaml` |
| `bin/musikbox_einsteiger.factory.bin` | fertige Einsteiger-Firmware, erstes Aufspielen per USB |
| `bin/musikbox_einsteiger.ota.bin` | dieselbe Firmware für Updates über die Statusseite |

## Variante A: selbst bauen (empfohlen)

1. ESPHome installieren, z. B. den ESPHome Builder in Home Assistant oder ESPHome am PC.
2. `secrets.example.yaml` als `secrets.yaml` speichern und eigene Passwörter eintragen.
3. `musikbox.yaml`, `ereignislog.h` und `udp_lx.h` in denselben Ordner legen und bauen.
4. Erstes Aufspielen per USB, danach Updates über ESPHome oder die Statusseite.

Jede Box hat damit eigene Passwörter für Hotspot, Statusseite und Updates.

## Variante B: Einsteiger-Firmware

1. XIAO per USB anschließen, in Chrome oder Edge **web.esphome.io** öffnen, **Connect**.
2. **Install** wählen und `bin/musikbox_einsteiger.factory.bin` auswählen.
   **Nicht „Prepare for first use“ wählen:** Das spielt eine Standard-Firmware von ESPHome ohne Statusseite und ohne Musikbox-Funktion auf. Erkennbar ist das am Namen `esphome-web-…` im Router und daran, dass die Statusseite die Verbindung ablehnt. Dann einfach mit **Install** und der Datei wiederholen.
3. Nach dem Aufspielen „Configure Wi-Fi“ wählen und das WLAN eingeben (Improv). Alternativ nach etwa 90 s mit dem offenen Hotspot **„Musikbox Setup“** verbinden und dort das WLAN wählen.
4. Die Statusseite unter `http://<IP-der-Box>` öffnen (mit http, nicht https) und Loxone IP und Port eintragen.

Die Einsteiger-Firmware ist auf einer echten Box getestet: WLAN-Einrichtung beim Aufspielen, Statusseite und Steuerung über Loxone.

> **Achtung:** Statusseite, Hotspot und Updates sind ohne Passwort. Jeder im Heimnetz kann Einstellungen ändern oder eine andere Firmware aufspielen. Der Hotspot ist nur offen, solange die Box kein WLAN findet. Wer das nicht möchte, nimmt Variante A.

## Einstellungen auf der Statusseite

| Einstellung | Voreinstellung |
|---|---|
| Name der Box | Musikbox |
| Loxone IP | 192.168.178.10 |
| Loxone UDP-Port | 7000 |
| LED-Signale (Farbe, Helligkeit, Anzahl, Tempo) | Karte erkannt: weiß 60 %, Karte ohne Nummer: rot 3 ×, Kein Netzwerk: rot 6 × schnell |

Der Knopf **„Verbindungstest Loxone“** sendet `taste=0` (harmlos) zum Prüfen im UDP-Monitor.

## Wichtig bei Updates

- **WLAN neu einrichten:** ESPHome bindet die über den Hotspot eingegebenen WLAN-Daten an die genaue Firmware. Nach jedem Update findet die Box das WLAN nicht mehr. Nach etwa 90 s öffnet sie den Hotspot, dort das WLAN neu eingeben. Bei Variante A mit eingetragenem WLAN in der `secrets.yaml` entfällt das.
- Die Einstellungen der Statusseite und das Ereignislog bleiben erhalten.

## Verhalten

| Situation | Box |
|---|---|
| Karte mit Nummer aufgelegt | `karte=<nr>`, LED „Karte erkannt“ |
| Karte weggenommen | `karte=0`, LED aus |
| Karte ohne Nummer | Blinksignal, nichts gesendet |
| WLAN länger als 3 s weg | Blinksignal „Kein Netzwerk“, sobald eine Karte liegt oder aufgelegt wird |
| Tasten | nur mit aufgelegter Karte, `taste=1` bis `4`, danach `taste=0` |
| Nach WLAN-Verbindung | `taste=0`, dann `karte=<nr>` bzw. `karte=-1`; nachgeholter Stopp `karte=0` |
| Ereignislog | alle Karten- und Tastenereignisse mit Zeitstempel im Flash, Ausgabe über die Statusseite |

Ein Handy mit NFC-Bezahlfunktion auf der Box meldet sich mit ständig wechselnder Kennung. Die Box zeigt dann das Signal „Karte ohne Nummer“ und sendet nichts.

## Pinbelegung

| XIAO | Funktion |
|---|---|
| D1 (GPIO3) | Taste leiser |
| D2 (GPIO4) | Taste lauter |
| D3 (GPIO5) | Taste zurück |
| D7 (GPIO20) | Taste weiter |
| D4 (GPIO6) | I2C SDA (PN532) |
| D5 (GPIO7) | I2C SCL (PN532) |
| D10 (GPIO10) | LED-Daten über 330 Ω |

Taster jeweils gegen GND, interne Pull-ups aktiv. Log über die USB-Buchse.
