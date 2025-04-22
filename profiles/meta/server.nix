{profiles, ...}: {
  imports = with profiles; [
    # extend common
    meta.common
  ];
}
