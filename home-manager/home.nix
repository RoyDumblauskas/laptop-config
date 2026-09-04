{ pkgs, ... }:

{

  # import longer service declarations
  imports = [
    ./programs
  ];

  home.username = "roy";
  home.homeDirectory = "/home/roy";

  home.packages = with pkgs; [
    age
    brightnessctl
    dig
    discord
    ffmpeg_6
    fish
    git
    grim
    jq
    nodejs_22
    postman
    prismlauncher
    python3
    slurp
    sops
    spotify
    ssh-to-age
    tree
    tmux
    unzip
    wl-clipboard
    woeusb
    wofi
    xrandr
    zip
  ];

  # user program config files
  home.file = {
    ".config/hypr".source = ../roy-config/hypr;
    ".config/waybar".source = ../roy-config/waybar;
    ".config/wofi".source = ../roy-config/wofi;
  };

  # user persisted dirs
  home.persistence."/persist" = {
    directories = [
      ".ssh"
      "rp"
      "dl"
      # persist steam (long download times)
      ".local/share/Steam"
      # persist spotify login
      ".config/spotify"
      # Minecraft (long download times)
      ".local/share/PrismLauncher/instances"
      ".local/share/PrismLauncher/assets"
    ];
    files = [
      ".bash_history"
      ".config/sops/age/keys.txt"
      # Persist mc login
      ".local/share/PrismLauncher/accounts.json"
    ];
  };

  # User services must come after sops secrets
  systemd.user.services.mbsync.unitConfig.After = [ "sops-nix.service" ];

  home.stateVersion = "24.11";
  programs.home-manager.enable = true;

}
