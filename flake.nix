{
  description = "openssl CLI as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # The `openssl` command-line tool (3.x), statically linked against its own
  # libcrypto/libssl, shipped as a single binary. The packaging delta that makes
  # it self-contained — retarget OPENSSLDIR/ENGINESDIR/MODULESDIR off /nix/store
  # to /etc/ssl (0 store refs; the CLI consults the host's openssl.cnf + trust
  # store like a distro openssl, still overridable via OPENSSL_CONF /
  # SSL_CERT_FILE / SSL_CERT_DIR), re-enable Certificate Transparency, and drop
  # the legacy `c_rehash` shim — is single-sourced in lib.retargetOpenssl and
  # applied by the engine scope's native-overlay, NOT here (see the `let` below
  # and that file for the full rationale).
  #
  # Windows: a single `openssl.exe` cross-built with mingw (openssl is portable
  # C and builds cleanly for mingw-w64). The static cross produces a PE32+ that
  # imports only Windows system DLLs (KERNEL32/msvcrt/WS2_32/ADVAPI32/CRYPT32/
  # USER32) — no companion DLLs — so the portability gate passes. We keep the
  # same deltas as the native build: drop `c_rehash`, re-enable CT, and retarget
  # OPENSSLDIR/ENGINESDIR/MODULESDIR off /nix/store. We use `C:\ssl` (openssl's
  # historical Windows default, and space-free — a path with spaces would be
  # word-split by make's command-line buildFlags), so a user can drop an
  # openssl.cnf under C:\ssl; certificate verification can also use the OS trust
  # store via `-CAstore org.openssl.winstore://`.
  outputs = { self, unpins-lib }:
    let
      lib = unpins-lib.lib;
      # The packaging delta (retarget OPENSSLDIR/ENGINESDIR/MODULESDIR off
      # /nix/store, re-enable CT, drop c_rehash) is single-sourced in
      # lib.retargetOpenssl and applied ONCE per platform by the engine scope's
      # native-overlay/openssl.nix. So the native build below just RECEIVES the
      # already-retargeted openssl, built via the unpin-llvm engine — the very same
      # derivation engine consumers like dnsutils link, so there is one openssl drv
      # and this package adds no recipe of its own. Windows is still mingw cross
      # (not yet on unpin-llvm), and that scope has no such overlay, so until mingw
      # migrates to the engine windowsBuild applies the shared recipe directly.
    in
    lib.mkStandaloneFlake {
      inherit self;
      name = "openssl";
      binName = "openssl";
      smoke = [ "version" ];
      smokePattern = "OpenSSL 3";
      # Engine (no multicall — single binary): useEngine kicks in on linux/darwin,
      # so `build` receives enginePkgs where pkgsStatic.openssl is the overlay's
      # retargeted drv. Windows keeps useEngine=false → plain mingw pkgs.
      engine = "unpin-llvm";
      build = pkgs: pkgs.pkgsStatic.openssl;
      windowsBuild = pkgs:
        (lib.mingwStaticCross pkgs).openssl.overrideAttrs
          (lib.retargetOpenssl "C:/ssl" "C:/ssl/engines-3" "C:/ssl/ossl-modules");
    };
}
