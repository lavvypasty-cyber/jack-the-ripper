Config = {}

Config.MinInterval = 60 * 60 * 1000
Config.MaxInterval = 60 * 60 * 1000
Config.MinPlayers = 1
Config.ActiveHours = { [21] = true, [22] = true, [23] = true, [0] = true, [1] = true, [2] = true, [3] = true, [4] = true }
Config.Debug = false
Config.DayRetryInterval = 10 * 60 * 1000
Config.JoinGrace = 10 * 60 * 1000

Config.JackModels = {
    `A_M_M_UniCorpse_01`,
    `A_M_M_ArmCholeraCorpse_01`,
    `CS_JackMarston`,
}
Config.JackOutfit = 0
Config.JackPedScale = 0.75
Config.Weapon = `WEAPON_MELEE_KNIFE`
Config.JackDamageMultiplier = 2.0
Config.Lifetime = 5 * 60 * 1000
Config.RetaskInterval = 2000
Config.SeeingRange = 60.0
Config.HearingRange = 100.0
Config.SpawnDistanceMin = 20.0
Config.SpawnDistanceMax = 25.0
Config.ChaseSpeed = 1.0
Config.ShowBlip = false
Config.BlipSprite = -839369609

Config.WeatherType = 'thunderstorm'
Config.WeatherTransition = 30.0
Config.DarkHour = 0
Config.DarkMinute = 0
Config.UseWeathersync = true
Config.NotifyOnStart = true

Config.Sound = {
    Enabled = true,
    UseNui = true,
    NuiVolume = 0.8,
    NativeName = 'DEATH_SCREEN_ENTER',
    NativeSet = 'DEATH_FAIL_RESPAWN_SOUNDS',
    ChaseName = 'Heartbeat',
    ChaseSet = 'RDRO_Sniper_Tension_Sounds',
    UseCustom = false,
    StartFile = 'jack_sting',
    ChaseFile = 'jack_laugh',
    CustomVolume = 0.8,
    ChaseInterval = 60000,
    VoiceInterval = 60000,
    ProximityRange = 60.0,
}
