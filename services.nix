with builtins;
{ config, pkgs, ... }:
let
  rustKernel = pkgs.rustPlatform.buildRustPackage rec {
    pname = "evcxr";
    version = "0.4.6";
    src = pkgs.fetchFromGitHub {
      owner = "google";
      repo = pname;
      rev = "v${version}";
      sha256 = "12hlqgh74z8vmd7fkxh4vk3dqp8hlhzkxnbyywk6nphi562n6w5w";
    };
    cargoSha256 = "1vikhgy8ixhm28j5s19p9s1cxyyfj1dywyb20xajyhr5cij4blrm";
    nativeBuildInputs = [ pkgs.cmake ];
  };
  myPython = pkgs.python3.withPackages (ps:
    with ps; [
      ipykernel
      ipykernel
      ipywidgets
      beautifulsoup4
      lightning
      matplotlib
      seaborn
      aiohttp
    ]);
in {
  services.jupyter = {
    enable = true;
    notebookDir = "/mnt/work";
    password = "'sha1:6d7e49cc865b:2f62311bd587a74d4b71595b7d67e0843e986448'";
    port = 8888;
    kernels = {
      python3 = {
        displayName = "Python 3";
        argv = [
          myPython.interpreter
          "-m"
          "ipykernel_launcher"
          "-f"
          "{connection_file}"
        ];
        language = "python";
        logo32 =
          "${myPython}/${myPython.sitePackages}/ipykernel/resources/logo-32x32.png";
        logo64 =
          "${myPython}/${myPython.sitePackages}/ipykernel/resources/logo-64x64.png";
      };
      rust = {
        displayName = "Rust";
        argv = [
          "${rustKernel}/bin/evcxr_jupyter"
          "--control_file"
          "{connection_file}"
        ];
        language = "rust";
      };
    };
  };
}
