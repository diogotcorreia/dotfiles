{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    fira-code
    noto-fonts
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
  ];
}
