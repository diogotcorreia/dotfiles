# Cybersecurity and CTF related tools.
{pkgs, ...}: {
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark; # use Qt version instead of CLI version
  };
  usr.extraGroups = [
    "wireshark"
    "dialout" # access USB TTY devices without sudo
  ];

  hm.home.packages = with pkgs; [
    # Enhanced GDB
    gef
    # hx (hexdump replacement)
    hex
    # Java Decompiler
    jadx
    # Binary Decompiler
    unstable.ghidra
  ];
}
