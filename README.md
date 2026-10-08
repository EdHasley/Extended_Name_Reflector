# Extended Name Reflector

A complete XLXD package with an interactive installer and reflector manager. XLXD, AMBED, the PP5PK dark dashboard, Echo Test, configuration files, and service templates are included in this repository. Installation builds the bundled files rather than cloning separate projects.

## Install on a fresh Debian or Ubuntu test VM

Run these commands on the new VM:

```bash
sudo apt update
sudo apt install -y git
git clone https://github.com/EdHasley/Extended_Name_Reflector.git
cd Extended_Name_Reflector
sudo bash installer.sh
```

Download the **whole repository**. A standalone `installer.sh` download is no longer sufficient. Use a fresh test VM; the installer writes system services and the dashboard on the machine where you run it.

## Installation choices

- Three-character protocol ID, such as `X80` for `XLXX80`.
- Separate extended display name, up to 60 characters.
- Enable or disable DExtra, DPlus, DCS, XLX interlink, DMRPlus, DMR MMDVM, YSF, IMRS, and G3 Terminal. Disabled protocols do not open their listening sockets.
- Custom UDP ports. DMR MMDVM defaults to **62030**.
- Optional AMBED installation and configurable transcoder port, default **10100**.
- Public call-home advertising, default **off**.
- Module count, YSF frequency and auto-link, dashboard details, optional Echo Test and HTTPS.

Before compilation, the numbered review menu allows changes to **17: Extended Name**, **18: Protocols and ports**, **19: AMBE**, and **20: Public call-home**, as well as the earlier choices.

This XLXD source supports the protocols listed above. It does not implement M17, P25, or NXDN; these are not presented as working protocol options.

## Manage an installed reflector

```bash
sudo reflector-manager
```

The manager controls users, protocols and ports, YSF/IMRS, AMBED service operation, extended name, public advertising, and optional `header.png` replacement. A replacement PNG must have the installed header's height; its width may vary. The original image is backed up before replacement. The extended display name also appears beneath the dashboard header.

Choose **9: Rebuild XLXD and restart reflector** after changing protocol switches or ports. The manager recompiles installed AMBED too, keeping its port synchronized with XLXD. Enabling AMBED requires it to have been installed with the optional installer choice and compatible hardware.

Installation metadata is in `/etc/extended-name-reflector/reflector.conf`; protocol build settings are in `/usr/src/xlxd/src/main.h`. Dashboard name and advertising settings use `/var/www/html/xlxd/config.inc.php`.

## HTTPS and external dependencies

For automatic HTTPS, the dashboard domain must resolve to this VM's public address and public TCP port 80 must reach its Apache server. HTTPS needs TCP 443 forwarded too. Certificate failure leaves HTTP available and reports the failure; after fixing DNS or forwarding, retry:

```bash
sudo certbot --apache -d YOUR_DASHBOARD_DOMAIN
```

The package still needs internet access for Debian/Ubuntu dependencies, RadioID/DMR database updates, and optional FTDI D2XX drivers and certificates. The proprietary FTDI binary driver is downloaded when AMBED is selected; it is not redistributed here.

## Source and validation

Upstream snapshots and licenses are preserved. See [bundled source provenance](docs/BUNDLED_SOURCES.md). The original installer remains in `baseline/installer.sh`. Changes are confined to this repository; PP5PK repositories and the running XLX480 are not modified.

Validation includes XLXD compilation, isolated DMR-only and D-Star/DMR listener tests, AMBED source compilation, Echo Test compilation, Bash syntax checks, and CI PHP linting. AMBED hardware operation and a complete fresh-VM installation require testing on the target VM.

See [identity audit](docs/IDENTITY_AUDIT.md) for why the display name remains separate from fixed-width protocol callsigns.
