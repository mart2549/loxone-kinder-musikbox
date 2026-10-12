// =====================================================================
// Loxone Kinder-Musikbox  (NFC-Station fuer Loxone Audioserver)
// VARIANTE WLAN + USB-C: Seeed XIAO ESP32C3 + PN532 NFC V3
// Parametrisch, OpenSCAD 2021+.  Alle Masse in mm.
//
// Teile (part = ...):
//   "base"     Unterteil mit Halterungen und USB-C-Oeffnung
//   "lid"      Deckel mit Kartenmulde und Griffmulden
//   "diffuser" Lichtleiste fuer die Front (transparent/weiss drucken)
//   "diffuser_duenn" Lichtleiste, Zapfen hohl, vorn 0,8 mm (heller)
//   "diffuser_dummy" Platzhalter fuer das geschlossene Fenster (base mit -D fenster_haut=0.6)
//   "stand"    Kartenstaender
//   "caps"     4 Tastkappen mit Piktogrammen (Flansch nach unten drucken)
//   "all"      Uebersicht
//
// VOR DEM DRUCK MIT DEN ECHTEN PLATINEN PRUEFEN:
//   esp_l, esp_w, esp_t, usb_* (XIAO ESP32C3 laut Seeed 20 x 17,5 mm)
//   pn_w, pn_d           (PN532 V3 ca. 42,7 x 40,4 mm)
//   sw_h                 (Kurzhubtaster 6 x 6 mm, Hoehe 5 mm gemessen)
// =====================================================================

part = "all";

/* ---------- Gehaeuse ---------- */
W      = 144;    // Aussenbreite (x)
D      = 88;     // Aussentiefe  (y)
H      = 28;     // Aussenhoehe inkl. Deckel
wall   = 3;
flr    = 2.4;    // Bodenstaerke
R      = 10;     // Eckradius aussen
lidT   = 4;      // Deckelstaerke
clr    = 0.25;   // Spiel Deckel zu Wand

/* ---------- Karte ---------- */
card_w = 85.6;   card_d = 54;
rec_w  = 89;     // Mulde (Karte + Spiel, auch fuer laminierte Karten)
rec_d  = 58;
rec_r  = 4.5;
rec_h  = 2.2;    // Muldentiefe, Restboden = lidT - rec_h = 1,8 mm
rec_cx = wall + 54;   // Muldenmitte x (4 mm nach rechts, Platz fuer die Rampe links)
rec_cy = D/2;

/* ---------- Seeed XIAO ESP32C3 ---------- */
esp_l  = 20.5;   // Laenge (y), USB-C zeigt nach hinten. gemessen 28.09.: Platine ca. 20 mm, Buchse steht ca. 2 mm ueber (ragt in die Wandoeffnung)
esp_w  = 17.8;   // Breite (x), Foto ca. 17,5 mm, mit Reserve
esp_t  = 1.2;    // Platinenstaerke
esp_z  = flr + 3;            // Unterkante Platine
esp_x0 = 88;                 // linke Platinenkante
usb_w  = 10;     // Ausschnitt USB-C-Buchse (Buchse ca. 9 x 3,2)
usb_h  = 4.2;
usb_cb_w = 13.5; // Senkung aussen fuer den Steckerkoerper
usb_cb_h = 7.5;
usb_cb_d = 2;    // Tiefe der Senkung, Restwand = wall - usb_cb_d

/* ---------- PN532 V3 ---------- */
pn_w   = 42.7;   pn_d = 40.4;   pn_t = 1.6;
pn_cx  = wall + 50; pn_cy = rec_cy;

