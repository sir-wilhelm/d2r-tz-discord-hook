# d2r-tz-discord-hook

PowerShell script that polls the **d2emu** Terror Zone API and optionally posts alerts to a **Discord** channel via webhook.

Ex notifications:

<img width="527" height="634" alt="image" src="https://github.com/user-attachments/assets/7fb46a7b-1d3f-4cd0-8a4d-39b205c3a350" />

## What it does

- Defines an “alert list” of zone IDs you care about (`$d2rAlertZoneIds`).
- On a schedule (minute `00`, `05`, `30`, `35` of each hour), calls the d2emu API for terror zone info.
- If any **current** __or__ **next** terror zone matches your alert list, it prints a message or (with `-SendToDiscord`) sends it to Discord.
- With `-DumpInfo`, it prints/sends the **current** terror zone info ignoring the `$d2rAlertZoneIds` filter.

## Configure the zones you care about

Edit the `$d2rAlertZoneIds` array in `CheckTzAndAlertDiscord.ps1`. Ex for keys/act bosses:

```powershell
$d2rAlertZoneIds = @(
    20,  # "Forgotten Tower"
    37,  # "Catacombs 4"
    73,  # "Tal Rashas Chamber"
    74,  # "Arcane Sanctuary"
    102, # "Durance of Hate 3"
    108, # "Chaos Sanctuary"
    123, # "Halls of Pain"
    132  # "Worldstone Keep"
)
```

- The numeric IDs come from the `$d2rZoneIds` mapping near the top of the script.
- Keep this list to integers only.

## Configure secrets in `tz-bot.env`

The script reads required secrets from `tz-bot.env` placed next to `CheckTzAndAlertDiscord.ps1`.

1. Rename `tz-bot.env.example` to `tz-bot.env`.
2. Fill in these required values in JSON:

```json
{
  "X_EMU_USERNAME": "<your d2emu username>",
  "X_EMU_TOKEN": "<your d2emu token>",
  "DISCORD_WEBHOOK_URL": "https://discord.com/api/webhooks/<id>/<token>"
}
```

If any required key is missing, the script fails and prints what value is missing.

### Getting d2emu API credentials

You must request API access from **d2emu**:
1. Join their Discord: https://www.d2emu.com/about
2. Then open [#request-token](https://discord.com/channels/1083777671172980826/1277801738103160912) and create a ticket.
3. Copy the username/token into your `tz-bot.env` file.

### Creating a Discord webhook

1. In Discord, open your server and choose the target channel.
2. Channel Settings → Integrations → Webhooks → “New Webhook”.
3. Copy the webhook URL into `DISCORD_WEBHOOK_URL` in `tz-bot.env`.

## Usage

Run once to print the current and next terror zone(s):
```powershell
pwsh -File .\CheckTzAndAlertDiscord.ps1 -DumpInfo
```

Send the current and next terror zone(s) to Discord:
```powershell
pwsh -File .\CheckTzAndAlertDiscord.ps1 -DumpInfo -SendToDiscord
```

Run continuously (waits until the next query time and loops forever):
```powershell
pwsh -File .\CheckTzAndAlertDiscord.ps1
```

Run continuously and send alerts to Discord:
```powershell
pwsh -File .\CheckTzAndAlertDiscord.ps1 -SendToDiscord
```

### RunOnce

Use `-RunOnce` to do a single poll + alert pass and then exit.

This is the best option when running from `cron` so you don’t end up with overlapping long-running processes.

Examples:

- One-time check (prints to console):
  ```powershell
  pwsh -File .\CheckTzAndAlertDiscord.ps1 -RunOnce
  ```
- One-time check (send alerts to Discord):
  ```powershell
  pwsh -File .\CheckTzAndAlertDiscord.ps1 -RunOnce -SendToDiscord
  ```

## Scheduling

The script calculates the next poll time via `GetNextQueryTime` (currently `:00`, `:05`, `:30`, and `:35` each hour).

Examples:

- Linux `cron` (every hour 8am 9pm at minute 00, 05, 30, 35 Sat/Sun):
  ```
  00,05,30,35 8-21 * * Sun,Sat pwsh -File /home/<username>/scripts/CheckTzAndAlertDiscord.ps1 -SendToDiscord -RunOnce
  ```

- Windows: use **Task Scheduler** to run `pwsh.exe` with arguments like or run in console:
  - `-File "E:\src\d2r-tz-discord-hook\CheckTzAndAlertDiscord.ps1" -SendToDiscord`
  - Ensure the runtime is set to indefinitely so it does not get terminated.
