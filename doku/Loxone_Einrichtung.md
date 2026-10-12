# Loxone einrichten

Die Box schickt kurze Textnachrichten (UDP) an den Miniserver. Loxone wertet sie aus und steuert damit den Audio Player der Zone im Kinderzimmer. In der Box ist kein Loxone-Benutzer hinterlegt.

Getestet mit Miniserver Gen. 2 und Loxone Audioserver (Favoriten aus Spotify).

## 1. Telegramme der Box

| Telegramm | Bedeutung |
|---|---|
| `karte=12` | Karte mit der Nummer 12 aufgelegt |
| `karte=0` | Karte weggenommen, Musik stoppen |
| `karte=-1` | Box ist neu verbunden und es liegt keine Karte. Nichts tun, Musik **nicht** stoppen |
| `taste=1` | leiser |
| `taste=2` | lauter |
| `taste=3` | vorheriger Titel |
| `taste=4` | nächster Titel |
| `taste=0` | folgt kurz nach jedem Tastendruck, damit Loxone jeden Druck als Impuls erkennt |

Die Tasten sind nur aktiv, solange eine Karte liegt. Lauter und leiser wiederholen sich beim Halten alle 0,3 s.

Nach jeder WLAN-Verbindung (auch nach einem Stromausfall) meldet die Box einmal ihren Stand: `taste=0`, dann `karte=<nummer>` wenn eine Karte liegt, sonst `karte=-1`. Wurde die Karte weggenommen, während nur das WLAN fehlte, holt sie `karte=0` nach. Nach einem Stromausfall stoppt sie die Musik bewusst nicht, weil sie nicht weiß, ob in der Zwischenzeit eine Karte weggenommen wurde.

## 2. Box vorbereiten

1. Auf der Statusseite der Box (Adresse siehe FritzBox bzw. Router) im Bereich Konfiguration eintragen:
   - **Loxone IP:** Adresse des Miniservers
   - **Loxone UDP-Port:** z. B. 7000 (jede Box bekommt einen eigenen Port)
   - **Name der Box:** frei wählbar, nur zur Anzeige
2. Im Router der Box eine feste IP-Adresse geben (FritzBox: „Diesem Netzwerkgerät immer die gleiche IPv4-Adresse zuweisen“). Loxone filtert nach der Senderadresse.

## 3. Virtueller UDP-Eingang

In Loxone Config unter „Virtuelle Eingänge“ einen **virtuellen UDP-Eingang** anlegen:

| Eigenschaft | Wert |
|---|---|
| Senderadresse | feste IP der Box |
| UDP-Empfangsport | Port aus der Statusseite, z. B. 7000 |

Darunter zwei **virtuelle UDP-Eingang-Befehle**:

| Name | Befehlserkennung | Wertebereich |
|---|---|---|
| Karte | `karte=\v` | −1 bis 9999 (Vorzeichen zulassen) |
| Taste | `taste=\v` | 0 bis 4 |

Minimaler Zeitabstand 0 s. Zum Prüfen auf der Statusseite den Knopf **„Verbindungstest Loxone“** drücken: Im UDP-Monitor von Loxone Config muss `taste=0` ankommen.

## 4. Logik zum Audio Player

| Signal | Bausteine | Eingang am Audio Player |
|---|---|---|
| Karte ≥ 1 | „Größer oder gleich“ (V2 = 1) → Flankenerkennung, Ausgang On (Pd 0,1 s) | Set am Analogspeicher und **Play** |
| Kartennummer | Analogspeicher (Eingang V = Karte, übernommen mit dem Impuls oben) | **Fav** |
| Karte = 0 | „Gleich“ (V2 = 0) → Flankenerkennung, Ausgang On (Pd 0,1 s) | **Off** |
| Taste = 1 | „Gleich“ (V2 = 1) → Monoflop 0,6 s | **V−** |
| Taste = 2 | „Gleich“ (V2 = 2) → Monoflop 0,6 s | **V+** |
| Taste = 3 | „Gleich“ (V2 = 3) | **Prev** |
| Taste = 4 | „Gleich“ (V2 = 4) | **Next** |

Wichtig dabei:

- **Fav über den Analogspeicher:** Eine nicht vorhandene Favoriten-ID wählt den ersten Favoriten. Deshalb dürfen 0 und −1 den Eingang Fav nie erreichen. Der Analogspeicher übernimmt nur Werte ab 1.
- **Off nur als kurzer Impuls:** Ein Impuls unter 200 ms schaltet aus, ein längerer sperrt den Baustein. Deshalb Pd 0,1 s.
- **Lautstärke-Schrittweite** am Audio Player einstellen (Parameter Vsts, z. B. 5).
- Bestehende Wandschalter können parallel bleiben.

## 5. Karten und Favoriten

- **Kartennummer = Favoriten-ID** in der Zone des Kinderzimmers. Karte 3 startet also Favorit 3.
- Karten (MIFARE Classic 1K oder NTAG) mit der App **NFC Tools** beschreiben: Schreiben → Datensatz hinzufügen → **Text** → Nummer eingeben (z. B. `3`) → Schreiben.
- Die Nummer zusätzlich auf die Rückseite schreiben, vorne ein Bild für das Kind.
- Karten ohne Nummer lässt die Box rot blinken und sendet nichts.

## 6. Mehrere Boxen

Jede Box bekommt eine eigene feste IP, einen eigenen UDP-Port (7000, 7001, …) und in Loxone einen eigenen virtuellen UDP-Eingang mit eigener Logik zum Audio Player des jeweiligen Zimmers. Die Firmware ist für alle Boxen dieselbe.

## Beobachtetes Verhalten (Version 1)

| Test | Ergebnis |
|---|---|
| Karte auflegen / wegnehmen | Musik startet / stoppt nach weniger als 1 s |
| Dieselbe Karte wieder auflegen | Musik läuft dort weiter, wo sie pausiert wurde |
| lauter/leiser halten, mehrfach drücken | stufenweise, kein Favoritenwechsel |
| Neustart ohne Karte | Musik bleibt aus |
| Neustart mit Karte | Musik läuft ohne Unterbrechung weiter |
