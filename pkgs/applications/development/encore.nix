{
  fetchFromGitHub,
  buildGoModule,
  makeWrapper,
  callPackage,
  ...
}:
buildGoModule rec {
  pname = "encore";
  version = "1.39.0";

  src = fetchFromGitHub {
    name = "${pname}-source";
    owner = "encoredev";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-71vzo52vV4VilBnLZxIWDKIY08rfTavMZ57qgi4pip8=";
  };

  doCheck = true;

  subPackages = [
    "cli/cmd/encore"
    "cli/cmd/git-remote-encore"
    "cli/cmd/tsbundler-encore"
  ];

  nativeBuildInputs = [makeWrapper];

  CGO_ENABLED = 1;

  postInstall = let
    goEncore = callPackage ./go-encore.nix {};
  in ''
    mkdir -p $out/share/runtimes
    cp -r $src/runtimes/* $out/share/runtimes

    ln -s ${goEncore}/bin/* $out/bin

    wrapProgram $out/bin/encore \
      --set ENCORE_RUNTIMES_PATH $out/share/runtimes \
      --set ENCORE_GOROOT ${goEncore}/share/go \
      --set GOROOT ${goEncore}/share/go
  '';

  vendorHash = "sha256-lM03+eBrny7uNKAq4xuQ3HSmX+aglaSEaRCetGgdyjQ=";
  proxyVendor = true;
}
