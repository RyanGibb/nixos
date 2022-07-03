{ pkgs, ... }:

{
  imports = [
    ../../hardware-configuration.nix
    ./shell.nix
  ];

  boot.loader.grub = {
    enable = true;
    version = 2;
  };

  time.timeZone = "Europe/London";

  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "uk";
  }; 

  users.mutableUsers = false;
  users.users.ryan = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # enable sudo
    shell = pkgs.zsh;
    openssh.authorizedKeys.keyFiles = [
      ./authorized_keys
    ];
  };

  environment.systemPackages = with pkgs; [
    nix
    tree
    htop
    bind
    inetutils
    ncdu
    nix-prefetch-git
    gnumake
    bat
    killall
    nmap
    gcc
    direnv
    fzf
  ];

  environment = {
    variables.EDITOR = "nvim";
    shellAliases = {
      ls = "ls -p --color=auto";
      pls = "sudo $(fc -ln -1)";
      o = "xdg-open";
      se = "sudoedit";
      su = "su -p";
      ssh = "TERM=xterm ssh";
      nix-shell = "nix-shell --command zsh";
      inhibit-lid = "systemd-inhibit --what=handle-lid-switch sleep 1d";
    };
  };

  programs.mosh.enable = true;
  services.openssh = {
    enable = true;
    permitRootLogin = "no";
    passwordAuthentication = false;
  };
  services.tailscale.enable = true;

  networking = rec {
    nameservers = [ "1.1.1.1" ];
    networkmanager.dns = "none";
    extraHosts = ''
      100.122.46.94  pixel-4a
      100.92.111.117 dell-xps
      100.91.12.120  hp-pavilion
      100.125.253.71 vps
      100.93.8.35    desktop
      100.110.247.52 rasp-pi
    '';
  };

  # Strict reverse path filtering breaks Tailscale exit node use and some subnet routing setups.
  networking.firewall.checkReversePath = "loose";

  programs = {
    ssh.extraConfig = ''
      Host pixel-4a*
      	User u0_a342
      	Port 8022
      
      Host slogin
      	User rtg24
      	Hostname slogin-serv.cl.cam.ac.uk
      
      Host l41
      	User root
      	Hostname rpi4-013.advopsys.cl.cam.ac.uk
      	IdentityFile ~/.ssh/id_rsa_rpi4-013.advopsys.cl.cam.ac.uk
      	ProxyJump rtg24@slogin-serv.cl.cam.ac.uk
      	ForwardAgent yes
    '';
    git = {
      enable = true;
      config = {
        user = {
          email = "ryan@gibbr.org";
          name = "Ryan Gibb";
        };
        alias = {
          s = "status";
          c = "commit";
          cm = "commit --message";
          ca = "commit --amend";
          cu = "commit --message update";
          ci = "commit --message initial";
          br = "branch";
          co = "checkout";
          df = "diff";
          lg = "log -p";
          lol = "log --graph --decorate --pretty=oneline --abbrev-commit";
          lola = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
          ls = "ls-files";
          a = "add";
          aa = "add --all";
          au = "add -u";
          ap = "add --patch";
          ps = "push";
          pf = "push --force";
          pu = "push --set-upstream";
          pl = "pull";
          pr = "pull --rebase";
          acp = "!git add --all && git commit --message update && git push";
        };
      };
    };
    bash.promptInit = ''
      PS1='\[\e[36m\]\u@\h:\W\[\e[0m\] $ '
    '';
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      configure = {
        customRC = builtins.readFile ./nvim.cfg;
        packages.myVimPackage = with pkgs.vimPlugins; {
          start = [
            vimtex
            vim-auto-save
            vim-airline
            vim-airline-themes
            palenight-vim
            vim-nix
          ];
          opt = [ ];
        };
      };
    };
    tmux = {
      enable = true;
      extraConfig = ''
        set -g mouse on
        set-window-option -g mode-keys vi
      '';
    };
  };

  system.copySystemConfiguration = true;

  system.stateVersion = "22.05";
}
