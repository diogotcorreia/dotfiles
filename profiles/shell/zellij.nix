# Terminal multiplexer
{
  config,
  pkgs,
  user,
  ...
}:
{
  hm.programs.zellij = {
    enable = true;

    settings = {
      theme = "nord";
      show_startup_tips = false;
      # Avoid keeping dead sessions around
      session_serialization = false;
    };
  };

  hm.home.packages = [
    # Script to rename all zellij tabs according to their position
    # https://github.com/zellij-org/zellij/issues/3709#issuecomment-2766730939
    (pkgs.writeShellApplication {
      name = "zr";

      runtimeInputs = [
        config.home-manager.users.${user}.programs.zellij.package
      ];
      text = ''
        if [[ -z "$ZELLIJ" ]]; then
          echo "Not inside a Zellij session"
          exit 1
        fi

        zellij action rename-tab "__CURRENT__"
        TABS=$(zellij action query-tab-names)

        zellij action go-to-tab 1

        i=1
        CURRENT_INDEX=0

        while IFS= read -r TAB; do
          if [[ "$TAB" == "__CURRENT__" ]]; then
            CURRENT_INDEX=$i
          fi
          zellij action rename-tab "Tab #$i"
          i=$((i + 1))
          zellij action go-to-next-tab
        done <<< "$TABS"

        zellij action go-to-tab $CURRENT_INDEX
      '';
    })
  ];
}
