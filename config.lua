Config = {}

---------------------------------
-- event scheduling (night only)
---------------------------------
Config.MinInterval = 10 * 60 * 1000 -- min ms between auto events (10 min)
Config.MaxInterval = 10 * 60 * 1000 -- max ms between auto events (10 min)
Config.MinPlayers = 1 -- minimum online players to trigger
Config.ActiveHours = { [21] = true, [22] = true, [23] = true, [0] = true, [1] = true, [2] = true, [3] = true, [4] = true }
Config.Debug = false

Config.JackModels = {
    `A_M_M_UniCorpse_01`,
    `A_M_M_ArmCholeraCorpse_01`,
    `CS_JackMarston`,
}
Config.JackOutfit = 0 
Config.JackPedScale = 0.75 -- 1.0 = normal, <1.0 = smaller (child-like)
Config.Weapon = `WEAPON_MELEE_KNIFE`
Config.JackDamageMultiplier = 2.0 
Config.Lifetime = 5 * 60 * 1000 
Config.RetaskInterval = 2000 
Config.SeeingRange = 60.0
Config.HearingRange = 100.0
Config.SpawnDistanceMin = 30.0 
Config.SpawnDistanceMax = 50.0 
Config.ChaseSpeed = 1.0 
Config.ShowBlip = false 
Config.BlipSprite = -839369609

---------------------------------
-- horror weather (foggy + dark, restored after)
---------------------------------
Config.WeatherType = 'thunderstorm' -- RDR weathersync type: thunderstorm / thunder / rain (was fog)
Config.WeatherTransition = 30.0 -- seconds for fog to roll in
Config.DarkHour = 0 -- force midnight during event
Config.DarkMinute = 0
Config.UseWeathersync = true -- use weathersync personal override if resource started, else natives
Config.NotifyOnStart = true


Config.Sound = {
    Enabled = true,
    UseNui = true, -- plays jack.mp3 bundled in this resource (no setup needed)
    NuiVolume = 0.8,
    NativeName = 'DEATH_SCREEN_ENTER',
    NativeSet = 'DEATH_FAIL_RESPAWN_SOUNDS',
    ChaseName = 'Heartbeat',
    ChaseSet = 'RDRO_Sniper_Tension_Sounds',
    UseCustom = false, -- set true after adding the .ogg files below
    StartFile = 'jack_sting', -- event start sting (everyone hears own copy)
    ChaseFile = 'jack_laugh', -- creepy loop while jack hunts (target only)
    CustomVolume = 0.8,
    ChaseInterval = 10000, -- ms between chase sounds (every 10s)
    ProximityRange = 60.0, -- anyone within this many meters of Jack hears the repeat
}
