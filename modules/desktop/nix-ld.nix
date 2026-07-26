{pkgs, ...}: {
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Standard C/C++ runtime
      stdenv.cc.cc.lib

      # Compression
      zlib

      # Graphics
      libGL
      libglvnd
      vulkan-loader

      # Audio
      libpulseaudio

      # X11 / windowing
      libx11
      libxcursor
      libxi
      libxinerama
      libxrandr
      libxxf86vm
      libxcb

      # Networking / crypto
      openssl

      # Misc commonly needed by games and AppImages
      freetype
      fontconfig
      dbus
      udev
    ];
  };
}
