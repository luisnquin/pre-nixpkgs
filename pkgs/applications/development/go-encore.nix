{
  fetchFromGitHub,
  stdenv,
  lib,
  go,
  ...
}: let
  shortVersion = "1.22";
in
  stdenv.mkDerivation rec {
    pname = "go-encore";
    version = "${shortVersion}.0";

    src = fetchFromGitHub {
      owner = "encoredev";
      repo = "go";
      rev = "encore-go${version}";
      sha256 = "sha256-SSa3CoUS6JMfs6T1PMb3NK8UeJnpLlTIn46/3oCTnL8=";
    };

    buildInputs = [go];

    patchPhase = let
      goSrc = fetchFromGitHub {
        owner = "golang";
        repo = "go";
        rev = "release-branch.go${shortVersion}";
        hash = "sha256-amASGhvBcW90dylwFRC2Uj4kOAOKCgWmFKhLnA9dOgg=";
      };
    in ''
      # delete submodule and replace with the go source
      rm -rf go
      cp -r ${goSrc} go
      chmod -R u+rw go

      cd go

      for patch in ../patches/*.diff; do
        patch --verbose -p1 --ignore-whitespace < "$patch"
      done

      cp -p -P -v -R ../overlay/* ./

      cd ..
    '';

    installPhase = let
      goarch = platform:
        {
          "aarch64" = "arm64";
          "arm" = "arm";
          "armv5tel" = "arm";
          "armv6l" = "arm";
          "armv7l" = "arm";
          "i686" = "386";
          "mips" = "mips";
          "mips64el" = "mips64le";
          "mipsel" = "mipsle";
          "powerpc64" = "ppc64";
          "powerpc64le" = "ppc64le";
          "riscv64" = "riscv64";
          "s390x" = "s390x";
          "x86_64" = "amd64";
        }
        .${platform.parsed.cpu.name}
        or (throw "Unsupported system: ${platform.parsed.cpu.name}");
    in ''
      mkdir -p /tmp/.gobuild-cache
      GOCACHE=/tmp/.gobuild-cache go run . \
        --goos "${stdenv.targetPlatform.parsed.kernel.name}" \
        --goarch "${goarch stdenv.targetPlatform}"

      mkdir -p $out/{bin,share/go}

      cp -r dist/${stdenv.targetPlatform.parsed.kernel.name}_${goarch stdenv.targetPlatform}/encore-go/* $out/share/go
      ln -s $out/share/go/bin/go $out/bin
      mv $out/bin/go $out/bin/go-encore
    '';

    meta = with lib; {
      description = "Encore's Go runtime";
      homepage = "https://encore.dev";
      platforms = platforms.linux;
    };
  }
