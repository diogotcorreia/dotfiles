# Enable ZRAM swap and set its size to 150% of total RAM size
{...}: {
  zramSwap = {
    enable = true;
    memoryPercent = 150;
  };
}
