inputs:
{ config, pkgs, lib, nixosConfig, ... }:
let
  hasBattery = nixosConfig.networking.hostName == "laptop";

  myPython = pkgs.python3.withPackages
    (ps: with ps; [ numpy scipy matplotlib jupyter black flake8 isort ]);
  sauceFont = pkgs.nerdfonts.override { fonts = [ "SourceCodePro" ]; };
  gpsm = with pkgs;
    writeShellScriptBin "gpsm" ''
      ${findutils}/bin/find ~/.password-store/ -name '.git*' -prune -o -type d -print \
      | ${gnused}/bin/sed "s|^$HOME/\.password-store/\(.*\)$|\1|" \
      | ${gnugrep}/bin/grep -v '^$' \
      | ${dmenu}/bin/dmenu \
      | ${findutils}/bin/xargs ${pass}/bin/pass generate -c $@
    '';
  psm = with pkgs;
    writeShellScriptBin "psm" ''
      ${findutils}/bin/find ~/.password-store/ -name '*.gpg' \
      | ${gnused}/bin/sed "s|^$HOME/\.password-store/\(.*\)\.gpg$|\1|" \
      | ${dmenu}/bin/dmenu \
      | ${findutils}/bin/xargs ${pass}/bin/pass show -c"${"\${1-1}"}"
    '';
  wallpaper = builtins.fetchurl {
    url = "https://i.redd.it/u5wugt3u42761.png";
    sha256 = "12g7q1lkkawmswh3xa6lq1cjyxcdck2yvq2xipcrh1lq2s8g0xsp";
  };
  ledger-live = let
    src = builtins.fetchurl {
      name = "ledger-live-desktop.AppImage";
      url = "https://download-live.ledger.com/releases/latest/download/linux";
      sha256 = "10gi29mcvs4d5flqycwid190pnlciznzbvg36250mxaxxs58rq7j";
    };
  in
    with pkgs;
    writeScriptBin "ledger-live" "${appimage-run}/bin/appimage-run ${src}";
  windows-vm = with pkgs;
    writeScriptBin "windows-vm" ''
      exec ${qemu_kvm}/bin/qemu-kvm \
        -cpu host \
        -drive file=/mnt/data/qemu/images/win10.qcow2 \
        -net nic \
        -net user,hostfwd=tcp::2223-:22 \
        -m 8G \
        -monitor stdio \
        -name "Windows" \
        $@
    '';
  mo2-handler = with pkgs;
    writeScriptBin "modorganizer2-nxm-broker.sh" (
      builtins.readFile
        "${inputs.lutris-skyrimse-installers}/handlers/modorganizer2-nxm-broker.sh"
    );
  mo2-handler-desktop-item = pkgs.makeDesktopItem {
    name = "modorganizer2-nxm-handler";
    desktopName = "Mod Organizer 2 NXM Handler";
    type = "Application";
    categories = "Game;";
    exec = "${mo2-handler}/bin/modorganizer2-nxm-broker.sh %u";
    mimeType = "x-scheme-handler/nxm";
    extraEntries = ''
      NoDisplay=true
    '';
  };
  toggle-tmux-pane = with pkgs; writeScript "toggle-tmux-pane" ''
    name="$1"
    shift
    P="$(tmux show -wv "@$name")"
    if [ -z "$P" ]; then
      ${tmux}/bin/tmux set -w "@$name" "$(${tmux}/bin/tmux splitw -PF '#{pane_id}' $@)"
    else
      ${tmux}/bin/tmux killp -t "$P"
      ${tmux}/bin/tmux set -wu "@$name"
    fi
  '';
  sidebar = with pkgs; writeScript "sidebar" ''
    export NVIM_LISTEN_ADDRESS="${"$"}{XDG_RUNTIME_DIR-/tmp}/tmux-nvim-${"$"}{TMUX##*,}"
    export NNN_OPENER="${tnvr}"
    exec ${nnnNerd}/bin/nnn -c $@
  '';
  nnnNerd = pkgs.nnn.override { withNerdIcons = true; };
  tnvr = with pkgs; writeScript "tnvr" ''
    if [ -n "$TMUX" ]; then
      pane_id="$(${neovim-remote}/bin/nvr --nostart -s --remote-expr 'get(environ(), "TMUX_PANE")')"
      if [ -n "$pane_id" ]; then
        tmux select-pane -t "$pane_id"
      fi
    fi
    exec ${neovim-remote}/bin/nvr $@
  '';
