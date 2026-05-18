{
  description = "System Wide Config Controller";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixvim,
      home-manager,
      disko,
      impermanence,
      sops-nix,
      firefox-addons,
    }@inputs:
    # Place all config differences between laptop/desktop here
    # If they grow sufficiently different, maybe split them out completely
    let
      platforms = [
        {
          name = "roy-laptop";
          hostId = "4cb9fc76";
          hashedPass = "$y$j9T$4yOAv6R7Xtn23XmhSSC8g.$T1CckfWgxjEyZshjBzcaMO9WidP.q..OG7LwtXFTw12";
        }
        {
          name = "roy-desktop";
          hostId = "67cf9bc4";
          hashedPass = "$y$j9T$6u38YtgJqXZ6Yq11mIZq//$SyZo1UEj5csiElp3a2zoDbdFGCdYktel09lfIkgKKd0";
        }
      ];
    in
    {
      nixosConfigurations = builtins.listToAttrs (
        map (platform: {
          name = platform.name;
          value = nixpkgs.lib.nixosSystem {
            specialArgs.meta = {
              hostname = platform.name;
              hostId = platform.hostId;
              hashedPass = platform.hashedPass;
            };
            system = "x86_64-linux";
            modules = [
              ./configuration.nix
              ./hardware-configuration.nix
              ./disk-config.nix
              disko.nixosModules.disko
              impermanence.nixosModules.impermanence
              sops-nix.nixosModules.sops
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.extraSpecialArgs = { inherit inputs; };
                home-manager.users.roy =
                  { ... }:
                  {
                    imports = [
                      ./home.nix
                      nixvim.homeModules.nixvim
                      sops-nix.homeManagerModules.sops
                    ];
                  };
              }
            ];
          };
        }) platforms
      );
    };
}
