{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    cargo2nix.url = "github:cargo2nix/cargo2nix";
    naersk.url = "github:nix-community/naersk";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { nixpkgs, flake-utils, rust-overlay, cargo2nix, naersk, ... }:
    flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"] (system:
      let

        overlays = [
          (import rust-overlay)
          (import "${cargo2nix}/overlay")
        ];

        pkgs = import nixpkgs {
          inherit system overlays;
        };

        rustVersion = "1.54.0";

        wasmTarget = "wasm32-unknown-unknown";

      in

      rec {
        devShell = pkgs.mkShell {
          buildInputs = [
            (pkgs.rust-bin.stable.${rustVersion}.default.override {
              targets = [ wasmTarget ];
            })
            cargo2nix.defaultPackage.${system}
          ];
        };

        packages.rust-wasm_cargo2nix =
          let

            # create nixpkgs that contains rustBuilder from cargo2nix overlay
            crossPkgs = import nixpkgs {
              inherit system;

              crossSystem = {
                config = "wasm32-unknown-wasi";
                system = "wasm32-wasi";
                useLLVM = true;
              };

              overlays = [
                (import "${cargo2nix}/overlay")
                rust-overlay.overlay
              ];
            };

            # create the workspace & dependencies package set
            rustPkgs = crossPkgs.rustBuilder.makePackageSet' {
              rustChannel = rustVersion;
              packageFun = import ./Cargo.nix;
              target = "wasm32-unknown-unknown";
            };

          in

          rustPkgs.workspace.nix-build-rust-wasm-example {};

        packages.rust-wasm_naersk =
          let

            rust = pkgs.rust-bin.stable.${rustVersion}.default.override {
              targets = [ wasmTarget ];
            };

            naersk' = pkgs.callPackage naersk {
              cargo = rust;
              rustc = rust;
            };

            wasm = naersk'.buildPackage {
              src = ./.;
              copyLibs = true;
              CARGO_BUILD_TARGET = wasmTarget;
              cargoBuildOptions = (opts: opts ++ ["--package=nix-build-rust-wasm-example"]);
            };

          in

          wasm;

        packages.toplevel =
          let

            js-main = pkgs.writeTextFile {
              name = "main.js";
              text = ''
                import init, { run_app } from './app.js';
                async function main() {
                   await init('nix_build_rust_wasm_example.wasm');
                   run_app();
                }
                main()
              '';
            };

          in

          pkgs.stdenv.mkDerivation {
            name = "nix-build-rust-wasm-example";
            buildInputs = [ pkgs.nodePackages.rollup ];
            unpackPhase = "true";
            installPhase = ''
              mkdir $out
              cp ${./index.html} $out/index.html
              cp ${./app.js} $out/app.js
              cp ${packages.rust-wasm_naersk}/lib/nix_build_rust_wasm_example.wasm $out
              cp ${js-main} $out/main.js
              rollup $out/main.js --format iife --file $out/bundle.js
            '';
          };
      });
}
