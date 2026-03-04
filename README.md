# d2r-tz-discord-hook

PowerShell script that polls the **d2emu** Terror Zone API and optionally posts alerts to a **Discord** channel via webhook.

## What it does

- Maintains a lookup table of Diablo II: Resurrected zone IDs (`$d2rZoneIds`).
- Defines an “alert list” of zone IDs you care about (`$d2rAlertZoneIds`).
- On a schedule (minute `01`, `05`, `31`, `35` of each hour), calls the d2emu API for terror zone info.
- If any **current** __or__ **next** terror zone matches your alert list, it prints a message or (with `-SendToDiscord`) sends it to Discord.
- With `-DumpInfo`, it prints/sends the **current** terror zone info ignoring the `$d2rAlertZoneIds` filter.

## Configure the zones you care about

Edit the `$d2rAlertZoneIds` array in `CheckTzAndAlertDiscord.ps1` ex for keys/act bosses:

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

## Configure d2emu API access (`x-emu-*` headers)

`GetTzInfo` currently uses two HTTP headers:

- `x-emu-username`
- `x-emu-token`

You must request API access from **d2emu**  to obtain valid values:
* Join their discord https://www.d2emu.com/about
* Then go to [#request-token](https://discord.com/channels/1083777671172980826/1277801738103160912) and create a ticket asking for access.

## Configure the Discord webhook

`NotifyDiscord` posts to a Discord webhook URL like:

```
https://discord.com/api/webhooks/<id>/<token>
```

To create one:

1. In Discord, open your server and choose the target channel.
2. Channel Settings → Integrations → Webhooks → “New Webhook”.
3. Copy the webhook URL and replace the `$webhook = "..."` value in `NotifyDiscord`.

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

The script calculates the next poll time via `GetNextQueryTime` (currently `:01`, `:05`, `:31`, and `:35` each hour).

Examples:

- Linux `cron` (every hour 8–22 at minute 01, 05, 31, 35):
  ```
  01,05,31,35 8-22 * * * pwsh -File /home/<user>/scripts/CheckTzAndAlertDiscord.ps1 -RunOnce -SendToDiscord
  ```

- Windows: use **Task Scheduler** to run `pwsh.exe` with arguments like:
  - `-File "E:\src\d2r-tz-discord-hook\CheckTzAndAlertDiscord.ps1" -SendToDiscord`
  - Ensure the runtime is set to indefinitely so it does not get terminated.
