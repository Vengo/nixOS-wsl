{ config, pkgs, lib, ... }:

{
  wsl = {
    enable = true;
    defaultUser = "nixos";
    useWindowsDriver = true;

    # Fix for WSL 2.9.8+ wsl-mnt-guard.service
    extraBin = [
      { src = "${pkgs.coreutils}/bin/true"; }
      { src = "${pkgs.util-linux}/bin/mount"; }
    ];
  };

  hardware.graphics.enable = true;
  # Skip building HTML documentation outputs (.doc) for system packages on WSL
  documentation.doc.enable = false;

  # Global CLI packages available everywhere
  environment.systemPackages = with pkgs; [
    git
    uv
    python312
    nvtopPackages.nvidia # Live terminal monitor for both RTX 3090s
    htop
    wget
    curl
    vim
  ];

  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://cache.nixos.org"
      "https://cache.nixos-cuda.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };

  # Allow unpatched binaries (uv Python builds, pip wheels, nvidia-smi, VS Code) to run
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = (with pkgs; [
    stdenv.cc.cc
    zlib
    glib
    libGL
  ]) ++ config.hardware.graphics.extraPackages;

  # Expose WSL drivers + nix-ld libraries to dynamically linked wheels (PyTorch, Triton, etc.)
  environment.extraInit = ''
    export PATH="/usr/lib/wsl/lib:$PATH"
    export LD_LIBRARY_PATH="/usr/lib/wsl/lib:/run/opengl-driver/lib:$NIX_LD_LIBRARY_PATH:$LD_LIBRARY_PATH"
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
