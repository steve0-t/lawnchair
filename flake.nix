{
  description = "Flake java and c environment";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config = {
        allowUnfree = true;
        android_sdk.accept_license = true;
      };
    };
    androidSdk =
      (pkgs-unstable.androidenv.composeAndroidPackages {
        platformVersions = ["37.2"];
        buildToolsVersions = ["37.0.0"];
        includeEmulator = false;
        includeSystemImages = false;
        includeSources = false;
      }).androidsdk;
    # junitJar = pkgs.stdenv.mkDerivation {
    #   pname = "junit";
    #   version = "1.14.3";
    #   src = pkgs.fetchurl {
    #     url = "https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/1.14.3/junit-platform-console-standalone-1.14.3.jar";
    #     sha256 = "sha256-kJogqLFzrKNI+3wbttyNmyNNMJXFtSuBaZ10LhSn9ho=";
    #   };
    #   dontUnpack = true;
    #   installPhase = ''
    #     install -Dm644 $src $out/share/junit-platform-console-standalone.jar
    #     mkdir -p $out/bin
    #     cat > $out/bin/junit-console <<EOF
    #     #!${pkgs.runtimeShell}
    #     exec ${pkgs.jdk17}/bin/java -jar $out/share/junit-platform-console-standalone.jar "\$@"
    #     EOF
    #     chmod +x $out/bin/junit-console
    #   '';
    # };
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs;
        [
          libgcc
          jdk21
          androidSdk
          maven
          mvnd
          spring-boot-cli
        ]
        ++ (with pkgs-unstable; [
          jdt-language-server
          # android-studio
        ]);

      # export GLFW_PLATFORM_WAYLAND=1
      shellHook = ''
        export JAVA_HOME=${pkgs.jdk21}
        export PATH="${pkgs.jdk21}/bin:$PATH"
        export ANDROID_HOME=${androidSdk}/libexec/android-sdk
        export ANDROID_SDK_ROOT="$ANDROID_HOME"
        export GRADLE_OPTS="-Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/37.0.0/aapt2 ''${GRADLE_OPTS:-}"
        export GLFW_PLATFORM=wayland
        export _JAVA_AWT_WM_NONREPARENTING=1
      '';
    };
  };
}
