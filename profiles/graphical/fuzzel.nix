# Application launcher
{...}: {
  hm.programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        list-executables-in-path = true;
      };
    };
  };
}
