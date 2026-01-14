# Cross-Development Devshell as a Package

This pet project provides a nix devshell with cross toolchains installable as a system-wide package on NixOS.

## Usage

`flake.nix`:
```nix
{
  inputs = {
    ...
    crossdev = {
      url = "github:Artox/nix-flakes/crossdev";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

`configuration.nix`:
```nix
{
  # either as a package
  environment.systemPackages = with pkgs; [
    ...
    inputs.crossdev.packages.${pkgs.system}.crossdev-shell
  ];

  # or as an overlay
  nixpkgs = {
    overlays = [
      ...
      inputs.crossdev.overlays.default
    ];
  };
}
```

