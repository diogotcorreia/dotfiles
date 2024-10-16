{
  requireFile,
  lib,
  python3Packages,
  ...
}:
python3Packages.buildPythonApplication {
  pname = "stt-ad-client";
  version = "0.0";

  src = requireFile {
    name = "ad-client.tar.gz";
    message = "The team captain should send you the ad-client tarball for the specific CTF";
    hash = "sha256-mUzCCZvcb3HEYXE1+GLyipg5sY+am/9Mqmzdz44Hv5I=";
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
