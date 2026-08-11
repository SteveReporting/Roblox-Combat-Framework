--!strict

return {
    MaxShieldStamina = 100,
    ShieldRegenPerSecond = 14,
    ShieldRegenDelay = 1.25,

    Guard = {
        FrontDotThreshold = 0.15,
        DamageStaminaCost = 24,
        BrokenGuardStun = 1.5,
    },

    Attacks = {
        Slash = {
            Damage = 24,
            Range = 7,
            ArcDotThreshold = -0.15,
            Cooldown = 0.75,
            ActiveTime = 0.32,
        },
        Stab = {
            Damage = 30,
            Range = 8.5,
            ArcDotThreshold = 0.45,
            Cooldown = 0.95,
            ActiveTime = 0.28,
        },
        Kick = {
            Damage = 6,
            Range = 5.5,
            ArcDotThreshold = 0.2,
            Cooldown = 20,
            ShieldStaminaDamage = 40,
            OpenTargetStun = 2,
            ActiveTime = 0.45,
        },
    },
}
