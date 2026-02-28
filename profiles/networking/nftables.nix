# Use nftables instead of the default iptables
{ ... }:
{
  networking.nftables.enable = true;
}
