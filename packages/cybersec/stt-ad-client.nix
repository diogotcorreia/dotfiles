{
  requireFile,
  lib,
  python3Packages,
  ...
}:
python3Packages.buildPythonApplication {
  pname = "stt-ad-client";
  version = "0.0";

  src = requireFile rec {
    name = "ad-client.tar.gz";
    message = ''
      The team captain should send you the ad-client tarball for the specific CTF.
      The file can be imported with `nix-store --add-fixed sha256 ${name}`.
      It is important that the file is named '${name}', otherwise it will not work.
    '';
    # get hash with `nix hash file ad-client.tar.gz`
    hash = "sha256-Pl/z5y2975oe31tABkNXFMoDK01VkpBj9bD8rYqVTj8=";
  };

  propagatedBuildInputs = with python3Packages; [
    requests
    pwntools
    pika
    future
    regex
  ];

  # package tries to do HTTP requests during testing (doesn't work on sandbox)
  doCheck = false;

  meta = with lib; {
    description = "Attack defense client for Security Team @ Técnico (STT)";
    license = licenses.unfree; # closed source
    platforms = platforms.linux;
  };
}
