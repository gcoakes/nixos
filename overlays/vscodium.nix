inputs: final: prev:
with prev;
let
  myCodium = vscode-with-extensions.override {
    vscode = vscodium;
    vscodeExtensions = with vscode-extensions;
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
      ] ++ vscode-utils.extensionsFromVscodeMarketplace [
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

in {
  vscodium = lib.wrapPrograms {
    paths = [ myCodium ];
    wrap.codium = {
      script = ''
        settings="${
          "$"
        }{XDG_CONFIG_HOME-$HOME/.config}/VSCodium/User/settings.json"
        ${jq}/bin/jq -s '.[0] * .[1]' "${
          ../.vscode/settings.json
        }" "$settings" \
        | ${moreutils}/bin/sponge "$settings"
        exec "${myCodium}/bin/codium" $@
      '';
      path = [ clang-tools haskell-language-server nixfmt ];
    };
  };
}
