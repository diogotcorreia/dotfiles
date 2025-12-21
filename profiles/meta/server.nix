{ profiles, ... }:
{
  imports = with profiles; [
    # extend common
    meta.common

    monitoring.prometheus-exporters.node
  ];
}
