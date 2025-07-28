{ profiles, ... }:
{
  imports = with profiles; [
    # extend common
    meta.common

    shell.programs.personal
  ];
}
