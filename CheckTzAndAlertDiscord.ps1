#crontab -e
#run at minute 0, 5, 30, and 35 past every hour from 8am through 9pm on Sun/Sat
#00,05,30,35 8-21 * * Sun,Sat pwsh -File /home/<username>/scripts/CheckTzAndAlertDiscord.ps1 -SendToDiscord -RunOnce

param(
    [switch]$DumpInfo,
    [switch]$SendToDiscord,
    [switch]$RunOnce
)

function Import-JsonConfigFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        throw "Missing config file at '$Path'. Copy tz-bot.env.example to tz-bot.env and set required values."
    }

    try {
        $config = Get-Content -Path $Path -Raw | ConvertFrom-Json
    }
    catch {
        throw "Invalid JSON in '$Path'. Ensure tz-bot.env contains a valid JSON object."
    }

    if ($null -eq $config) {
        throw "Config file '$Path' is empty. Add required keys to the JSON object."
    }

    return $config
}

function Assert-RequiredConfig {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Config,
        [Parameter(Mandatory = $true)]
        [string[]]$Names
    )

    $missing = @()
    foreach ($name in $Names) {
        $value = $Config.$name
        if ([string]::IsNullOrWhiteSpace($value)) {
            $missing += $name
        }
    }

    if ($missing.Count -gt 0) {
        throw "Missing required config value(s): $($missing -join ', '). Set these keys in '$PSScriptRoot\tz-bot.env'."
    }
}

$script:BotConfig = Import-JsonConfigFile -Path "$PSScriptRoot\tz-bot.env"
Assert-RequiredConfig -Config $script:BotConfig -Names @('X_EMU_USERNAME', 'X_EMU_TOKEN', 'DISCORD_WEBHOOK_URL')

$script:XEmuUsername = [string]$script:BotConfig.X_EMU_USERNAME
$script:XEmuToken = [string]$script:BotConfig.X_EMU_TOKEN
$script:DiscordWebhookUrl = [string]$script:BotConfig.DISCORD_WEBHOOK_URL

$d2rZoneIds = @(
    @(0, "None"),
    @(1, "Rogue Encampment"),
    @(2, "Blood Moor"),
    @(3, "Cold Plains"),
    @(4, "Stony Field"),
    @(5, "Dark Wood"),
    @(6, "Black Marsh"),
    @(7, "Tamoe Highland"),
    @(8, "Den of Evil"),
    @(9, "Cave 1"),
    @(10, "Underground Passage 1"),
    @(11, "Hole 1"),
    @(12, "Pit 1"),
    @(13, "Cave 2"),
    @(14, "Underground Passage 2"),
    @(15, "Hole 2"),
    @(16, "Pit 2"),
    @(17, "Burial Grounds"),
    @(18, "Crypt"),
    @(19, "Mausoleum"),
    @(20, "Forgotten Tower"),
    @(21, "Tower Cellar 1"),
    @(22, "Tower Cellar 2"),
    @(23, "Tower Cellar 3"),
    @(24, "Tower Cellar 4"),
    @(25, "Tower Cellar 5"),
    @(26, "Monastery Gate"),
    @(27, "Outer Cloister"),
    @(28, "Barracks"),
    @(29, "Jail 1"),
    @(30, "Jail 2"),
    @(31, "Jail 3"),
    @(32, "Inner Cloister"),
    @(33, "Cathedral"),
    @(34, "Catacombs 1"),
    @(35, "Catacombs 2"),
    @(36, "Catacombs 3"),
    @(37, "Catacombs 4"),
    @(38, "Tristram"),
    @(39, "The Secret Cow Level"),
    @(40, "Lut Gholein"),
    @(41, "Rocky Waste"),
    @(42, "Dry Hills"),
    @(43, "Far Oasis"),
    @(44, "Lost City"),
    @(45, "Valley of Snakes"),
    @(46, "Canyon of the Magi"),
    @(47, "Sewers 1"),
    @(48, "Sewers 2"),
    @(49, "Sewers 3"),
    @(50, "Harem 1"),
    @(51, "Harem 2"),
    @(52, "Palace Cellar 1"),
    @(53, "Palace Cellar 2"),
    @(54, "Palace Cellar 3"),
    @(55, "Stony Tomb 1"),
    @(56, "Halls of the Dead 1"),
    @(57, "Halls of the Dead 2"),
    @(58, "Claw Viper Temple 1"),
    @(59, "Stony Tomb 2"),
    @(60, "Halls of the Dead 3"),
    @(61, "Claw Viper Temple 2"),
    @(62, "Maggot Lair 1"),
    @(63, "Maggot Lair 2"),
    @(64, "Maggot Lair 3"),
    @(65, "Ancient Tunnels"),
    @(66, "Tal Rashas Tomb 1"),
    @(67, "Tal Rashas Tomb 2"),
    @(68, "Tal Rashas Tomb 3"),
    @(69, "Tal Rashas Tomb 4"),
    @(70, "Tal Rashas Tomb 5"),
    @(71, "Tal Rashas Tomb 6"),
    @(72, "Tal Rashas Tomb 7"),
    @(73, "Tal Rashas Chamber"),
    @(74, "Arcane Sanctuary"),
    @(75, "Kurast Docks"),
    @(76, "Spider Forest"),
    @(77, "Great Marsh"),
    @(78, "Flayer Jungle"),
    @(79, "Lower Kurast"),
    @(80, "Kurast Bazaar"),
    @(81, "Upper Kurast"),
    @(82, "Kurast Causeway"),
    @(83, "Travincal"),
    @(84, "Archnid Lair"),
    @(85, "Spider Cavern"),
    @(86, "Swampy Pit 1"),
    @(87, "Swampy Pit 2"),
    @(88, "Flayer Dungeon 1"),
    @(89, "Flayer Dungeon 2"),
    @(90, "Swampy Pit 3"),
    @(91, "Flayer Dungeon 3"),
    @(92, "Sewers 1"),
    @(93, "Sewers 2"),
    @(94, "Ruined Temple"),
    @(95, "Disused Fane"),
    @(96, "Forgotten Reliquary"),
    @(97, "Forgotten Temple"),
    @(98, "Ruined Fane"),
    @(99, "Disused Reliquary"),
    @(100, "Durance of Hate 1"),
    @(101, "Durance of Hate 2"),
    @(102, "Durance of Hate 3"),
    @(103, "Pandemonium Fortress"),
    @(104, "Outer Steppes"),
    @(105, "Plains of Despair"),
    @(106, "City of the Damned"),
    @(107, "River of Flame"),
    @(108, "Chaos Sanctuary"),
    @(109, "Harrogath"),
    @(110, "Bloody Foothills"),
    @(111, "Frigid Highlands"),
    @(112, "Arreat Plateau"),
    @(113, "Crystalline Passage"),
    @(114, "Frozen River"),
    @(115, "Glacial Trail"),
    @(116, "Drifter Cavern"),
    @(117, "Frozen Tundra"),
    @(118, "The Ancients Way"),
    @(119, "Icy Cellar"),
    @(120, "Arreat Summit"),
    @(121, "Nihlathaks Temple"),
    @(122, "Halls of Anguish"),
    @(123, "Halls of Pain"),
    @(124, "Halls of Vaught"),
    @(125, "Abaddon"),
    @(126, "Pit of Acheron"),
    @(127, "Infernal Pit"),
    @(128, "Worldstone Keep 1"),
    @(129, "Worldstone Keep 2"),
    @(130, "Worldstone Keep 3"),
    @(131, "Throne of Destruction"),
    @(132, "Worldstone Keep")
)

