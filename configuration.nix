{
  config,
  lib,
  pkgs,
  meta,
  ...
}:

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
    configurationLimit = 25;
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

    secrets = {
      "networkPasswords" = {
        sopsFile = ./secrets/networking.yaml;
        key = "networkPasswords";
        format = "yaml";

        # let the service that needs the secrets own them
        owner = "wpa_supplicant";
        group = "wpa_supplicant";
      };
    };
  };

  networking.hostName = meta.hostname;
  networking.hostId = meta.hostId;

  networking = {
    useDHCP = true;
    networkmanager.enable = false;
    wireless = {
      userControlled = true;
      enable = true;
      secretsFile = config.sops.secrets."networkPasswords".path;
      networks = {
        "NU-Guest" = {
          priority = -1;
        };
        "Intelligentsia Public" = {
          priority = -1;
        };
        "mojo dojo casa house" = {
          pskRaw = "ext:homeNetwork";
        };
        "Galaxy S6 2279" = {
          pskRaw = "ext:mobileHotspot";
        };
        "d fam google" = {
          pskRaw = "ext:home";
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

  # Enable sound.
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define users
  users.mutableUsers = false;
  users.users.roy = {
    isNormalUser = true;
    hashedPassword = meta.hashedPass;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.fish;
  };

  boot.zfs.forceImportRoot = false;

  # Delete root on reboot disable for now while broken
  boot.initrd.systemd.services = {
    rollback = {
      description = "Rollback root zfs dataset to blank snapshot";
      wantedBy = [ "initrd.target" ];
      before = [ "sysroot.mount" ];
      after = [ "zfs-import-zroot.service" ];
      path = [ pkgs.zfs ];

      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";

      script = ''
        zfs rollback -r zroot/root@blank
        echo "blank rollback complete" > /dev/kmsg
      '';
    };
  };

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    gc = {
      automatic = true;
      persistent = true;
      dates = [ "daily" ];
      options = "--delete-older-than 30d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  # Declare system wide pkgs
  environment.systemPackages = with pkgs; [
    alacritty
    gimp
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
  networking.firewall.enable = true;

  # INITIAL system version
  system.stateVersion = "24.11";

}
