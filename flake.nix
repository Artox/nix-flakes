{
  description = "Cross-Compilation Development Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      # Define the per-system outputs
      perSystem = flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          pkgsAarch64 = pkgs.pkgsCross.aarch64-multiplatform;
          pkgsArmv7l = pkgs.pkgsCross.armv7l-hf-multiplatform;
          kernelBuildDeps = pkgs.linux_latest.nativeBuildInputs;

          devShell = pkgs.mkShell {
            strictDeps = true;
            nativeBuildInputs =
              kernelBuildDeps
              ++ (with pkgs; [
                pkgsAarch64.stdenv.cc
                pkgsArmv7l.stdenv.cc
                pkgs.stdenv.cc
                bison
                flex
                perl
                bc
                openssl.dev
                rsync
                gmp.dev
                libmpc
                mpfr.dev
                elfutils.dev
                zstd
                kmod
                util-linux
                cpio
                pahole
                zlib
                python3Minimal
                ubootTools
                ncurses.dev
                pkg-config
                gnumake
                dt-schema
                yamllint
              ]);

            shellHook = ''
              ARCH=arm64
              CROSS_COMPILE=aarch64-unknown-linux-gnu-

              if [ $# -ge 1 ]; then
                case "$1" in
                armv7)
                  ARCH=arm
                  CROSS_COMPILE=armv7l-unknown-linux-gnueabihf-
                  shift
                  ;;
                arm64)
                  ARCH=arm64
                  CROSS_COMPILE=aarch64-unknown-linux-gnu-
                  shift
                  ;;
                *)
                  echo "Unknown architecture \"$1\"" >&2
                  exit 1
                  ;;
                esac
              fi

              if [ $# -ge 1 ]; then
                CROSS_COMPILE="$1"
                shift
              fi

              export ARCH CROSS_COMPILE

              echo "╔════════════════════════════════════════════════════╗"
              echo "║ Linux Cross-Compilation Environment                ║"
              echo "╚════════════════════════════════════════════════════╝"
              echo ""
              echo "Target Architecture: $ARCH"
              echo "Cross Compiler: $CROSS_COMPILE"
              echo ""
              echo "To switch targets:"
              echo "  64-bit ARM: export ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu-"
              echo "  32-bit ARM: export ARCH=arm CROSS_COMPILE=armv7l-unknown-linux-gnueabihf-"
              echo ""
            '';
          };

          wrapperScript = pkgs.writeScriptBin "crossdev-shell" ''
            #!/usr/bin/env bash
            export PATH=${pkgs.lib.makeBinPath devShell.nativeBuildInputs}:$PATH
            ${devShell.shellHook}
            exec ${pkgs.bashInteractive}/bin/bash "$@"
          '';

        in
        {
          devShells.default = devShell;
          packages = {
            crossdev-shell = wrapperScript;
            default = wrapperScript;
          };
        }
      );
    in
    perSystem
    // {
      overlays.default = final: prev: {
        crossdev-shell = self.packages.${prev.system}.crossdev-shell;
      };
    };
}