$d2rAlertZoneIds = @(
    20,  # "Forgotten Tower"
    34,  # "Catacombs 1"
    35,  # "Catacombs 2"
    36,  # "Catacombs 3"
    37,  # "Catacombs 4"
    39,  # "The Secret Cow Level"
    46,  # "Canyon of the Magi"
    73,  # "Tal Rashas Chamber"
    74,  # "Arcane Sanctuary"
    100, # "Durance of Hate 1"
    101, # "Durance of Hate 2"
    102, # "Durance of Hate 3"
    107, # "River of Flame"
    108, # "Chaos Sanctuary"
    121, # "Nihlathaks Temple"
    123, # "Halls of Pain"
    128, # "Worldstone Keep 1"
    129, # "Worldstone Keep 2"
    130, # "Worldstone Keep 3"
    131, # "Throne of Destruction"
    132  # "Worldstone Keep"
)

function GetNextQueryTime {
    $now = Get-Date
    $hourStart = $now.Date.AddHours($now.Hour)
    $t05 = $hourStart.AddMinutes(5)
    $t30 = $hourStart.AddMinutes(30)
    $t35 = $hourStart.AddMinutes(35)

    if ($now -lt $t05) { return $t05 }
    if ($now -lt $t30) { return $t30 }
    if ($now -lt $t35) { return $t35 }
    return $hourStart.AddHours(1)
}

function GetTzInfo {
    $headers = @{
        'x-emu-username' = $script:XEmuUsername
        'x-emu-token'    = $script:XEmuToken
    }
    $response = Invoke-WebRequest -Uri https://d2emu.com/api/v1/tz -Headers $headers
    return $response.Content | ConvertFrom-Json
}

function NotifyDiscord {
    param (
        [ValidateSet("Current", "Next")]
        [string]$Prefix,
        [string[]]$Zones,
        [string[]]$Immunities,
        [string[]]$SuperUniques
    )
    $title = if ($Prefix -eq "Current") { "Current Terror Zones" } else { "Next Terror Zones" }
    $color = if ($Prefix -eq "Current") { 16711680 } else { 65280 } # Red for current, Green for next

    $zoneLines = ($Zones | ForEach-Object { "- $_" }) -join "`n"
    $immunitiesText = $Immunities -join ", "
    $superUniquesText = ($SuperUniques | ForEach-Object { "- $_" }) -join "`n"

    $embed = @{
        title  = $title
        color  = $color
        fields = @(
            @{
                name   = "Zones"
                value  = $zoneLines
                inline = $false
            },
            @{
                name   = "Immunities"
                value  = $immunitiesText
                inline = $true
            },
            @{
                name   = "Superuniques"
                value  = $superUniquesText
                inline = $false
            }
        )
    }

    $webhook = $script:DiscordWebhookUrl
    $body = @{ embeds = @($embed) } | ConvertTo-Json -Depth 6 -Compress
    Invoke-RestMethod -Uri $webhook -Method Post -Body $body -ContentType 'application/json'
}

