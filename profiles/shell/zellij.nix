# Terminal multiplexer
{...}: {
  hm.programs.zellij = {
    enable = true;

    settings = {
      theme = "nord";
      show_startup_tips = false;
      # Avoid keeping dead sessions around
      session_serialization = false;
    };
  };
}
