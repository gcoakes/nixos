inputs: final: prev: {
  lib = prev.lib.extend (finalLib: prevLib: {
    wrapPrograms = prev.callPackage ./wrap-programs.nix { };
  });
}
