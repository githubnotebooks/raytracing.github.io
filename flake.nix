{
  description = "A basic Nix flake providing development shells";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-stable.follows = "nixpkgs";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-v2505.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-v2411.url = "github:NixOS/nixpkgs/nixos-24.11";
    nur = {
      url = "github:nix-community/NUR";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      nixpkgs-unstable,
      nixpkgs-v2505,
      nixpkgs-v2411,
      nur,
      ...
    }@inputs:
    let
      pkg-settings = rec {
        allowed-unfree-packages =
          pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "cudnn"
            "libcublas"
          ];
        allowed-insecure-packages = [
          "electron-11.5.0"
          "openssl-1.1.1w"
        ];
      };

      eachSystem = nixpkgs.lib.genAttrs [ "x86_64-linux" ] (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfreePredicate = pkg-settings.allowed-unfree-packages;
            config.permittedInsecurePackages = pkg-settings.allowed-insecure-packages;
            overlays = [
              nur.overlays.default
              (final: prev: {
                unstable = import nixpkgs-unstable {
                  inherit system;
                  config.allowUnfreePredicate = pkg-settings.allowed-unfree-packages;
                  config.permittedInsecurePackages = pkg-settings.allowed-insecure-packages;
                  overlays = [ nur.overlays.default ];
                };
              })
              (final: prev: {
                v2505 = import nixpkgs-v2505 {
                  inherit system;
                  config.allowUnfreePredicate = pkg-settings.allowed-unfree-packages;
                  config.permittedInsecurePackages = pkg-settings.allowed-insecure-packages;
                  overlays = [ nur.overlays.default ];
                };
              })
              (final: prev: {
                v2411 = import nixpkgs-v2411 {
                  inherit system;
                  config.allowUnfreePredicate = pkg-settings.allowed-unfree-packages;
                  config.permittedInsecurePackages = pkg-settings.allowed-insecure-packages;
                  overlays = [ nur.overlays.default ];
                };
              })
            ];
          };
        in
        {
          default = pkgs.mkShellNoCC {
            name = "proj";
            hardeningDisable = [ "fortify" ];
            packages = with pkgs; [
              pkg-config
              gcc15
              gnumake
              ninja
              cmake
              xmake
              glfw3
              libGL
              assimp
              freetype
              stb
              xorg.libX11
              xorg.libXrandr
              xorg.libXinerama
              xorg.libXi
              xorg.libXxf86vm
              xorg.libXcursor
              xorg.xorgproto
            ];
            shellHook = "";
          };
        }
      );

    in
    {
      devShells = eachSystem;
    };
}
