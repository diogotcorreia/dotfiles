# Add restic build that does not bundle rclone
{...}: (_: prev: {
  restic-without-rclone = prev.restic.override {rclone = "/dev/null";};
})
