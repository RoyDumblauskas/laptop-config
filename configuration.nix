{ config, lib, pkgs, ... }:

{
  imports = [ ];

  # Use the systemd-boot EFI boot loader.
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  # Grub Boot Loader Setup
  boot.loader.grub = {
    enable = true;
    zfsSupport = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    mirroredBoots = [
      { 
        devices = [ "nodev" ];
        path = "/boot";
      }
    ];
  };

  fileSystems."/persist".neededForBoot = true;

  environment.persistence."/persist" = {
    directories = [
      "/etc/nixos"
      "/var/log"
      "/var/db/sudo/lectured"
      "/var/lib/nixos"
      "/var/lib/bluetooth"
    ];
  };

  # SOPS config
  sops = {
    age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
    # deleted and generated every boot
    age.keyFile = "/var/lib/sops-nix/key.txt";
    age.generateKey = true;
    defaultSopsFormat = "json";

    # test secrets
    secrets = {
      "networkPasswords" = {
        sopsFile = ./secrets/networking.yaml;
        key = "networkPasswords";
        format = "yaml";
      };
    };
  };

  networking.hostName = "roy-laptop";
  networking.hostId = "4cb9fc76";

  networking = {
    useDHCP = true;
    networkmanager.enable = false;
    wireless = {
      userControlled.enable = true;
      enable = true;
      secretsFile = config.sops.secrets."networkPasswords".path;
      networks = {
        "NU-Guest" = {
          priority = -1;
        };
        "mojo dojo casa house" = {
          pskRaw = "ext:homeNetwork";
        };
      };
    };

  };

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    browsed.enable = true;
    browsing = true;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Graphical bluetooth
  services.blueman.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define users
  users.mutableUsers = false;
  users.users.roy = {
    isNormalUser = true;
    hashedPassword = "$y$j9T$4yOAv6R7Xtn23XmhSSC8g.$T1CckfWgxjEyZshjBzcaMO9WidP.q..OG7LwtXFTw12";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.fish;
  };

  # Delete root on reboot
  boot.initrd.postMountCommands = lib.mkAfter ''
    zfs rollback -r zroot/root@blank
  '';

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Declare system wide pkgs
  environment.systemPackages = with pkgs; [
    gimp
    alacritty
    rose-pine-hyprcursor
    vim
    wget
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.mononoki
    nerd-fonts.ubuntu-mono
  ];

  # List services that to enable:
  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    waybar.enable = true;
    fish.enable = true;

    # needed to allowOther in home.nix
    fuse.userAllowOther = true;

    steam = {
      enable = true;
      remotePlay.openFirewall = true;       
      dedicatedServer.openFirewall = true;      
      localNetworkGameTransfers.openFirewall = true;
    };
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Shows battery charge of connected devices on supported
        # Bluetooth adapters. Defaults to 'false'.
        Experimental = true;
      };
      Policy = {
        # Enable all controllers when they are found. This includes
        # adapters present on start as well as adapters that are plugged
        # in later on.
        AutoEnable = true;
      };
    };
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.variables = {
    EDITOR = "nvim";
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    hostKeys = [
      {
        type = "ed25519";
        path = "/persist/etc/ssh/ssh_host_ed25519_key";
      }
    ];
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # INITIAL system version
  # CURRENT nixpkgs version = 25.05
  system.stateVersion = "24.11";

}