/* ---------- Tasten (2 x 2) ---------- */
btn_cx  = (rec_cx + rec_w/2 + 1.2 + W - wall - clr) / 2;  // Mitte Tastenfeld x
btn_cy  = rec_cy;
btn_px  = 7*2.54;  // Raster x = 7 Loecher im Lochraster (17,78 mm)
btn_py  = 7*2.54;  // Raster y
cap_d   = 13;    // Kappe sichtbar
cap_fl  = 16;    // Flansch unter dem Deckel
cap_flt = 1.2;
cap_up  = 1.5;   // Ueberstand ueber Deckel
nase_h  = 2.0;   // Verdrehnase: Hoehe ueber dem Flansch, bleibt unter dem Deckel verborgen
nut_t   = 2.4;   // Nut fuer die Nase, von unten in den Deckel, oben bleiben 1,6 mm geschlossen
sw_h    = 5.0;   // Taster 6x6 mm, Hoehe inkl. Stoessel (gemessen 29.09.2026)
pb_w    = 16*2.54;  // Lochfeld 16 x 16 Loecher; Platine selbst 43,18 mm (halbe Randreihe), max. 45 mm
pb_d    = 16*2.54;
pb_t    = 1.6;
pb_cy   = btn_cy - 2;   // (nicht mehr verwendet)
// Platinenursprung (linke vordere Ecke): Taster S1 liegt im Raster bei
// Spalte 6,5 / Reihe 6 (Mitte 15,24 / 13,97 mm vom Ursprung)
pb_x0   = btn_cx - btn_px/2 - 15.24;
pb_y0   = btn_cy - btn_py/2 - 13.97;
pb_top  = H - lidT - cap_flt - sw_h - 0.2;   // 0,2 mm Leerweg zwischen Stoessel und Kappe
// Reihenfolge: [x-Index, y-Index, Symbol]
btn_list = [[-1, -1, "minus"], [1, -1, "plus"], [-1, 1, "prev"], [1, 1, "next"]];
function btn_pos(b) = [btn_cx + b[0]*btn_px/2, btn_cy + b[1]*btn_py/2];

/* ---------- LED-Lichtleiste ---------- */
led_w  = 78;     led_h = 4;     led_z = 10;   // Fenster deckt alle 10 LEDs ab (Rasterabstand ca. 8 mm)
led_pcb_l = 80;  led_pcb_t = 1.6;  // Soldered WS2812B-Stick, 10 LEDs, 80 x 10 mm
led_pcb_b = 10;    // Breite gemessen 30.09.2026
led_rand  = 1.0;   // Kante bis LED-Rand, gemessen 30.09.2026 (LEDs sitzen an einer Laengskante)
led_mitte = led_rand + 2.5;              // LED-Mitte ab LED-Kante (LED 5 x 5 mm)
// Einbau: LEDs zeigen zur Front, Anschluesse rechts (x+) -> LED-Kante liegt oben
led_zo  = led_z + led_h/2 + led_mitte;  // Oberkante Platine
led_zu  = led_zo - led_pcb_b;           // Unterkante Platine

$fn = 48;
zl = H - lidT;   // Unterkante Deckel

// ---------------------------------------------------------------------
module rr2(w, d, r) { translate([r, r]) offset(r = r) square([w - 2*r, d - 2*r]); }
module inner2(o = 0) { translate([wall - o, wall - o]) rr2(W - 2*wall + 2*o, D - 2*wall + 2*o, R - wall + o); }

module outer_body() {
    c1 = 1.0; c2 = 0.8;
    hull() {
        linear_extrude(0.01) offset(delta = -c1) rr2(W, D, R);
        translate([0, 0, c1]) linear_extrude(H - c1 - c2) rr2(W, D, R);
        translate([0, 0, H - 0.01]) linear_extrude(0.01) offset(delta = -c2) rr2(W, D, R);
    }
}

fuss_d = 12.4;  fuss_t = 1.0;   // Vertiefung fuer Fuesse (Gummi oder Filz, bis 12 mm), Unterteil und Kartenstaender
fuss_rand = wall + 5.5;           // Abstand Fussmitte zur Aussenkante
post_pos = [[wall + 5.5, wall + 5.5], [W - wall - 5.5, wall + 5.5],
            [wall + 5.5, D - wall - 5.5], [W - wall - 5.5, D - wall - 5.5]];