in
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "gcoakes";
  home.homeDirectory = "/home/gcoakes";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.05";

  home.packages = with pkgs;
    [
      cachix
      ccid
      cookiecutter
      deno
      discord
      dmenu
      element-desktop
      ffmpeg
      gimp
      google-chrome
      gpsm
      home-manager
      inkscape
      ipfs
      libreoffice
      lutris
      mo2-handler
      mo2-handler-desktop-item
      myPython
      neovim-remote
      niv
      opensc
      pass
      pavucontrol
      protontricks
      psm
      sauceFont
      spotify
      steam
      teams
      brave
      unzip
      virt-manager
      wineWowPackages.full
      xclip
      yarn
      zip
      zstd
    ] ++ (if hasBattery then [] else [ windows-vm ]);

  home.sessionVariables = { EDITOR = "nvim"; };

  programs = {
    zsh = {
      enable = true;
      oh-my-zsh = {
        enable = true;
        theme = "fino-time";
        plugins = [ "colored-man-pages" ];
      };
      initExtra = ''
        if [ -n "$TMUX" ]; then
          export NVIM_LISTEN_ADDRESS="${"$"}{XDG_RUNTIME_DIR-/tmp}/tmux-nvim-${"$"}{TMUX##*,}"
          export EDITOR="${tnvr} -s"
        fi
        function editor() {
          tmuxp load default
        }
      '';
    };
    git = {
      enable = true;
      userEmail = "gregcoakes@gmail.com";
      userName = "Gregory C. Oakes";
      signing = { key = "gregcoakes@gmail.com"; };
      ignores = [ ".vscode/" ".mypy_cache/" ".direnv/" ];
      delta.enable = true;
      extraConfig.core.editor = "${tnvr} --remote-wait-silent -s";
    };
    gpg.enable = true;
    direnv = {
      enable = true;
      enableZshIntegration = true;
      enableNixDirenvIntegration = true;
    };
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      withPython3 = true;
      withNodeJs = true;
      extraConfig = builtins.readFile ./init.vim;
      plugins = with pkgs.vimPlugins; [
        coc-css
        coc-eslint
        coc-fzf
        coc-git
        coc-html
        coc-json
        coc-nvim
        coc-pairs
        coc-rust-analyzer
        coc-spell-checker
        coc-tsserver
        coc-vimlsp
        coc-yaml
        dracula-vim
        fugitive
        fzf-vim
        lightline-vim
        vim-nix
        vim-rooter
        vista-vim
      ];
      extraPackages = with pkgs; [
        fzf
        rust-analyzer
        rnix-lsp
        bat
        clang-tools
        ripgrep
      ];
    };
    tmux = {
      enable = true;
      keyMode = "vi";
      plugins = with pkgs.tmuxPlugins; [
        copycat
        open
      ];
      clock24 = true;
      tmuxp.enable = true;
      baseIndex = 1;
      customPaneNavigationAndResize = true;
      escapeTime = 0;
      terminal = "screen-256color";
      extraConfig = ''
        set -g status-style bg='#44475a',fg='#bd93f9'
        set -g status-interval 1
        setw -g window-status-style fg='#bd93f9',bg=default
        setw -g window-status-current-style fg='#ff79c6',bg='#282a36'
        set -g window-status-current-format "#[fg=#44475a]#[bg=#bd93f9]#[fg=#f8f8f2]#[bg=#bd93f9] #I #W #[fg=#bd93f9]#[bg=#44475a]"
        set -g window-status-format "#[fg=#f8f8f2]#[bg=#44475a]#I #W #[fg=#44475a] "
        set -g status-left '#{?client_prefix,#[fg=#282a36]#[bg=#ff79c6] ,}'
        set -ga status-left '#[bg=#44475a]#[fg=#ff79c6] #{?window_zoomed_flag, ↕ , }'
        set -g status-right '#[fg=#bd93f9,bg=#44475a]#[fg=#f8f8f2,bg=#bd93f9] %a %H:%M:%S #[fg=#6272a4]%Y-%m-%d '

        setw -g mouse
        bind C-q kill-session
        bind Tab run-shell '${toggle-tmux-pane} nnn -hbf -l 15% ${sidebar}'
      '';
    };
    jq.enable = true;
    lesspipe.enable = true;
    lsd = {
      enable = true;
      enableAliases = true;
    };
    mcfly = {
      enable = true;
      enableZshIntegration = true;
    };
    noti.enable = true;
    kitty = {
      enable = true;
      font = {
        name = "SauceCodePro Nerd Font";
        package = sauceFont;
      };
      settings = {
        font_size = if hasBattery then "11.0" else "12.0";
        enable_audio_bell = "no";
      };
      extraConfig = ''
        include ${inputs.kitty-themes}/themes/Dracula.conf
      '';
    };
    zathura.enable = true;
  };
  services = {
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 86400;
      enableSshSupport = true;
      sshKeys = [ "3310F4B460D1579E7BAD6684D9E9B9083B574282" ];
    };
  };
  xdg = {
    enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/plain" = [ "nvim.desktop" ];
        "text/x-script.python" = [ "nvim.desktop" ];
        "text/x-script.sh" = [ "nvim.desktop" ];
        "text/html" = [ "nvim.desktop" ];
        "text/css" = [ "nvim.desktop" ];
        "text/xml" = [ "nvim.desktop" ];
        "application/pdf" = [ "org.pwmt.zathura.desktop" ];
        "application/x-pdf" = [ "org.pwmt.zathura.desktop" ];
        "x-scheme-handler/http" = [ "brave-browser.desktop" ];
        "x-scheme-handler/https" = [ "brave-browser.desktop" ];
        "x-scheme-handler/about" = [ "brave-browser.desktop" ];
        "x-scheme-handler/unknown" = [ "brave-browser.desktop" ];
        "x-scheme-handler/msteams" = [ "teams.desktop" ];
        "x-scheme-handler/nxm" = [ "modorganizer2-nxm-handler.desktop" ];
      };
    };
    configFile."nvim/nix-coc-settings.json" = {
      text = builtins.readFile ./coc-settings.json;
      # Impure settings are maintained in coc-settings.json but are overridden
      # by the pure ones.
      onChange = ''
        config_dir="${"$"}{XDG_CONFIG_HOME-$HOME/.config}/nvim"
          coc_settings="$config_dir/coc-settings.json"
        nix_settings="$config_dir/nix-coc-settings.json"
        if [ -f "$coc_settings" ];
        then
        ${pkgs.coreutils}/bin/cp -L "$nix_settings" "$coc_settings"
        else
        ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$coc_settings" "$nix_settings" \
        | ${pkgs.moreutils}/bin/sponge "$coc_settings"
        fi
      '';
    };
    configFile."tmuxp/nix.json".text = builtins.toJSON {
      windows = [
        {
          panes = [
            {
              shell_command = "while :; do nvim; done";
              focus = true;
            }
            {}
          ];
          layout = "main-horizontal";
          options.main-pane-height = 40;
          focus = true;
          window_name = "editor";
        }
      ];
      session_name = "nix";
      start_directory = "/etc/nixos";
    };
    configFile."tmuxp/default.json".text = builtins.toJSON {
      windows = [
        {
          panes = [
            {
              shell_command = "while :; do nvim; done";
              focus = true;
            }
            {}
          ];
          layout = "main-horizontal";
          options.main-pane-height = 40;
          focus = true;
          window_name = "editor";
        }
      ];
      session_name = "\${PWD}";
      start_directory = "\${PWD}";
    };
  };

  home.file = {
    ".npmrc".text = ''
      ignore-scripts = true
    '';
    ".cookiecutterrc".text = ''
      default_context:
      full_name: "Gregory C. Oakes"
        email: "gregcoakes@gmail.com"
          github_username: "gcoakes"
            gitlab_username: "gcoakes"
    '';
  };

  fonts.fontconfig.enable = true;

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/peripherals/mouse".accel-profile = "flat";
      "org/gnome/desktop/background".picture-uri = "file://${wallpaper}";
      "org/gnome/desktop/screensaver".picture-uri = "file://${wallpaper}";
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-standard;
    };
  };

  home.activation = {
    passwordStoreDownload = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        test -d "$HOME/.password-store" \
      || $DRY_RUN_CMD git clone git@gitlab.com:gcoakes/password-store.git $HOME/.password-store
    '';
    dodPki = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if ! ${pkgs.nssTools}/bin/modutil -dbdir "sql:$HOME/.pki/nssdb" -list | grep -q '^[[:space:]]*[[:digit:]]\+\. CAC Module'; then
      echo "Adding CAC Module to NSS."
      $DRY_RUN_CMD ${pkgs.nssTools}/bin/modutil -dbdir "sql:$HOME/.pki/nssdb" \
      -add "CAC Module" -libfile "$HOME/.nix-profile/lib/opensc-pkcs11.so" \
      && $DRY_RUN_CMD ${pkgs.nssTools}/bin/modutil -dbdir "sql:$HOME/.pki/nssdb" -list \
      | grep -q '^[[:space:]]*[[:digit:]]\+\. CAC Module'
      fi

      if ! ${pkgs.nssTools}/bin/certutil -d "sql:$HOME/.pki/nssdb" -L -n "${inputs.dod-pki}/DoD_PKE_CA_chain.pem"; then
      echo "Installing DoD PKI Certificates."
      $DRY_RUN_CMD ${pkgs.nssTools}/bin/certutil -d "sql:$HOME/.pki/nssdb" -A -t TC \
      -n "${inputs.dod-pki}/DoD_PKE_CA_chain.pem" \
      -i "${inputs.dod-pki}/DoD_PKE_CA_chain.pem"
      fi
    '';
  };
}
