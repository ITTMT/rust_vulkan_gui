{
  description = "Rust Vulkan dev shell with Wayland support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        # Needed to replicate LD_LIBRARY_PATH behavior
        buildInputs = with pkgs; [
          libxkbcommon
          wayland xorg.libX11 xorg.libXcursor xorg.libXrandr xorg.libXi
          alsa-lib
          fontconfig freetype
          shaderc directx-shader-compiler
          pkg-config cmake
          mold

          libGL
          vulkan-headers vulkan-loader
          vulkan-tools vulkan-tools-lunarg
          vulkan-extension-layer
          vulkan-validation-layers

          cargo-nextest cargo-fuzz
          typos
          yq
          rustup

          gdb rr
          evcxr
          valgrind
          renderdoc
        ];

        libPath = pkgs.lib.makeLibraryPath buildInputs;

      in {
        devShells.default = pkgs.mkShell {
          inherit buildInputs;

          shellHook = ''
            # Read rust version from rust-toolchain.toml
            if [ -f rust-toolchain.toml ]; then
              export RUSTC_VERSION="$(tomlq -r .toolchain.channel rust-toolchain.toml)"
              echo "Using rustc version: $RUSTC_VERSION"
              rustup default "$RUSTC_VERSION"
              rustup component add rust-src rust-analyzer
            else
              echo "⚠️ rust-toolchain.toml not found; skipping rustup config."
            fi

            export PATH="$PATH:''${CARGO_HOME:-$HOME/.cargo}/bin"
            export PATH="$PATH:''${RUSTUP_HOME:-$HOME/.rustup}/toolchains/''${RUSTC_VERSION}-x86_64-unknown-linux-gnu/bin"
            export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${libPath}"
          '';

          # Optional: Set other helpful env vars
          RUST_LOG = "debug";
        };
      });
}
