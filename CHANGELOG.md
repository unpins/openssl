# Changelog

## [Unreleased]

### Fixed

- Certificate verification with no `-CAfile`/`-CApath` (`s_client`, `verify`)
  found no trusted certificates on Fedora, RHEL, openSUSE, macOS and Windows:
  the binary only looked where Debian and Ubuntu keep them. It now uses the
  host's CA certificates wherever the common systems keep them — Debian/Ubuntu,
  Fedora/RHEL, openSUSE, Alpine, Arch, NixOS, Android/Termux and macOS's
  `/etc/ssl/cert.pem`.

### Added

- Mozilla's root certificates are built into the binary and used when the host
  has none, such as a minimal container. On Windows they are combined with the
  system's trusted root store, leaving out certificates Windows marks as
  untrusted, and nothing under `C:\ssl` is trusted. `SSL_CERT_FILE` and
  `SSL_CERT_DIR` still take precedence; otherwise `UNPIN_CA_FALLBACK=off` never
  uses the built-in roots and `UNPIN_CA_FALLBACK=force` uses only them.
