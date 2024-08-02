# below is needed to be able to run the app or other fonts that helix uses on your system
# fonts.packages = with pkgs; [
#   jetbrains-mono
# ];

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, crane, rust-overlay, ... }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ (import rust-overlay) ];
      };
      inherit (pkgs) lib;

      craneLib = crane.mkLib pkgs;

      sharedDeps = with pkgs; [
        rust-bin.stable.latest.default
        mold # better linker on linux
        xorg.libxcb
        openssl
        fontconfig
        pkg-config
        libxkbcommon
      ];

      libPath = with pkgs; lib.makeLibraryPath [
        vulkan-loader
        libGL
        libxkbcommon
        wayland
        xorg.libX11
        xorg.libXcursor
        xorg.libXi
        xorg.libXrandr
      ];

      helixGpui = craneLib.buildPackage {
        name = "helix-gpui";
        src = ./.;
        nativeBuildInputs = sharedDeps;
        version = "0.1";
      };

    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

      packages.${system} = {
        default = helixGpui;
      };

      devShells.${system}.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          lld
        ];

        shellHook = ''
        '';

        # Extra inputs can be added here
        buildInputs = with pkgs; [
          cargo-watch
        ] ++ sharedDeps;

        LD_LIBRARY_PATH = libPath;
      };
    };
}