// ============================ UNTERTEIL ==============================
module base() {
    difference() {
        union() {
            difference() {
                outer_body();
                translate([0, 0, flr]) linear_extrude(H) inner2();
            }
            // Schraubdome Ecken
            for (p = post_pos) translate([p[0], p[1], flr - 0.1])
                cylinder(d = 10, h = zl - flr + 0.1);
            // Auflagekante fuer Deckel (mit 45-Grad-Fase, stuetzfrei druckbar), durchgehend.
            // Die Lichtleiste wird oben 10 bis 15 Grad nach hinten geneigt an der Kante vorbei
            // abgesenkt (Einbausimulation 01.10.2026).
            translate([0, 0, zl - 2.8]) difference() {
                linear_extrude(2.8) inner2();
                hull() {
                    translate([0, 0, -0.01]) linear_extrude(0.01) inner2(-0.01);
                    translate([0, 0, 1.6]) linear_extrude(1.21) inner2(-1.6);
                }
            }
            esp_mount();
            pn_mount();
            mulde_stuetze();
            led_holder();
            pb_mount();
        }
        // Schraubloecher fuer M3 x 16 Senkkopf (Gewinde schneidet sich in den Kunststoff)
        for (p = post_pos) translate([p[0], p[1], zl - 15]) cylinder(d = 2.6, h = 16);  // M3 x 16
        // USB-C-Oeffnung Rueckwand mit Senkung fuer den Steckerkoerper
        ucx = esp_x0 + esp_w/2;
        ucz = esp_z + esp_t + usb_h/2 - 0.5;
        translate([ucx, D - wall - 1, ucz]) rotate([-90, 0, 0])
            linear_extrude(wall + 2) offset(r = 1.2) square([usb_w - 2.4, usb_h - 2.4], center = true);
        translate([ucx, D - usb_cb_d, ucz]) rotate([-90, 0, 0])
            linear_extrude(usb_cb_d + 1) offset(r = 2.5) square([usb_cb_w - 5, usb_cb_h - 5], center = true);
        // Lichtleiste Front. Mit fenster_haut > 0 bleibt aussen eine duenne Haut stehen,
        // die sich spaeter mit dem Messer herausschneiden laesst.
        translate([rec_cx - led_w/2, fenster_haut > 0 ? fenster_haut : -1, led_z])
            cube([led_w, wall + 1 - (fenster_haut > 0 ? fenster_haut : -1), led_h]);
        // Vertiefungen fuer Gummi- bzw. Filzfuesse (bis d 12)
        for (p = post_pos) translate([p[0], p[1], -0.01]) cylinder(d = fuss_d, h = fuss_t + 0.01);
    }
}

// XIAO: Auflagen vorn/hinten, Seitenfuehrungen, Schnapphaken vorn.
// Hinten stuetzt sich die Platine an der Rueckwand ab (Steckkraft), die
// USB-C-Buchse sitzt im Wandausschnitt und haelt die Platine unten.
module esp_mount() {
    yb = D - wall;            // Hinterkante Platine (an Innenwand)
    yf = yb - esp_l;          // Vorderkante Platine
    // Auflagen
    translate([esp_x0, yb - 3, flr - 0.1]) cube([esp_w, 3, esp_z - flr + 0.1]);
    // vordere Auflage 0,6 mm zurueckgesetzt: 0,8 mm Spalt zu den Schnapphaken, damit sie beim Druck
    // nicht mit der Auflage verschmelzen und frei federn (Montagesimulation 01.10.2026)
    translate([esp_x0, yf + 0.6, flr - 0.1]) cube([esp_w, 2.4, esp_z - flr + 0.1]);
    // Seitenfuehrungen nur an den Enden (je 4 mm ueber den Auflagen). Dazwischen bleibt die Seite
    // offen, damit Adern auch unter der Platine seitlich herausgefuehrt werden koennen und
    // Loetstellen an den Randpads nicht an der Fuehrung anstehen.
    for (yy = [yf, yb - 4]) {
        translate([esp_x0 - 0.2 - 1.6, yy, flr - 0.1]) cube([1.6, 4, esp_z + esp_t + 1.5 - flr]);
        translate([esp_x0 + esp_w + 0.2, yy, flr - 0.1]) cube([1.6, 4, esp_z + esp_t + 1.5 - flr]);
    }
    // Fester Anschlag zwischen den Haken: nimmt die Steckkraft des USB-Kabels auf, die Haken halten
    // nur nach oben. Anschlagflaeche auf der urspruenglichen Taschengrenze yf (Platz nicht vergroessert),
    // endet 0,3 mm unter der Platinenoberseite und 0,8 mm neben den Haken.
    translate([esp_x0 + 5.3, yf - 2, flr - 0.1]) cube([esp_w - 10.6, 2, esp_z + esp_t - 0.3 - flr + 0.1]);
    translate([esp_x0 + 5.3, yf - 0.1, flr - 0.1]) cube([esp_w - 10.6, 0.8, esp_z - flr + 0.1]);
    // Schnapphaken an der Vorderkante (zwei Stueck an den Ecken)
    for (xx = [esp_x0 + 0.5, esp_x0 + esp_w - 4.5]) snap_hook(xx, yf - 0.2);
}

