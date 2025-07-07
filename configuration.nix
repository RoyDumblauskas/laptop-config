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
      "testKey" = {
        sopsFile = ./secrets/roy.json;
        key = "testKey";
      };
      "networkPasswords" = {
        sopsFile = ./secrets/networking.yaml;
        key = "networkPasswords";
        format = "yaml";
      };
    };
  };

  # needed to allowOther in home.nix
  programs.fuse.userAllowOther = true;

  networking.hostName = "roy-laptop";
  networking.hostId = "4cb9fc76";

  networking.wireless = {
    enable = true;
    secretsFile = config.sops.secrets."networkPasswords".path;
    networks = {
      "flooper" = {
        pskRaw = "ext:flooperPsk";
      };
      "NU-Guest" = {
        priority = -1;
      };
      "d fam google" = {
        pskRaw = "ext:ancestralGrounds";
      };
      "mojo dojo casa house" = {
        pskRaw = "ext:homeNetwork";
      };
      "TwoHeartedQueen Guest" = {
        pskRaw = "ext:2QCafe";
      };
      "Close Personal Friends of Osmium" = {
        pskRaw = "ext:osmium";
      };
    };
  };

  networking.wireless.userControlled.enable = true; # Enable user to edit wpa_supplicant.
  networking.networkmanager.enable = false;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

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
    extraGroups = [ "wheel" ];
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
  ];

  # List services that to enable:
  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    waybar.enable = true;
    fish.enable = true;
  };


  programs.firefox = {
    enable = true;
    policies = {
      ExtensionSettings = {
        "*".installation_mode = "blocked";
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
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

