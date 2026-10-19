# IP Pilot

**Switch your IP address in one click, and keep an eye on your network.** A free macOS app with a cartoon-style interface: a living mascot, a cable tongue that wiggles, an RJ45 plug that connects, a night mode, in English and French.

## What it does

- **Setup**: create network profiles (static IP or DHCP, subnet mask, gateway, DNS, one or several interfaces) and apply them in one click. A ping test checks the connection after a profile is applied. A menu in the top menu bar lets you switch profiles without opening the window.
- **Devices**: an inventory of everything seen on the network (name, IP, MAC address, manufacturer, last seen). You can rename a device, add a note or pin it. The name is remembered through the MAC address, even if the IP changes. Three tools help you find your way around a network:
  - **Radar**: finds devices when you don't know which network you are on. It pings the usual address ranges to see who answers, or, with "listen only", sends nothing and just listens for devices talking. Devices are grouped by range, you can add your own ranges, and one click puts your Mac on a range you found.
  - **Switch**: draws a diagram of a network switch (read-only). It listens for the switch's LLDP/CDP announcement to tell you which switch and which port you are plugged into, then reads the switch over SNMP to show which device is on which port, with names and IPs. Requires a managed switch with SNMP enabled.
  - **Change IP**: change the IP address (and subnet mask) of a device whose protocol is supported, or switch it to DHCP, without the manufacturer's software. Supported: Art-Net, CODA, Shure (ULX-D) and L-Acoustics. "Check" first detects the device's protocol without changing anything, and the app asks for confirmation before applying.
- **Monitoring**: an "N / M devices" banner and a list showing each device's latency and a 30-minute history (green, orange or red depending on dropouts). Latency, jitter, packet-loss and throughput graphs, an event history, and continuous monitoring of a chosen device to hunt micro-dropouts. CSV export available.
- **Protocols** *(beta)*: passive listening to audio and lighting production protocols: OSC, Art-Net, PTP, Dante / AES67, MA-Net and MIDI.

## Installation

1. Download the folder (or the latest version from **Releases**).
2. Open Terminal and type: `bash creer_app.sh`
3. The "IP Pilot" app appears in your Applications folder.

A window automatically lets you know when a new version is available.

## License

© 2026 GOONY — free application: do not modify, do not resell (see `LICENCE.txt`).