module snap_hook(x, y) {
    t = 1.3; w = 4; top = esp_z + esp_t + 0.15;   // 1,3 mm: Biegedehnung beim Einrasten ca. 2,9 % statt 3,6 %
    translate([x, y - t, flr - 0.1]) cube([w, t, top - flr + 0.1]);
    // Haken mit Einfuehrschraege
    translate([x, y, top]) rotate([90, 0, 90]) linear_extrude(w)
        polygon([[-t, 0], [1.0, 0], [1.0, 0.4], [-t, 2.6]]);
}

// PN532 (HW-147): umlaufender Rahmen. Die Platine liegt mit dem Rand (Antennenstreifen,
// bauteilfrei) auf einem 1,8 mm breiten Steg, seitlich gefuehrt, der Deckel klemmt von oben.
// Bestueckungsseite nach unten, glatte Rueckseite nach oben zum Deckel.
// I2C-Loetpunkte (SCL, SDA, VCC, GND) zeigen nach rechts zum XIAO; dort ein Durchlass fuer die Adern.
pn_steg = 1.8;
module pn_mount() {
    ztop = zl - 0.1;          // Oberkante Platine = Unterseite Deckel
    zbot = ztop - pn_t;
    x0 = pn_cx - pn_w/2 - 0.3; y0 = pn_cy - pn_d/2 - 0.3;
    difference() {
        translate([x0 - 1.5, y0 - 1.5, flr - 0.1]) cube([pn_w + 0.6 + 3, pn_d + 0.6 + 3, ztop - flr + 0.1]);
        // Tasche fuer die Platine (seitliche Fuehrung)
        translate([x0, y0, zbot]) cube([pn_w + 0.6, pn_d + 0.6, 10]);
        // Innenraum fuer die Bauteile, Steg bleibt stehen
        translate([x0 + 0.3 + pn_steg, y0 + 0.3 + pn_steg, flr]) cube([pn_w - 2*pn_steg, pn_d - 2*pn_steg, 40]);
        // Durchlass rechts fuer die 4 Adern, nach oben offen: die umgebogene Stiftleiste
        // (bis 9 mm unter Oberkante Platine, steht seitlich ueber die Kante) wird von oben eingelegt
        translate([x0 + pn_w - 5, pn_cy - 8, flr]) cube([10, 16, 40]);
    }
}

// Stuetze unter dem rechten Streifen der Kartenmulde (zwischen PN532 und Tasterplatine).
// 0,2 mm kuerzer als der Deckelabstand: traegt erst, wenn sich der Muldenboden durchbiegt.
mulde_stuetze = [88, 30];
module mulde_stuetze() {
    translate([mulde_stuetze[0], mulde_stuetze[1], flr - 0.1]) union() {
        cylinder(d = 4, h = zl - 0.2 - flr + 0.1);
        cylinder(d1 = 9, d2 = 4, h = 5);
    }
}

