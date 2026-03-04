#crontab -e
#run At minute 0, 5, 30, and 35 past every hour from 8 through 22
#00,05,30,35 8-22 * * * pwsh -File /home/<username>/scripts/CheckTzAndAlertDiscord.ps1 -SendToDiscord -RunOnce

param(
    [switch]$DumpInfo,
    [switch]$SendToDiscord,
    [switch]$RunOnce
)

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
    110, # "Bloody Foothills"
    111, # "Frigid Highlands"
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
        'x-emu-username' = ''
        'x-emu-token'    = ''
    }
    $response = Invoke-WebRequest -Uri https://d2emu.com/api/v1/tz -Headers $headers
    return $response.Content | ConvertFrom-Json
}

function NotifyDiscord {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)][string]$Message
    )
    $webhook = "https://discord.com/api/webhooks/"
    $body = @{ 'content' = $Message } | ConvertTo-Json -Compress
    Invoke-RestMethod -Uri $webhook -Method Post -Body $body -ContentType 'application/json'
}

function FormatFilteredTzMessage {
    param (
        [string[]]$Zones,
        [string[]]$Immunities,
        [string[]]$SuperUniques,
        [switch]$IgnoreFilteredZones
    )

    $alertZones = @()
    foreach ($zone in $Zones) {
        if ($d2rAlertZoneIds -contains $zone -or $IgnoreFilteredZones) {
            $alertZones += $d2rZoneIds[$zone][1]
        }
    }
    if ($alertZones) {
        return "  $($alertZones -join "`n  ")`n`nImmunities: $($Immunities -join ", ")`n`nSuperuniques: $($SuperUniques -join ", ")`n"
    }
    return ""
}

if ($DumpInfo) {
    $tzInfo = GetTzInfo
    $tzInfo
    $currentMessage = FormatFilteredTzMessage -Zones $tzInfo.current -Immunities $tzInfo.current_immunities -SuperUniques $tzInfo.current_superuniques -IgnoreFilteredZones
    $tzCurrentMessage = "Current Terror Zones:`n$currentMessage"

    $nextMessage = FormatFilteredTzMessage -Zones $tzInfo.next -Immunities $tzInfo.next_immunities -SuperUniques $tzInfo.next_superuniques -IgnoreFilteredZones
    $tzNextMessage = "Next Terror Zones:`n$nextMessage"
    if ($SendToDiscord) {
        NotifyDiscord -Message $tzCurrentMessage
        NotifyDiscord -Message $tzNextMessage
    }
    else {
        Write-Host $tzCurrentMessage -ForegroundColor Green
        Write-Host $tzNextMessage -ForegroundColor DarkRed
    }
    return
}

do {
    $now = Get-Date
    $tzInfo = GetTzInfo

    if ($now.Minute -eq 0 -or $now.Minute -eq 30) {
        $alertMessage = FormatFilteredTzMessage -Zones $tzInfo.current -Immunities $tzInfo.current_immunities -SuperUniques $tzInfo.current_superuniques
        if ($alertMessage) {
            $tzMessage = "Current Terror Zone:`n$alertMessage"
            if ($SendToDiscord) {
                NotifyDiscord -Message $tzMessage
            }
            else {
                Write-Host $tzMessage
            }
        }
    }
    else {
        $alertMessage = FormatFilteredTzMessage -Zones $tzInfo.next -Immunities $tzInfo.next_immunities -SuperUniques $tzInfo.next_superuniques
        if ($alertMessage) {
            $tzMessage = "Next Terror Zone:`n$alertMessage"
            if ($SendToDiscord) {
                NotifyDiscord -Message $tzMessage
            }
            else {
                Write-Host $tzMessage
            }
        }
    }

    if ($RunOnce) { break }
    Start-Sleep -Seconds ((GetNextQueryTime) - (Get-Date)).TotalSeconds
} while ($true)
