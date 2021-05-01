{ email, inputs }:
{ config, pkgs, lib, nixosConfig, ... }: {
  home.packages = with pkgs; [
    git-review
    nixfmt
    python3
    poetry
    cargo
    rustc
    cargo-edit
    rust-analyzer
  ];
  programs = {
    vscode.enable = true;
    zsh = {
      enable = true;
      oh-my-zsh = {
        enable = true;
        theme = "fino-time";
        plugins = [ "colored-man-pages" ];
      };
      initExtra = ''
        if [ -n "$TMUX" ]; then
          window_id="$(tmux list-panes -F '#{window_id}' | head -n1)"
        fi
        if [ -z "$DISPLAY" ]; then
          export EDITOR=nvim
        else
          export EDITOR="code --wait"
        fi
        export GIT_EDITOR="$EDITOR"
      '';
      enableAutosuggestions = true;
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    git = {
      enable = true;
      userEmail = email;
      userName = "Gregory C. Oakes";
      ignores = [ ".direnv/" ".vscode/" ".envrc" ];
      delta.enable = true;
      extraConfig = { init.defaultBranch = "main"; };
    };
    direnv = {
      enable = true;
      enableZshIntegration = true;
      enableNixDirenvIntegration = true;
    };
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      extraConfig = builtins.readFile ./init.vim;
      plugins = with pkgs.vimPlugins; [
        dracula-vim
        fzf-vim
        lightline-vim
        vim-nix
        vim-rooter
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
  home.file = {
    ".npmrc".text = ''
      ignore-scripts = true
    '';
  };
}
