#pragma once

#define AIRPLAY_MODEL "AirPort10,115"

/**
 * Initialize mDNS and advertise AirPlay 2 services
 *
 * This publishes:
 * - _airplay._tcp service (AirPlay 2)
 * - _raop._tcp service (Remote Audio Output Protocol)
 *
 * With all required TXT records for iOS to recognize the device
 */
void mdns_airplay_init(void);

/**
 * Re-announce all mDNS services on active network interfaces.
 *
 * Sends gratuitous mDNS announcements to keep the device visible
 * in AirPlay device lists during extended uptime. Should be called
 * periodically (e.g. every 5 minutes).
 */
void mdns_airplay_reannounce(void);