function GetFilteredZoneNames {
    param (
        [string[]]$Zones,
        [switch]$IgnoreFilter
    )

    $alertZones = @()
    foreach ($zone in $Zones) {
        if ($d2rAlertZoneIds -contains $zone -or $IgnoreFilter) {
            $alertZones += $d2rZoneIds[$zone][1]
        }
    }
    if ($alertZones) {
        return $alertZones
    }
    return $null
}

function CreateTzMessage {
    param (
        [ValidateSet("Current", "Next")]
        [string]$Prefix,
        [string[]]$Zones,
        [string[]]$Immunities,
        [string[]]$SuperUniques
    )

    if (-not $Zones) {
        return ""
    }

    $prefixText = if ($Prefix -eq "Current") { "Current Terror Zones:" } else { "Next Terror Zones:" }
    return @"
$(Get-Date -Format G) $prefixText
  $($Zones -join "`n  ")

Immunities: $($Immunities -join ", ")

Superuniques: $($SuperUniques -join ", ")

"@
}

if ($DumpInfo) {
    $tzInfo = GetTzInfo
    $tzInfo
    $zones = GetFilteredZoneNames -Zones $tzInfo.current -IgnoreFilter
    $tzCurrentMessage = CreateTzMessage -Prefix Current -Zones $zones -Immunities $tzInfo.current_immunities -SuperUniques $tzInfo.current_superuniques

    $nextZones = GetFilteredZoneNames -Zones $tzInfo.next -IgnoreFilter
    $tzNextMessage = CreateTzMessage -Prefix Next -Zones $nextZones -Immunities $tzInfo.next_immunities -SuperUniques $tzInfo.next_superuniques

    Write-Host $tzCurrentMessage -ForegroundColor DarkRed
    Write-Host $tzNextMessage -ForegroundColor Green

    if ($SendToDiscord) {
        NotifyDiscord -Prefix Current -Zones $zones -Immunities $tzInfo.current_immunities -SuperUniques $tzInfo.current_superuniques
        NotifyDiscord -Prefix Next -Zones $nextZones -Immunities $tzInfo.next_immunities -SuperUniques $tzInfo.next_superuniques
    }
    return
}

do {
    $now = Get-Date
    $tzInfoFile = "$PSScriptRoot\tzInfo.json"

    if ($now.Minute -le 01 -or ($now.Minute -ge 30 -and $now.Minute -le 31)) {
        if (Test-Path -Path $tzInfoFile) {
            $tzInfo = Get-Content -Path $tzInfoFile | ConvertFrom-Json
            $tzInfo.current = $tzInfo.next
            $tzInfo.current_immunities = $tzInfo.next_immunities
            $tzInfo.current_superuniques = $tzInfo.next_superuniques
            Remove-Item -Path $tzInfoFile -Force
        }
        else
        {
            Start-Sleep -Seconds 65
            $tzInfo = GetTzInfo
        }

        $zones = GetFilteredZoneNames -Zones $tzInfo.current
        if ($zones) {
            if ($SendToDiscord) {
                NotifyDiscord -Prefix Current -Zones $zones -Immunities $tzInfo.current_immunities -SuperUniques $tzInfo.current_superuniques
            }
            else {
                $tzCurrentMessage = CreateTzMessage -Prefix Current -Zones $zones -Immunities $tzInfo.current_immunities -SuperUniques $tzInfo.current_superuniques
                Write-Host $tzCurrentMessage -ForegroundColor DarkRed
            }
        }
    }
    else {
        $tzInfo = GetTzInfo
        $zones = GetFilteredZoneNames -Zones $tzInfo.next
        if ($zones) {
            $tzInfo | ConvertTo-Json | Out-File -FilePath $tzInfoFile -Force
            if ($SendToDiscord) {
                NotifyDiscord -Prefix Next -Zones $zones -Immunities $tzInfo.next_immunities -SuperUniques $tzInfo.next_superuniques
            }
            else {
                $tzNextMessage = CreateTzMessage -Prefix Next -Zones $zones -Immunities $tzInfo.next_immunities -SuperUniques $tzInfo.next_superuniques
                Write-Host $tzNextMessage -ForegroundColor Green
            }
        }
    }

    if ($RunOnce) { break }
    Start-Sleep -Seconds (((GetNextQueryTime) - (Get-Date)).TotalSeconds + 1)
} while ($true)
