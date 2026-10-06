# jack-the-ripper

Random horror event for RSG-Core (RedM). Every 10 minutes at night, a small knife-wielding
NPC ("Jack") spawns near a random online player and hunts them. The weather turns to
**thunderstorm + dark** for everyone, then restores when the event ends.

## Behavior
- **Timer:** every 10 min (`Config.MinInterval / MaxInterval = 10 min`), only if 1+ player online
- **Night only:** 21:00–04:00, checked client-side via `GetClockHours` (`Config.ActiveHours`)
- **Random player:** server picks 1 random online player per event (`RSGCore.Functions.GetPlayers()`)
- **Restore after:** `weathersync` personal override (`setMyWeather` / `setMyTime`) for the
  storm + midnight, `setSyncEnabled(true)` to restore; falls back to natives if weathersync
  isn't running
- **Killable normal:** normal HP, `TaskCombatPed` with `WEAPON_MELEE_KNIFE`, ends on kill /
  5 min timeout / victim death / target disconnect / admin stop
- **Damage:** `JackDamageMultiplier = 2.0` (AI melee + weapon modifier, restored after event).
  Raise to 3.0–4.0 for deadlier, lower to 1.0 for a vanilla knife.

## Install
1. Copy `jack-the-ripper` to `resources/[framework]/`.
2. In `server.cfg` (after rsg-core, ox_lib, weathersync):
   ```
   ensure weathersync
   ensure jack-the-ripper
   ```
3. Restart server (a resource restart is enough for updates, but NUI/audio changes need one too).

## Files
```
fxmanifest.lua      manifest + ui_page + files (html, jack.mp3)
config.lua          all tuning (timer, ped, damage, weather, sound)
client/client.lua   weather, spawn/combat, damage boost, sounds, watchdogs
server/server.lua   60s scheduler, random target, net-id relay, admin commands
html/index.html     NUI audio player for jack.mp3
jack.mp3            bundled scare sound (replace with your own file, same name)
```

## Config (`config.lua`)
- `MinInterval / MaxInterval`: both 10 min by default
- `JackModels`: tried in order, first **visible** one wins (spawn → outfit → visibility check).
  Defaults are proven-visible ambients scaled to `JackPedScale = 0.75` for a child-like size,
  `CS_JackMarston` last. `JackOutfit = 0` fixes invisible `CS_` peds.
- `Weapon`: `WEAPON_MELEE_KNIFE` | `Lifetime`: 5 min | `RetaskInterval`: 2s (relentless)
- `WeatherType = 'thunderstorm'`, `DarkHour = 0`, `WeatherTransition = 30.0`
- `ShowBlip`: optional red blip (same native as rex-zombies)

## Sound
Three layers (all can run together):
1. **Bundled mp3 (main scare, works out of the box):** `jack.mp3` in the resource root plays
   via the NUI page — once for **everyone** on event start, then every `ChaseInterval`
   (**10s**) for **anyone within `ProximityRange` (60m)** of Jack (victim + bystanders).
   Swap the file for your own scare (keep the name, or update `html/index.html`).
   Tune with `Config.Sound.UseNui` / `NuiVolume`.
2. **Native sting** (verified against
   [femga/rdr3_discoveries](https://github.com/femga/rdr3_discoveries/tree/master/audio/frontend_soundsets)
   + [Nowimps8 RedM list](https://github.com/Nowimps8/RedM-info/blob/master/FrontEndSounds.lua),
   called as `PlaySoundFrontend(-1, name, set, true)` with bank preload `0x0F2A2175734926D8`):
   start plays `DEATH_SCREEN_ENTER` / `DEATH_FAIL_RESPAWN_SOUNDS` for everyone, victim hears
   `Heartbeat` / `RDRO_Sniper_Tension_Sounds` on the chase loop. Alternatives:
   `sudden_death`, `OOB_death`, `FAIL`, `LeavingColter6_Gust`, `Strike_Heavy`, `Wanted_Spotted`.
3. **Custom .ogg (optional):** drop files into
   `resources/[standalone]/interact-sound/client/html/sounds/` (your `xsound` emulates the
   same `InteractSound_SV` events), set `Config.Sound.UseCustom = true`.

## Commands
- `jack_start [id]` — force start (admin)
- `jack_stop` — stop + restore weather/sound (admin)

## Notes
- If Jack is ever invisible again, enable `Config.Debug = true` + `Config.ShowBlip = true` and
  check F8: a moving blip means the ped exists but the mesh failed — change `Config.JackModels`.
- If you use a different weather resource than `weathersync`, set `Config.UseWeathersync = false`.
