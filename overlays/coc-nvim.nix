inputs: final: prev:
{
  vimPlugins = prev.vimPlugins // {
    coc-nvim = prev.vimUtils.buildVimPluginFrom2Nix {
      pname = "coc-nvim";
      version = "ad49565b";
      src = inputs."coc.nvim";
      meta.homepage = "https://github.com/gcoakes/coc.nvim/";
    };
  };
}
