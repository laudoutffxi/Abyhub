# abyhub

An Abyssea + Empyrean toolkit addon for **Ashita v4** (Final Fantasy XI), styled after YunaGearOpt (flat navy, periwinkle accent, Segoe UI).

## Install

1. Download this repository (green **Code** button → **Download ZIP**) and unzip it.
2. Copy the `abyhub` folder into your `Ashita/addons/` folder.
3. In game: `/addon load abyhub`, then `/aby` to open the window.

To load it automatically, add `/addon load abyhub` to your Ashita startup script. Nothing else is needed.

## Tabs

- **KEY ITEMS**: Abyssea pop key items per zone and boss, for Vision, Scars and Heroes. It follows you into the zone you're in. Shows READY when a boss can be popped. Hover a key item to see which NM drops it.
- **STAGGERS**: your target, the Vana'diel clock and the blue weakness window, plus the red / blue / yellow stagger lists. Spells are coloured by element. A big popup shows when a stagger lands.
- **ATMA**:
  - Atma per expansion and zone, following you into the zone you enter.
  - Other atma and abyssites.
  - Hover an atma to see its effects and where it comes from.
  - Hover an abyssite to see what it does.
- **EMPYREAN**. The job pill on the right follows your main job; click it to pick any job.
  - **ARMOR**: Base / +1 / +2 stats per slot, with seal and +2 material counts from your bags.
  - **NMS**: the Abyssea NMs that drop each seal or +2 item, with drop rates and estimated kills.
  - **WEAPONS**: Empyrean weapon Magian trials (CatsEyeXI paths). Your current trial is detected automatically from the weapon in your bags.
    - STAGES: the full 10-trial path. In the weapon list, a green light means you have the Empyrean and a yellow light means you're working on it.
    - COMPLETED: the Empyreans you've finished.

The **lights bar** (Abyssea lights and visitant time) is its own small window. It appears automatically when you enter an Abyssea zone and hides when you leave. `/abylights` turns that on or off.

The header shows the character you're logged in as (name plus main / sub job), so it's clear which character's data you're looking at.

Drag either window by any empty part of it. Resize the main window from its bottom-right corner. It remembers its size, can't be made narrower than its layout needs, and can't be stretched past the game window. `/aby reset` re-centres it and fits it to the content again.

## Commands

```
/aby                          show / hide the window
/aby ki | stagger | atma | empyrean     open a tab
/aby armor | nms | weapons [stages|completed]     Empyrean views
/aby job <JOB|auto>           Empyrean: show a job (auto = follow main job)
/aby refresh                  Empyrean: rescan bags now
/aby compact                  compact view (staggers / armour)
/aby all                      staggers: show every blue / yellow window
/aby alerts [target|any|off]  stagger popups
/aby test [red|yellow|blue|white]    test a stagger popup
/aby reset                    re-centre and re-fit the window
/aby help                     list commands

/abylights                    auto lights bar on / off
/abylights print              lights to chat
```

## Notes

- **Key item tabs:** these need key item data from the server. If a tab says *waiting for key item data*, zone once after loading the addon.
- **Lights and visitant time:** read from `/heal` in Abyssea, and estimated between checks.
- **Saved settings:** the addon writes `abyhub_settings.lua` (tab, window size, lights bar), `abyhub_empyrean.lua` and `lights_<character>.lua` into its own folder. Delete them to reset.
- **Font:** uses Segoe UI from your Windows Fonts folder (nothing is bundled). If it can't be loaded, the game's ImGui font is used.

## Files

| file | what |
|---|---|
| `abyhub.lua` | main addon: windows, commands, Abyssea tabs, lights, stagger popups |
| `abyempy.lua` | Empyrean tab |
| `abytheme.lua` | drawing / colours (edit the `HUD` table to recolour) |
| `abyatma.lua` | atma names, sources and effects |
| `empydata.lua` | Empyrean armour stats and NM drop data |
| `empyweapons.lua` | Empyrean weapon trial paths |

## Data sources

- Abyssea key items and atma: [LandSandBoat](https://github.com/LandSandBoat/server).
- Atma effects: [bg-wiki](https://www.bg-wiki.com/ffxi/Category:Abyssea_Atma).
- Abyssite descriptions: [FFXIclopedia](https://ffxiclopedia.fandom.com/wiki/Category:Abyssite).
- Item names and stats: retail client text via [Windower Resources](https://github.com/Windower/Resources). NM drop rates: retail kill tracking.
- Empyrean weapon trials: [bg-wiki CatsEyeXI](https://www.bg-wiki.com/ffxi/CatsEyeXI_Systems/Empyrean_Weapon).

Author: Laudout
