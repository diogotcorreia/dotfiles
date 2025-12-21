# OpenSSH server configuration
{ lib, ... }:
let
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICYiuCHjX9Dmq69WoAn7EfgovnFLv0VhjL7BSTYQcFa7 dtc@apollo"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINlaWu32ANU+sWFcwKrPlqD/oW3lC3/hrA1Z3+ubuh5A dtc@bacchus"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJG5pN82I+kQMlD49a7aUum+ms5wUXZoqW03BBjULONA dtc@bluejay"
  ];
in
{
  services.openssh = {
    enable = true;
    authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    ports = [ lib.my.ports.ssh ];
  };
  usr.openssh.authorizedKeys.keys = sshKeys;

  modules.services.nebula.firewall.inbound = [
    {
      port = lib.my.ports.ssh;
      proto = "tcp";
      group = "dtc";
    }
  ];
}
