{ email, inputs }:
{ config, pkgs, lib, nixosConfig, ... }:
let
  toggle-tmux-pane = with pkgs; writeShellScript "toggle-tmux-pane" ''
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
  sidebar = with pkgs; writeShellScript "sidebar" ''
    window_id="$(tmux list-panes -F '#{window_id}' | head -n1)"
    export NVIM_LISTEN_ADDRESS="${"$"}{XDG_RUNTIME_DIR-/tmp}/tmux-nvim-$window_id"
    export NNN_OPENER="${tnvr}"
    exec ${nnnNerd}/bin/nnn -c $@
  '';
  nnnNerd = pkgs.nnn.override { withNerdIcons = true; };
  tnvr = with pkgs; writeShellScriptBin "tnvr" ''
    if [ -n "$TMUX" ]; then
      pane_id="$(${neovim-remote}/bin/nvr --nostart -s --remote-expr 'get(environ(), "TMUX_PANE")')"
      if [ -n "$pane_id" ]; then
        tmux select-pane -t "$pane_id"
      fi
    fi
    exec ${neovim-remote}/bin/nvr $@
  '';
  editor = with pkgs; writeShellScriptBin "editor" ''
    if [ -n "$1" ]; then
      cd "$1" || exit 1
    fi
    if [ -f .envrc ]; then
      direnv allow || exit 2
    fi
    exec tmuxp load -a default
  '';
in
{
  home.packages = with pkgs; [
    editor
    git-review
    nixpkgs-fmt
    nnnNerd
    poetry
    (python27.withPackages (ps: with ps; [ virtualenv ]))
    python36
    tnvr
  ];
  home.sessionVariables = { EDITOR = "nvim"; };
  programs = {
    fish = {
      enable = true;
      shellInit = ''
        if set -q TMUX
          set window_id (tmux list-panes -F '#{window_id}' | head -n1)
          set -q XDG_RUNTIME_DIR; or set XDG_RUNTIME_DIR /tmp
          set -gx NVIM_LISTEN_ADDRESS "$XDG_RUNTIME_DIR/tmux-nvim-$window_id"
          set -gx EDITOR "${tnvr}/bin/tnvr -s"
        end
      '';
      plugins = [
        { name = "theme-agnoster"; src = inputs.theme-agnoster; }
      ];
    };
    fzf = {
      enable = true;
      enableFishIntegration = true;
    };
    git = {
      enable = true;
      userEmail = email;
      userName = "Gregory C. Oakes";
      ignores = [ ".direnv/" "coc-settings.json" ];
      delta.enable = true;
      extraConfig = {
        core.editor = "${tnvr}/bin/tnvr --remote-wait-silent -s";
        init.defaultBranch = "main";
      };
    };
    direnv = {
      enable = true;
      enableFishIntegration = true;
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
        coc-pyright
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
        bat
        clang-tools
        fzf
        ripgrep
        rnix-lsp
        rust-analyzer
      ];
    };
    tmux = {
      enable = true;
      keyMode = "vi";
      plugins = with pkgs.tmuxPlugins; [ copycat open ];
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
        set -g automatic-rename on
        set -g automatic-rename-format '#{s|([^/])[^/]*/|\1/|g:pane_current_path}'

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
    bat = {
      enable = true;
      config = {
        pager = "less -FR";
        theme = "Dracula";
      };
      themes.dracula = inputs.dracula-sublime + "/Dracula.tmTheme";
    };
  };
  xdg = {
    enable = true;
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
    configFile."tmuxp/default.json".text = builtins.toJSON {
      windows = [
        {
          panes = [
            {
              shell_command = "while true; nvim; end";
              focus = true;
            }
            { }
          ];
          layout = "main-horizontal";
          options.main-pane-height = 40;
          focus = true;
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
  };
}
