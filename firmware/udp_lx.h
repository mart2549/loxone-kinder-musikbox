// UDP-Versand an den Loxone Miniserver mit einstellbarer Zieladresse und Port
// (Einstellungen auf der Statusseite, gespeichert im Flash). Ersetzt die feste
// ESPHome-UDP-Komponente, damit eine Firmware fuer alle Boxen genuegt.
#pragma once
#include <string>
#include <cerrno>
#include "lwip/sockets.h"
#include "lwip/inet.h"
#include "esphome/core/log.h"

namespace udp_lx {

static const char *const TAG = "udp_lx";
static int fd = -1;

// true, wenn ip eine vollstaendige IPv4-Adresse ist (z. B. 192.168.178.10)
// Streng: genau 4 Zahlen 0 bis 255, durch Punkte getrennt (lwIP akzeptiert auch Kurzformen)
inline bool ip_gueltig(const std::string &ip) {
  int teile = 0, wert = -1, ziffern = 0;
  for (char c : ip) {
    if (c >= '0' && c <= '9') {
      wert = (wert < 0 ? 0 : wert) * 10 + (c - '0');
      if (++ziffern > 3 || wert > 255) return false;
    } else if (c == '.') {
      if (wert < 0) return false;
      teile++; wert = -1; ziffern = 0;
    } else {
      return false;
    }
  }
  return wert >= 0 && teile == 3;
}

inline bool senden(const std::string &ip, int port, const std::string &msg) {
  if (port < 1 || port > 65535) {
    ESP_LOGE(TAG, "Ungueltiger UDP-Port %d, nicht gesendet", port);
    return false;
  }
  struct sockaddr_in ziel {};
  ziel.sin_family = AF_INET;
  ziel.sin_port = htons((uint16_t) port);
  if (!ip_gueltig(ip) || inet_pton(AF_INET, ip.c_str(), &ziel.sin_addr) != 1) {
    ESP_LOGE(TAG, "Ungueltige Loxone-IP '%s', nicht gesendet", ip.c_str());
    return false;
  }
  if (fd < 0) {
    fd = ::socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (fd < 0) {
      ESP_LOGE(TAG, "UDP-Socket nicht verfuegbar (errno %d)", errno);
      return false;
    }
  }
  int r = ::sendto(fd, msg.data(), msg.size(), 0, (struct sockaddr *) &ziel, sizeof(ziel));
  if (r < 0) {
    ESP_LOGW(TAG, "Senden fehlgeschlagen (errno %d)", errno);
    ::close(fd);
    fd = -1;
    return false;
  }
  return true;
}

}  // namespace udp_lx
