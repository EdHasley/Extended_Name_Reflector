# Extended Name Reflector

Experimental multi-mode reflector project based on XLXD concepts, maintained separately from XLX480 and X80.

## Project goals

- Keep protocol-facing IDs compatible where a protocol requires a fixed format.
- Add a separate configurable extended reflector/display name.
- Allow a callsign or descriptive name for the reflector UI.
- Make call-home/advertising optional.
- Allow supported protocols/modes to be enabled or disabled during installation.
- Allow per-protocol network ports to be configured during installation.
- Make the AMBE/transcoder port configurable.
- Preserve a clean separation from the production XLX480 and experimental X80 projects.

## Identity design

The project will distinguish between:

1. **Protocol ID** — the identifier transmitted where an existing protocol requires a particular size or format.
2. **Extended Name** — a longer human-readable reflector/server name used where protocol constraints do not apply.

This separation lets the software support names such as callsigns or descriptive reflector names without blindly changing fixed-length protocol fields.

## Development rule

Do not modify XLX480 or X80 as part of this project. Changes for Extended Name Reflector belong in this repository only.

## Status

Repository initialized. Next step: import and audit a clean XLXD/installer baseline before changing identifier lengths.
