{
  description = "openssl CLI as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # The `openssl` command-line tool (3.x), statically linked against its own
  # libcrypto/libssl. We ship ONLY the `openssl` binary — nixpkgs' bin output
  # also installs `c_rehash`, a Perl script with a /nix/store bash-perl shebang
  # that can't run on a user's machine, so it's dropped.
  #
  # OPENSSLDIR retarget (the main packaging delta): nixpkgs compiles the
  # binary with OPENSSLDIR/ENGINESDIR/MODULESDIR pointing at /nix/store output
  # paths (the split `etc` output + `$out/lib`). A self-contained binary must
  # not embed store paths it carries as a runtime closure, so we override those
  # three macros to the conventional system locations (/etc/ssl, …) at BUILD
  # time only — via `buildFlags`, which the build phase honours but the install
  # phase does not, so nixpkgs' `etc`-output install still works. The upshot is
  # both cleaner (0 store refs) and more correct: the CLI now consults the
  # host's /etc/ssl/openssl.cnf and system trust store, exactly like a distro
  # `openssl`. Users can still override with OPENSSL_CONF / SSL_CERT_FILE /
  # SSL_CERT_DIR.
  #
  # Certificate Transparency re-enabled: nixpkgs forces `no-ct` on every static
  # build only because CT bakes a CTLOG_FILE store path into the binary. The
  # OPENSSLDIR retarget above already moves that to /etc/ssl/ct_log_list.cnf, so
  # the reason is gone and we keep CT (the `s_client -ct` SCT path) — see the
  # `retarget` helper.
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
      # Shared packaging deltas, parameterised by the OPENSSLDIR family so the
      # native (/etc/ssl) and Windows (C:/ssl) builds differ in one place only.
      retarget = sslDir: enginesDir: modulesDir: old: {
        # nixpkgs adds `no-ct` for every static build — Certificate Transparency
        # bakes a default CTLOG_FILE path into libcrypto, and on a stock static
        # build that path lands in /nix/store (undesired in a self-contained
        # binary). We already retarget OPENSSLDIR off /nix/store, so CTLOG_FILE
        # follows to ${sslDir}/ct_log_list.cnf — a system path, not a store ref.
        # That removes nixpkgs' sole reason for the flag, so we drop it and ship
        # CT (the `s_client -ct` SCT validation) like a distribution openssl.
        configureFlags = builtins.filter (f: f != "no-ct") (old.configureFlags or [ ]);
        buildFlags = (old.buildFlags or [ ]) ++ [
          "OPENSSLDIR=${sslDir}"
          "ENGINESDIR=${enginesDir}"
          "MODULESDIR=${modulesDir}"
        ];
        postInstall = (old.postInstall or "") + ''
          rm -f "''${bin:-$out}/bin/c_rehash"
        '';
      };
    in
    lib.mkStandaloneFlake {
      inherit self;
      name = "openssl";
      binName = "openssl";
      smoke = [ "version" ];
      smokePattern = "OpenSSL 3";
      build = pkgs:
        pkgs.pkgsStatic.openssl.overrideAttrs
          (retarget "/etc/ssl" "/etc/ssl/engines-3" "/etc/ssl/ossl-modules");
      windowsBuild = pkgs:
        (lib.mingwStaticCross pkgs).openssl.overrideAttrs
          (retarget "C:/ssl" "C:/ssl/engines-3" "C:/ssl/ossl-modules");
    };
}
