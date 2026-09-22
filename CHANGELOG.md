# Changelog

## [Unreleased]

### Changed

- Updated to OpenSSL 3.6.3.
- The Windows binary is now built by the same compiler as the Linux and macOS
  ones. It is about 8% smaller (21.7 MB to 19.9 MB); `version`, a SHA-256
  digest, an Ed25519 key and an AES round trip were checked under Wine.

  It now uses the Universal C Runtime, which is part of Windows 10 and later.
  On Windows 7 or 8.1 that runtime has to be installed first — it comes through
  Windows Update. The previous binary did not need it.

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
