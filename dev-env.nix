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
    cabal-install
    cargo
    cargo-edit
    clang-tools
    ghc
    git-review
    haskell-language-server
    hidden-shell
    kubectl
    kubernetes-helm
    nixfmt
    poetry
    python3
    rustc
    stack
  ];
  programs = {
    vscode = {
      enable = true;
      package = pkgs.vscodium;
      extensions = with pkgs.vscode-extensions;
        [
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
          haskell.haskell
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
          xaver.clang-format
          yzhang.markdown-all-in-one
        ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "nix-env-selector";
            publisher = "arrterian";
            version = "1.0.7";
            sha256 = "0mralimyzhyp4x9q98x3ck64ifbjqdp8cxcami7clvdvkmf8hxhf";
          }
          {
            name = "gruvbox-themes";
            publisher = "tomphilbin";
            version = "1.0.0";
            sha256 = "0xykf120j27s0bmbqj8grxc79dzkh4aclgrpp1jz5kkm39400z0f";
          }
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
