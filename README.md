# Extended Name Reflector

Experimental XLXD-based multi-mode reflector installer with a protocol-safe identity and a separate human-readable reflector name.

## Identity model

- **Protocol ID:** standard XLXD identity (`XLX` + three alphanumeric characters) used on protocol wire formats.
- **Extended Name:** up to 60 characters for the dashboard and local identification. It does not alter fixed-width protocol packets.

This separation preserves interoperability with XLXD's 8-character callsign fields while allowing names such as `AF0WX Reflector`, `N5XXXX Club Reflector`, or `Old Geezer Reflector`.

## Installer features

The working `installer.sh` adds:

- Extended display/server name independent of protocol ID.
- Public XLX call-home/advertising selectable during installation; default is **off**.
- Enable/disable selection for DExtra, DPlus, DCS, XLX interlink, DMRPlus, DMR MMDVM, YSF, G3 Terminal and IMRS.
- Configurable UDP ports for enabled protocols.
- Configurable AMBE/transcoder UDP port (default 10100).
- Existing YSF frequency and auto-link configuration.
- Existing SSL, dashboard, module and Echo Test options.
- Local metadata at `/etc/extended-name-reflector/reflector.conf`.
- Dashboard local override for the extended name and call-home state.

## Safety

This repository is independent of the production XLX480 reflector and the X80 experimental reflector. It does not modify either project. The imported clean installer is preserved unchanged at `baseline/installer.sh`.

## Source

The installer builds from `EdHasley/xlxd`, whose current `main.h` already contains the protocol enable switches used by this installer.

## Install on a fresh test VM

Use a fresh Debian or Ubuntu VM for the first test. Log in to the VM, open a terminal, and run:

```bash
sudo apt update
sudo apt install -y curl
curl -fsSL https://raw.githubusercontent.com/EdHasley/Extended_Name_Reflector/main/installer.sh -o installer.sh
chmod +x installer.sh
sudo ./installer.sh
```

The installer will ask for the protocol-safe XLX ID, the Extended Name, which protocols to enable, their ports, the AMBE/transcoder port, and whether public call-home advertising should be enabled.

**Test build:** do not run this installer on the existing XLX480 or X80 reflector. Use the new clean VM.

## Status

**Development / test VM only.** Static validation is automated with GitHub Actions (`bash -n` and ShellCheck). A fresh VM should be used for the first runtime installation test.

See `docs/IDENTITY_AUDIT.md` for the protocol-length audit and design rationale.
