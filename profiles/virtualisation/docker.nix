{...}: {
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  # Persist Docker images and volumes
  modules.impermanence.directories = ["/var/lib/docker"];
}
