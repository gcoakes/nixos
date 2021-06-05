inputs: final: prev: {
  picom = prev.picom.overrideAttrs (old: { src = inputs.picom; });
}