// (Halter fuer den LED-Stick, siehe unten)
// Halter fuer den LED-Stick (Stand 30.09.2026)
// Die Lichtleiste wird von innen eingesetzt, ihr Flansch (1,2 mm) liegt innen an der Vorderwand
// und ist 84 mm breit. Die Halter stehen deshalb frei auf dem Boden hinter dem Flansch:
//  - hintere Stuetzen 4 x 4 mm, unten auf 8 mm verbreitert
//  - an beiden Enden ein Sockel, auf dem die Platine steht, und eine vordere Lippe bis unter die LEDs
//  - hinten links eine Stuetze am Ende (unbenutzte Pads), hinten rechts eine Stuetze 12 mm vom Ende
//    entfernt, damit die Loetpads mit den Adern frei bleiben
led_fl_t  = 1.2;                                  // Flanschdicke Lichtleiste
led_y_fl  = wall + led_fl_t;                      // Rueckseite Flansch
led_y_lip = led_y_fl + 0.4;                       // Lippe beginnt 0,4 mm hinter dem Flansch
led_y_pcb = led_y_lip + 1.6;                      // Vorderseite Platine (LEDs 1,6 mm davor)
module led_holder() {
    zb = flr - 0.1;
    sl = led_pcb_t + 0.2;
    z_lip = led_z + led_h/2 - 2.5 - 0.5;          // Oberkante Lippe: 0,5 mm unter den LEDs
    for (sx = [-1, 1]) {
        x0 = rec_cx + sx*(led_pcb_l/2 - 1.5) - 1.5;
        translate([x0, led_y_lip, zb]) cube([3, led_y_pcb - led_y_lip, z_lip - zb]);        // Lippe
        // Lippe bis zur Vorderwand ausgefuellt (steifer). Liegt in der Kerbe des Lichtleisten-Flanschs.
        translate([x0, wall - 0.01, zb]) cube([3, led_y_lip - wall + 0.02, z_lip - zb]);
        translate([x0, led_y_lip, zb]) cube([3, led_y_pcb + sl + 2 - led_y_lip, led_zu - zb]); // Sockel
    }
    // Endanschlaege links und rechts am LED-Stick (je 0,2 mm Luft). Nur 1,3 mm ueber dem Sockel und
    // nur bis zur Platinenrueckseite: so bleibt der Einsetzweg der Lichtleiste frei (Flansch-Unterkante
    // beim Absenken 7,0) und hinter der Platine Platz fuer Adern und Elko.
    for (sx = [-1, 1]) {
        xe = rec_cx + sx*(led_pcb_l/2 + 0.2) - (sx < 0 ? 1.5 : 0);
        translate([xe, led_y_lip, zb]) cube([1.5, led_y_pcb + led_pcb_t + 0.2 - led_y_lip, led_zu + 1.3 - zb]);
        translate([rec_cx + sx*led_pcb_l/2 - 0.3, led_y_lip, zb]) cube([0.6, led_y_pcb + led_pcb_t + 0.2 - led_y_lip, led_zu - zb]);
    }
    // hintere Stuetzen: 4 x 4 mm, zum Boden hin auf 8 mm Tiefe verbreitert
    for (xb = [rec_cx - led_pcb_l/2, rec_cx + led_pcb_l/2 - 12])
        translate([xb, led_y_pcb + sl, zb]) hull() {
            cube([4, 4, led_zo + 1 - zb]);
            cube([4, 8, 0.01]);
        }
}

// ============================== DECKEL ===============================
module lid() {
    difference() {
        hull() {
            linear_extrude(lidT - 0.6) inner2(-clr);
            linear_extrude(lidT) inner2(-clr - 0.6);
        }
        // Kartenmulde mit Einfuehrfase
        translate([rec_cx, rec_cy, lidT - rec_h]) hull() {
            linear_extrude(rec_h - 0.8) translate([-rec_w/2, -rec_d/2]) rr2(rec_w, rec_d, rec_r);
            translate([0, 0, rec_h + 0.01]) linear_extrude(0.01)
                translate([-rec_w/2 - 1.2, -rec_d/2 - 1.2]) rr2(rec_w + 2.4, rec_d + 2.4, rec_r + 1.2);
        }
        // Rampe links: Karte laesst sich seitlich aus der Mulde schieben
        hull() {
            translate([rec_cx - rec_w/2 + 3, rec_cy - rec_d/2, lidT - rec_h]) cube([0.01, rec_d, rec_h + 1]);
            translate([-1, rec_cy - rec_d/2 - 3, lidT]) cube([0.01, rec_d + 6, 1]);
        }
        // Griffmulden vorn und hinten: Finger gleitet unter die Kartenkante
        for (sy = [-1, 1]) translate([rec_cx, rec_cy + sy*rec_d/2, 0.9 + 6])
            scale([14, 10, 6]) sphere(r = 1, $fn = 40);
        // Senkkopfschrauben M3
        for (p = post_pos) translate([p[0], p[1], -1]) {
            cylinder(d = 3.4, h = lidT + 2);
            translate([0, 0, lidT + 1 - 1.9]) cylinder(d1 = 3.4, d2 = 6.6, h = 1.91);
        }
        // Tastenloecher mit Verdrehsicherung
        for (b = btn_list) translate([btn_pos(b)[0], btn_pos(b)[1], -1]) {
            cylinder(d = cap_d + 0.6, h = lidT + 2, $fn = 64);
            // Nut nur von unten, von aussen nicht sichtbar
            translate([-0.8, 0, 0]) cube([1.6, cap_d/2 + 1.1, 1 + nut_t]);
        }
    }
}

