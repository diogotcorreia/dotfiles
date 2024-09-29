{ lib, ... }:
let
  /**
    Synopsis: filterHosts filters hosts

    Filter and select hosts from the provided attribute set based on the specified filters.

    Inputs:
    - filters: A list of functions that receive a host's configuration as an argument and return a boolean value.
    - hosts: An attribute set representing NixOS system configurations for multiple hosts.

    Output Format:
    An attribute set containing a subset of hosts from the provided `hosts` attribute set that satisfy all the specified filters.
    The function applies the filters to each host's configuration and includes only those hosts that pass all the filters.

    Example:
    filterHosts [ (config: config.services.nginx.enable) ] {
      webserver1 = <nixosConfiguration>;
      webserver2 = <nixosConfiguration>;
      host3 = <nixosConfiguration>;
    }

    Example output:
    {
      "webserver1" = { ... };
      "webserver2" = { ... };
    }
  */
  filterHosts =
    filters: hosts: lib.filterAttrs (_: { config, ... }: builtins.all (f: f config) filters) hosts;
in
{
  inherit filterHosts;
}
