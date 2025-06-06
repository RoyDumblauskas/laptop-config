{
  description = "System Wide Config Controller";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixvim.url = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";	
    };    
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    sops-nix = {
	url = "github:Mic92/sops-nix";
	inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixvim, home-manager, impermanence, sops-nix }@inputs: {

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
	impermanence.nixosModules.impermanence
	sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.roy = { ... }: {
            imports = [
              ./home.nix
              nixvim.homeManagerModules.nixvim
	      impermanence.homeManagerModules.impermanence

            ];
          };
        }
      ];
    };
  };
}
