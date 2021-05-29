{ email, inputs }:
{ config, pkgs, lib, nixosConfig, ... }:
let
  hidden-shell = with pkgs;
    writeShellScriptBin "hidden-shell" ''
      cat > shell.nix <<EOF
      with (builtins.getFlake flake:nixpkgs).legacyPackages.x86_64-linux;
      mkShell {
        nativeBuildInputs = [ $@ ];
        buildInputs = [];
      }
      EOF
      echo use nix > .envrc
      echo shell.nix >> .git/info/exclude
    '';
in {
  home.packages = with pkgs; [
    cargo
    cargo-edit
    git-review
    kubectl
    kubernetes-helm
    nixfmt
    poetry
    python3
    rustc
  ];
  programs = {
    vscode = {
      enable = true;
      package = pkgs.vscodium;
      extensions = with pkgs.vscode-extensions; [
        a5huynh.vscode-ron
        antfu.icons-carbon
        bbenoist.Nix
        brettm12345.nixfmt-vscode
        dracula-theme.theme-dracula
        eamodio.gitlens
        elmtooling.elm-ls-vscode
        esbenp.prettier-vscode
        file-icons.file-icons
        foxundermoon.shell-format
        github.vscode-pull-request-github
        jock.svg
        justusadam.language-haskell
        matklad.rust-analyzer
        ms-azuretools.vscode-docker
        ms-kubernetes-tools.vscode-kubernetes-tools
        ms-python.vscode-pylance
        ms-vscode.cpptools
        redhat.vscode-yaml
        serayuzgur.crates
        tamasfe.even-better-toml
        timonwong.shellcheck
        tomoki1207.pdf
        vadimcn.vscode-lldb
        vscodevim.vim
        yzhang.markdown-all-in-one
      ];
    };
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
          export EDITOR="codium --wait"
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
  xdg.configFile."VSCodium/User/nix-settings.json" = {
    source = ./.vscode/settings.json;
    onChange = with pkgs; ''
      cd "${"$"}{XDG_CONFIG_HOME-$HOME/.config}/VSCodium/User"
      ${jq}/bin/jq -s '.[0] * .[1]' settings.json nix-settings.json \
      | ${moreutils}/bin/sponge settings.json
    '';
  };
}