module note2() {
    s = 1.0;
    for (dx = [-6.5, 6.5]) {
        translate([dx - 2.2, -6]) rotate(-20) scale([1.35, 1]) circle(r = 3.2);
        translate([dx + 1.3, -6]) square([1.5, 17]);
    }
    translate([-5.2, 9]) polygon([[0, 0], [14.5, 1.6], [14.5, 4.8], [0, 3.2]]);
}

// ============================ LICHTLEISTE ============================
// Kerben unten im Flansch an den Lippen des LED-Halters: Ohne sie laesst sich die
// Lichtleiste nicht von innen bis in den Schlitz schieben (Einbausimulation 01.10.2026).
diff_kerbe_h = 2.6;
module diff_kerben() {
    for (xm = [rec_cx - led_pcb_l/2 + 1.5, rec_cx + led_pcb_l/2 - 1.5])
        translate([xm - (rec_cx - led_w/2 - 3) - 2.25, -1, -1]) cube([4.5, 1 + diff_kerbe_h, 1 + 1.2 + 0.01]);
}
module diffuser() {
    difference() {
        union() {
            cube([led_w + 6, led_h + 6, 1.2]);
            translate([3 + 0.15, 3 + 0.15, 1.2]) cube([led_w - 0.3, led_h - 0.3, wall - 0.2]);
        }
        diff_kerben();
    }
}
// Duenne Variante: Zapfen von hinten ausgehoehlt, vorn bleibt eine Wand von diff_front mm.
// Heller, die einzelnen LEDs sind eher als Punkte zu sehen.
diff_front = 0.8;
// Variante "Fenster zu": aussen duenne Haut im Lichtschlitz (0 = Fenster offen)
fenster_haut = 0;
// Dummy statt Lichtleiste fuer das geschlossene Fenster: gleicher Flansch, Zapfen um die
// Hautdicke kuerzer. Haelt den LED-Stick genauso auf Abstand wie die echte Lichtleiste.
// Nur ein Rahmen: durchgehende Oeffnung, damit das Licht ungehindert auf die Haut faellt.
// Waende oben/unten 0,5 mm (wie duenne Lichtleiste), an den Enden 2 mm fuer Stabilitaet.
dummy_haut = 0.6;
dummy_ende = 2.0;
module diffuser_dummy() {
    difference() {
        union() {
            cube([led_w + 6, led_h + 6, 1.2]);
            translate([3 + 0.15, 3 + 0.15, 1.2]) cube([led_w - 0.3, led_h - 0.3, wall - 0.2 - dummy_haut]);
        }
        diff_kerben();
        translate([3 + 0.15 + dummy_ende, 3 + 0.15 + 0.5, -1])
            cube([led_w - 0.3 - 2*dummy_ende, led_h - 0.3 - 1.0, 10]);
    }
}
module diffuser_duenn() {
    difference() {
        diffuser();
        translate([3 + 0.15 + 1.0, 3 + 0.15 + 0.5, -0.01])
            cube([led_w - 0.3 - 2.0, led_h - 0.3 - 1.0, 1.2 + wall - 0.2 - diff_front + 0.01]);
    }
}

// ========================== KARTENSTAENDER ===========================
st_n = 12; st_pitch = 7.5; st_slot = 2.2; st_tilt = 12;
module stand() {
    sw = card_w + 10; sd = st_n*st_pitch + 12; sh = 22;
    difference() {
        hull() {
            linear_extrude(sh - 1) rr2(sw, sd, 6);
            translate([0, 0, sh - 0.01]) linear_extrude(0.01) offset(delta = -1) rr2(sw, sd, 6);
        }
        for (i = [0:st_n - 1]) translate([5 - 0.5, 8 + i*st_pitch, 6])
            rotate([-st_tilt, 0, 0]) cube([card_w + 1, st_slot, 40]);
        // Vertiefungen fuer Fuesse wie am Unterteil
        for (x = [fuss_rand, sw - fuss_rand], y = [fuss_rand, sd - fuss_rand])
            translate([x, y, -0.01]) cylinder(d = fuss_d, h = fuss_t + 0.01, $fn = 64);
    }
}

