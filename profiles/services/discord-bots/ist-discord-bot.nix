# Setup ist-discord-bot
{
  config,
  inputs,
  secrets,
  ...
}:
{
  imports = [
    inputs.ist-discord-bot.nixosModules.ist-discord-bot
  ];

  age.secrets.istDiscordBotToken.file = secrets.host.istDiscordBotToken;

  services.ist-discord-bot = {
    enable = true;
    createPostgresqlDatabase = true;

    settings = {
      DISCORD_TOKEN_FILE = config.age.secrets.istDiscordBotToken.path;
      GUILD_ID = "759576132227694642";
      ADMIN_ID = "760174167223566416";
      ADMIN_PLUS_ID = "759811293326082060";
      COMMAND_LOGS_CHANNEL_ID = "896886447594950696";
    };
  };
}
