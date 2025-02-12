{...}: {
  # Keep a list of ports in a single file to make it easier to keep
  # track of assigned ports across all profiles/modules
  ports = {
    ssh = 22;
    smtp = 25;
    dns = 53;
    dhcpServer = 67;
    dhcpClient = 68;
    http = 80;
    imap = 143;
    https = 443;
    emailSubmissionTls = 465;
    emailSubmission = 587;
    imaps = 993;

    socksCaptivePortalsClient = 1666;
    nodered = 1880;
    mqtt = 1883;
    jellyfinAutoDiscoveryDlna = 1900;

    pairdrop = 2326;

    dawarich = 3000;
    meilisearch = 3449;
    lldapLdap = 3890;

    manageSieve = 4190;

    reposilite = 5100;
    mdnsGoogleCast = 5353;
    wastebin = 5435;
    jellyseerr = 5055;
    coiot = 5683; # CoIoT (Shelly Push)

    conduit = 6167;
    infraKeyval = 6442;
    bazarr = 6767;

    jellyfinAutoDiscoveryClients = 7359;
    chhotoUrl = 7542;
    battleships = 7643;
    dtcLabs = 7649;
    twin = 7650;
    radarr = 7878;

    uptimeKuma = 8002;
    healthchecks = 8003;
    atticd = 8004;
    bookMetadataApi = 8004;
    calibreWeb = 8011;
    iHateToBudget = 8013;
    immich = 8084;
    musicAssistantWeb = 8095;
    jellyfin = 8096;
    musicAssistantAudioStream = 8097;
    homeAssistant = 8123;
    umami = 8380;
    sonarr = 8989;

    socksFirefox = 9000;
    authelia = 9091;
    transmission = 9091;
    jackett = 9117;
    stalwartMailHttp = 9988;

    lldapHttp = 17170;

    paperless = 28981;

    rproxy0 = 44380;
    rproxy1 = 44381;
    rproxy2 = 44382;

    wireguard = 51820;
  };
}