// ============================ TASTEN ================================
// Lochrasterplatine auf 3 Domen und 3 Stuetzen, M2,5 x 6 selbstschneidend
// Befestigung: 3 Schrauben M2,5 x 5 in Rasterloechern (Spalte/Reihe ab 1 gezaehlt)
//   A: Sp 2 / R 2    B: Sp 2 / R 15    C: Sp 15 / R 2   (Loch auf 2,7 mm aufbohren)
// dazu eine Stuetze ohne Schraube hinten rechts (unter S4, frei von Loetstellen)
function rl(c, r) = [pb_x0 + (c - 0.5)*2.54, pb_y0 + (r - 0.5)*2.54];
pb_schrauben = [rl(2, 2), rl(2, 15), rl(15, 2)];
pb_stuetze   = [pb_x0 + 35.5, pb_y0 + 38.9];
// Zwei Mittelstuetzen links und rechts der GND-Schiene (Sp 10), jeweils zwischen
// 4 freien Loechern: Sp 8/9 bzw. Sp 11/12, Reihe 10/11. Mind. 1,5 mm Abstand zu jeder Loetstelle.
pb_mitte     = [[pb_x0 + 8*2.54, pb_y0 + 10*2.54], [pb_x0 + 11*2.54, pb_y0 + 10*2.54]];
module pb_mount() {
    for (p = pb_schrauben) translate([p[0], p[1], flr - 0.1]) difference() {
        union() {
            cylinder(d = 6, h = pb_top - pb_t - flr + 0.1);
            cylinder(d1 = 9, d2 = 6, h = 4);
        }
        translate([0, 0, 2]) cylinder(d = 2.1, h = 40);
    }
    translate([pb_stuetze[0], pb_stuetze[1], flr - 0.1]) union() {
        cylinder(d = 3, h = pb_top - pb_t - flr + 0.1);
        cylinder(d1 = 7, d2 = 3, h = 4);
    }
    for (p = pb_mitte) translate([p[0], p[1], flr - 0.1]) union() {
        cylinder(d = 3, h = pb_top - pb_t - flr + 0.1);
        cylinder(d1 = 7, d2 = 3, h = 4);
    }
}

module symbol2(t) {
    if (t == "plus")  { square([7, 2], center = true); square([2, 7], center = true); }
    if (t == "minus") { square([7, 2], center = true); }
    if (t == "next")  { translate([-3.6, 0]) polygon([[0, -2.8], [3, 0], [0, 2.8]]);
                        translate([-1.2, 0]) polygon([[0, -2.8], [3.2, 0], [0, 2.8]]);
                        translate([2.3, -2.8]) square([1.3, 5.6]); }
    if (t == "prev")  { mirror([1, 0]) symbol2("next"); }
}

// Kappe, Flansch unten auf z = 0, Oberseite oben
module cap(t) {
    stem = lidT + cap_up;
    difference() {
        union() {
            cylinder(d = cap_fl, h = cap_flt, $fn = 64);
            hull() {
                cylinder(d = cap_d, h = cap_flt + stem - 0.6, $fn = 64);
                cylinder(d = cap_d - 1.2, h = cap_flt + stem, $fn = 64);
            }
            // Nase gegen Verdrehen, endet unter der Deckeloberflaeche
            translate([-0.6, 0, 0]) cube([1.2, cap_d/2 + 0.8, cap_flt + nase_h]);
        }
        translate([0, 0, cap_flt + stem - 0.6]) linear_extrude(1) symbol2(t);
    }
}
module caps() {
    for (b = btn_list) translate([btn_pos(b)[0], btn_pos(b)[1], 0]) cap(b[2]);
}

// ============================== AUSGABE ==============================
if (part == "base") base();
else if (part == "lid") lid();
else if (part == "diffuser") diffuser();
else if (part == "diffuser_duenn") diffuser_duenn();
else if (part == "diffuser_dummy") diffuser_dummy();
else if (part == "stand") stand();
else if (part == "caps") caps();
else {
    color("#7CC6BA") base();
    color("#F4F1EA") translate([0, 0, zl]) lid();
    color("#F4B6A6") translate([0, -110, 0]) stand();
}
