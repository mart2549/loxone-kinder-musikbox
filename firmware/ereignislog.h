// =====================================================================
// Ereignislog der Musikbox
//
// Speichert steigende und fallende Flanken (Karte auflegen/entfernen,
// Tasten druecken/loslassen) dauerhaft im Flash-Bereich "ereignislog".
// Der Bereich wird als Ringspeicher in 4-KB-Sektoren genutzt. Belegt werden
// hoechstens 70 % des Bereichs: bevor diese Grenze ueberschritten wuerde,
// wird der Sektor mit den aeltesten Eintraegen geloescht.
//
// Ein Eintrag hat 16 Byte: laufende Nummer, Zeitstempel (Unix-Zeit, 0 wenn
// noch keine Uhrzeit vorliegt), Laufzeit seit Start in s, Kennung mit
// Ereignistyp und Flanke, Pruefsumme und Wert.
// Beim allerersten Start wird der Bereich einmal komplett geloescht und das
// in den Einstellungen vermerkt, damit fremder Flash-Inhalt nie als Log gilt.
// =====================================================================
#pragma once
#include "esphome.h"
#include "esp_partition.h"
#include <cstddef>

namespace elog {

static const char *const TAG = "ereignislog";

enum Typ : uint8_t { KARTE = 1, LEISER = 2, LAUTER = 3, ZURUECK = 4, WEITER = 5 };
static const uint8_t MAGIC = 0xA0;          // obere 4 Bit des Typfelds
static const uint16_t KEINE_NUMMER = 0xFFFF;  // Karte ohne gueltige Nummer
static const uint8_t MAX_PROZENT = 70;
static const uint8_t FLANKE_BIT = 0x08;          // Bit 3 des Typfelds: steigend
static const uint32_t SIGNATUR = 0x454C4F31;     // "ELO1", Kennung formatierter Bereich
static const uint32_t SIGNATUR_SCHLUESSEL = 0x6D62656C;  // Schluessel in den Einstellungen

struct Eintrag {
  uint32_t nr;
  uint32_t zeit;
  uint32_t laufzeit;
  uint8_t typ;     // obere 4 Bit MAGIC, Bit 3 Flanke, Bit 0..2 Ereignistyp
  uint8_t pruef;   // CRC-8 ueber alle anderen Bytes
  uint16_t wert;
  bool steigend() const { return typ & FLANKE_BIT; }
  uint8_t art() const { return typ & 0x07; }
};
static_assert(sizeof(Eintrag) == 16, "Eintrag muss 16 Byte haben");

static const uint32_t SEKTOR = 4096;
static const uint32_t PRO_SEKTOR = SEKTOR / sizeof(Eintrag);

static const esp_partition_t *bereich = nullptr;
static uint32_t sektoren = 0, grenze = 0;
static uint32_t kopf_sektor = 0, kopf_index = 0, naechste_nr = 1;
static bool bereit = false;

// Ausgabe
static bool ausgabe_aktiv = false;
static uint32_t ausgabe_sektor = 0, ausgabe_index = 0;

static uint8_t crc8(const Eintrag &e) {
  const uint8_t *p = (const uint8_t *) &e;
  uint8_t crc = 0;
  for (size_t i = 0; i < sizeof(Eintrag); i++) {
    if (i == offsetof(Eintrag, pruef)) continue;
    crc ^= p[i];
    for (int b = 0; b < 8; b++) crc = (crc & 0x80) ? (uint8_t) ((crc << 1) ^ 0x07) : (uint8_t) (crc << 1);
  }
  return crc;
}
static inline bool gueltig(const Eintrag &e) {
  return e.nr != 0xFFFFFFFF && e.nr != 0 && (e.typ & 0xF0) == MAGIC && e.art() >= 1 && e.art() <= 5 &&
         e.pruef == crc8(e);
}
static inline bool leer(const Eintrag &e) {
  const uint8_t *p = (const uint8_t *) &e;
  for (size_t i = 0; i < sizeof(Eintrag); i++)
    if (p[i] != 0xFF) return false;
  return true;
}

static bool lese(uint32_t sektor, uint32_t index, Eintrag &e) {
  return esp_partition_read(bereich, sektor * SEKTOR + index * sizeof(Eintrag), &e, sizeof(e)) == ESP_OK;
}
static void loesche_sektor(uint32_t sektor) { esp_partition_erase_range(bereich, sektor * SEKTOR, SEKTOR); }

// Belegte Sektoren zaehlen und den aeltesten ermitteln (Sektor 'ausnahme' wird ignoriert)
static uint32_t belegte_sektoren(int32_t *aeltester, uint32_t ausnahme = 0xFFFFFFFF) {
  uint32_t anzahl = 0, min_nr = 0xFFFFFFFF;
  if (aeltester) *aeltester = -1;
  Eintrag e;
  for (uint32_t s = 0; s < sektoren; s++) {
    if (s == ausnahme) continue;
    if (!lese(s, 0, e) || !gueltig(e)) continue;
    anzahl++;
    if (s != ausnahme && e.nr < min_nr) {
      min_nr = e.nr;
      if (aeltester) *aeltester = s;
    }
  }
  return anzahl;
}

static void formatieren() {
  esp_partition_erase_range(bereich, 0, bereich->size);
  kopf_sektor = 0;
  kopf_index = 0;
  naechste_nr = 1;
  ESP_LOGW(TAG, "Ereignislog geloescht");
}

static void init() {
  bereich = esp_partition_find_first((esp_partition_type_t) 0x40, (esp_partition_subtype_t) 0x00, "ereignislog");
  if (bereich == nullptr) {
    ESP_LOGE(TAG, "Flash-Bereich 'ereignislog' nicht gefunden, Log inaktiv");
    return;
  }
  sektoren = bereich->size / SEKTOR;
  grenze = sektoren * MAX_PROZENT / 100;
  // Erster Start: Bereich einmal loeschen und vermerken
  auto pref = esphome::global_preferences->make_preference<uint32_t>(SIGNATUR_SCHLUESSEL);
  uint32_t sig = 0;
  if (!pref.load(&sig) || sig != SIGNATUR) {
    ESP_LOGI(TAG, "Erster Start: Bereich wird vorbereitet");
    esp_partition_erase_range(bereich, 0, bereich->size);
    sig = SIGNATUR;
    pref.save(&sig);
    esphome::global_preferences->sync();
  }
  // Kopf suchen: Sektor, dessen erster Eintrag die hoechste Nummer hat.
  // Sektoren mit unbekanntem Inhalt gelten als frei; jeder Sektor wird vor
  // der Benutzung ohnehin geloescht (siehe schreibe()).
  Eintrag e;
  uint32_t max_nr = 0;
  bool gefunden = false;
  kopf_sektor = 0;
  kopf_index = 0;
  naechste_nr = 1;
  for (uint32_t s = 0; s < sektoren; s++) {
    lese(s, 0, e);
    if (!gueltig(e)) continue;
    if (e.nr >= max_nr) { max_nr = e.nr; kopf_sektor = s; gefunden = true; }
  }
  if (gefunden) {
    // Erste leere Position im Kopfsektor; halb geschriebene Eintraege
    // (Stromausfall beim Schreiben) werden uebersprungen.
    kopf_index = PRO_SEKTOR;
    for (uint32_t i = 0; i < PRO_SEKTOR; i++) {
      lese(kopf_sektor, i, e);
      if (leer(e)) { kopf_index = i; break; }
      if (gueltig(e)) naechste_nr = e.nr + 1;
    }
  }
  bereit = true;
  ESP_LOGI(TAG, "Ereignislog bereit: %u Sektoren, Grenze %u Sektoren (%u %%), naechste Nr. %u",
           (unsigned) sektoren, (unsigned) grenze, (unsigned) MAX_PROZENT, (unsigned) naechste_nr);
}

static void schreibe(uint8_t typ, bool steigend, uint16_t wert, uint32_t unixzeit) {
  if (!bereit) return;
  if (kopf_index >= PRO_SEKTOR || naechste_nr == 1) {
    // naechste_nr == 1: leeres Log, erster Eintrag kommt in den aktuellen Sektor
    uint32_t neu = (naechste_nr == 1 && kopf_index == 0) ? kopf_sektor : (kopf_sektor + 1) % sektoren;
    // Grenze einhalten: aelteste Sektoren loeschen, bis Platz fuer den neuen ist
    int32_t aeltester;
    while (belegte_sektoren(&aeltester, neu) + 1 > grenze && aeltester >= 0) {
      ESP_LOGI(TAG, "70-%%-Grenze erreicht, loesche aeltesten Sektor %d", (int) aeltester);
      loesche_sektor(aeltester);
    }
    loesche_sektor(neu);  // immer loeschen: alter Inhalt oder unbekannte Daten
    kopf_sektor = neu;
    kopf_index = 0;
  }
  Eintrag e{naechste_nr++, unixzeit, (uint32_t) (millis() / 1000),
            (uint8_t) (MAGIC | (steigend ? FLANKE_BIT : 0) | (typ & 0x07)), 0, wert};
  e.pruef = crc8(e);
  esp_partition_write(bereich, kopf_sektor * SEKTOR + kopf_index * sizeof(Eintrag), &e, sizeof(e));
  kopf_index++;
}

static uint32_t eintraege() {
  if (!bereit) return 0;
  uint32_t n = belegte_sektoren(nullptr);
  if (n == 0) return 0;
  return (n - 1) * PRO_SEKTOR + kopf_index;
}
static float fuellstand() {
  if (!bereit || sektoren == 0) return 0;
  return 100.0f * eintraege() / (sektoren * PRO_SEKTOR);
}

static std::string text(const Eintrag &e) {
  char zeit[24];
  if (e.zeit > 1600000000) {
    auto t = esphome::ESPTime::from_epoch_local(e.zeit);
    snprintf(zeit, sizeof(zeit), "%s", t.strftime("%d.%m.%Y %H:%M:%S").c_str());
  } else {
    snprintf(zeit, sizeof(zeit), "Laufzeit %lus", (unsigned long) e.laufzeit);
  }
  const char *flanke = e.steigend() ? "steigend" : "fallend";
  char zeile[128];
  uint8_t typ = e.art();
  if (typ == KARTE) {
    if (e.wert == KEINE_NUMMER)
      snprintf(zeile, sizeof(zeile), "#%lu | %s | Karte ohne Nummer %s | %s", (unsigned long) e.nr, zeit,
               e.steigend() ? "aufgelegt" : "entfernt", flanke);
    else
      snprintf(zeile, sizeof(zeile), "#%lu | %s | Karte %u %s | %s", (unsigned long) e.nr, zeit, e.wert,
               e.steigend() ? "aufgelegt" : "entfernt", flanke);
  } else {
    static const char *namen[] = {"", "", "leiser", "lauter", "zurueck", "weiter"};
    const char *name = typ <= WEITER ? namen[typ] : "?";
    snprintf(zeile, sizeof(zeile), "#%lu | %s | Taste %s %s | %s%s", (unsigned long) e.nr, zeit, name,
             e.steigend() ? "gedrueckt" : "losgelassen", flanke, e.wert ? "" : " (gesperrt, keine Karte)");
  }
  return zeile;
}

// Ausgabe aller Eintraege, aelteste zuerst, in kleinen Paketen (siehe interval)
static void ausgabe_starten() {
  if (!bereit) return;
  int32_t aeltester;
  if (belegte_sektoren(&aeltester) == 0 || aeltester < 0) {
    ESP_LOGI(TAG, "Ereignislog ist leer");
    return;
  }
  ausgabe_sektor = aeltester;
  ausgabe_index = 0;
  ausgabe_aktiv = true;
  ESP_LOGI(TAG, "===== Ereignislog Anfang (%u Eintraege, %.1f %% belegt) =====", (unsigned) eintraege(), fuellstand());
}

static void ausgabe_schritt(uint32_t anzahl) {
  if (!ausgabe_aktiv) return;
  Eintrag e;
  for (uint32_t n = 0; n < anzahl; n++) {
    bool ende_sektor = ausgabe_index >= PRO_SEKTOR;
    if (!ende_sektor) {
      lese(ausgabe_sektor, ausgabe_index, e);
      if (!leer(e)) {
        if (gueltig(e)) ESP_LOGI(TAG, "%s", text(e).c_str());  // halb geschriebene ueberspringen
        ausgabe_index++;
        continue;
      }
      ende_sektor = true;
    }
    if (ausgabe_sektor == kopf_sektor) {
      ausgabe_aktiv = false;
      ESP_LOGI(TAG, "===== Ereignislog Ende =====");
      return;
    }
    ausgabe_sektor = (ausgabe_sektor + 1) % sektoren;
    ausgabe_index = 0;
  }
}

}  // namespace elog
