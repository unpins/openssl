# openssl

[OpenSSL](https://www.openssl.org/) — the command-line tool for TLS/SSL and general-purpose cryptography: keys, certificates, digests, encryption, and `s_client`. A single self-contained binary, built natively for Linux, macOS, and Windows.

[![CI](https://github.com/unpins/openssl/actions/workflows/openssl.yml/badge.svg)](https://github.com/unpins/openssl/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) catalog; install it with [`unpin`](https://github.com/unpins/unpin): `unpin install openssl`.

## Usage

Run the `openssl` program with [unpin](https://github.com/unpins/unpin):

```bash
unpin openssl version
unpin openssl dgst -sha256 file.txt
unpin openssl s_client -connect example.com:443
```

To install it onto your PATH:

```bash
unpin install openssl
```

## Man pages

OpenSSL's man pages — the `openssl` overview plus the full command and
`libcrypto`/`libssl` API reference — are embedded in the binary. Read them with
`unpin man openssl [<page>]`:

```bash
unpin man openssl                  # the openssl(1) overview
unpin man openssl openssl-s_client
```

## Build locally

```bash
nix build github:unpins/openssl
./result/bin/openssl version
```

Or run directly:

```bash
nix run github:unpins/openssl -- version
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/openssl/releases) page has standalone binaries for manual download.

## Build notes

- **Windows** is an `openssl.exe` cross-compiled with mingw-w64 (OpenSSL is
  portable C and builds cleanly for it); it imports only Windows system DLLs
  (`KERNEL32`, `WS2_32`, `CRYPT32`, …) and ships no companion DLLs.
- **Only the `openssl` binary ships.** nixpkgs also installs `c_rehash`, a Perl
  script with a `/nix/store` shebang that can't run standalone — it's dropped;
  `openssl rehash` does the same job.
- **`OPENSSLDIR`:** nixpkgs compiles the binary with
  OPENSSLDIR/ENGINESDIR/MODULESDIR pointing at `/nix/store` paths. A
  self-contained binary must not carry a store closure, so those macros are
  retargeted to the conventional system locations at build time — `/etc/ssl` on
  Linux/macOS, `C:\ssl` on Windows. The result is both cleaner (zero store
  references) and more correct: the CLI consults the host's `openssl.cnf` and
  system trust store, exactly like a distribution `openssl`. On Windows you can
  also verify against the OS certificate store with
  `-CAstore org.openssl.winstore://`. Override with `OPENSSL_CONF` /
  `SSL_CERT_FILE` / `SSL_CERT_DIR` as usual.
- **No upstream features are disabled.** Certificate Transparency
  (`s_client -ct`) stays on — nixpkgs turns it off on static builds only because
  it bakes a `/nix/store` CTLOG_FILE path in, but the OPENSSLDIR retarget above
  already moves that to `/etc/ssl/ct_log_list.cnf`, so we keep it. The only
  flags forced off are inherent to static linking and lose no functionality:
  `no-shared` (we ship one static binary) and `no-module` (engines/providers
  can't be `dlopen`ed from a static musl binary, so they're compiled in instead
  — e.g. the legacy algorithms are still reachable with `-provider legacy`).
