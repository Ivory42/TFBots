#include "logic/heavy.sp"
#include "logic/demoman.sp"
#include "logic/scout.sp"
#include "logic/sniper.sp"
#include "logic/soldier.sp"
#include "logic/pyro.sp"
#include "logic/medic.sp"
#include "logic/spy.sp"
#include "logic/engineer.sp"

public Action OnPlayerRunCmd(int clientId, int& buttons, int& impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    ACustomBot bot = FBotStatics.GetPlayerAsBot(clientId);
    if (bot)
    {
        if (bot.Alive())
        {
            char debug[256];
            //buttons = 0;
            //vel = {0.0, 0.0, 0.0};
            FRotator eyeangle; //oldangle;
            eyeangle.Set(angles);
            //oldangle = eyeangle;
            
            FVector velocity;
            velocity.Set(vel);

            /*****
            
            Generic behavior for all bot types
            
            ******/

            TFClassType class = TF2_GetPlayerClass(bot.Get());
            float speed = GetVectorLength(vel, false);

            if (speed <= 60.0)
            {
                DoStutterStep(bot, velocity, class);
            }

            if (GetHealth(bot) <= 50 && bot.CallMedicDelay <= GetGameTime())
            {
                FakeClientCommand(bot.Get(), "voicemenu 0 0");
                bot.CallMedicDelay = GetGameTime() + GetRandomFloat(5.0, 35.0);
            }

            if (!(class == TFClass_Sniper && bot.InCondition(TFCond_Slowed)))
            {
                // Set bot FOV so spectating isn't nauseating
                bot.SetProp(Prop_Send, "m_iFOV", 90);
                bot.SetProp(Prop_Send, "m_iDefaultFOV", 90);
            }

            // Tell if our bot is currently trying to attack
            bot.Attacking = (buttons & IN_ATTACK) != 0;

            if (bot.TimerExpired("TFBot.AmmoRefreshTimer"))
            {
                RefreshAmmo(bot, GetPlayerWeaponSlot(bot.Get(), TFWeaponSlot_Primary), GetPlayerWeaponSlot(bot.Get(), TFWeaponSlot_Secondary));
            }

            if (bot.TimerExpired("TFBot.JumpTimer"))
            {
                buttons |= IN_JUMP;
                if (class == TFClass_Scout)
                {
                    if (!bot.ScoutSingleJump)
                    {
                        bot.SetTimer("TFBot.Scout.DoubleJumpTimer", ConstructTimer(GetRandomFloat(0.1, 0.25), false, false, true));
                    }
                }
            }
            if (bot.TimerExpired("TFBot.Scout.DoubleJumpTimer"))
            {
                buttons |= IN_JUMP;
            }

            if (!CastToClient(bot.GetCurrentTarget()).Alive())
            {
                bot.SetCurrentTarget(GetWorld());
            }

            // Target acquisition
            FObject target;
            target = bot.GetCurrentTarget();
            if (bot.NextAggroTime <= GetGameTime())
            {
                target = SelectBestTarget(bot, eyeangle, class);
                if (target.Valid())
                {
                    StrCat(debug, sizeof debug, "Target is Valid\n");
                    bot.SetCurrentTarget(target);
                    bot.NextAggroTime = GetGameTime() + bot.GetAggroDelay();
                }
            }

            if (TargetIsValid(bot, target))
            {
                StrCat(debug, sizeof debug, "Target is valid\n");
                FVector targpos, botpos;
                targpos = target.GetPosition();
                botpos = bot.GetPosition();

                bot.Fleeing = ShouldBotFlee(bot);
                bot.NavDelayTimeout = GetGameTime() + 3.0;

                float distance = botpos.DistanceTo(targpos);

                FBotLogicInfo info;
                info = InitializeBotLogicInfo();

                info.Primary = ConstructObject(GetPlayerWeaponSlot(bot.Get(), TFWeaponSlot_Primary));
                if (info.Primary.Valid())
                {
                    info.PrimaryIndex = info.Primary.GetProp(Prop_Send, "m_iItemDefinitionIndex");
                }
                info.Secondary = ConstructObject(GetPlayerWeaponSlot(bot.Get(), TFWeaponSlot_Secondary));
                if (info.Secondary.Valid())
                {
                    info.SecondaryIndex = info.Secondary.GetProp(Prop_Send, "m_iItemDefinitionIndex");
                }
                info.Melee = ConstructObject(GetPlayerWeaponSlot(bot.Get(), TFWeaponSlot_Melee));
                if (info.Melee.Valid())
                {
                    info.MeleeIndex = info.Melee.GetProp(Prop_Send, "m_iItemDefinitionIndex");
                }
                info.ActiveWeapon = bot.GetPropEnt(Prop_Send, "m_hActiveWeapon");
                if (info.ActiveWeapon.Valid())
                {
                    info.ActiveIndex = info.ActiveWeapon.GetProp(Prop_Send, "m_iItemDefinitionIndex");
                }

                if (!bot.Fleeing && class != TFClass_Sniper && class != TFClass_Medic && BotCanAttack(bot, class))
                {
                    StrCat(debug, sizeof debug, "Not fleeing\n");
                    if (distance > bot.GetAttackRange() && AcceptableAngle(bot, target) && !bot.InCaptureArea)
                    {
                        StrCat(debug, sizeof debug, "Outside Attack Range. Moving Forward\n");
                        ForceBotMovement(true, false, false, false, velocity, GetPlayerMaxSpeed(bot, false));
                    }
                    switch (class)
                    {
                        case TFClass_Heavy: Heavy_OnCombatTick(bot, target, buttons);
                        case TFClass_DemoMan: Demo_OnCombatTick(bot, target, buttons, distance);
                        case TFClass_Scout: Scout_OnCombatTick(bot, target, buttons, distance, velocity, class, info);
                        case TFClass_Pyro: Pyro_OnCombatTick(bot, buttons, distance, info);
                    }
                }
                else if (bot.Fleeing && !Demo_IsDemoKnight(bot))
                {
                    switch (class)
                    {

                    }
                }
            }
            else if (IsControlPoints() && Captures >= 1)
            {

            }
            else
            {
                if (class == TFClass_DemoMan && BotHasShield(bot))
                {
                    buttons |= ~IN_ATTACK2;
                }
            }

            // Target-agnostic logic
            switch (class)
            {

            }

            vel = velocity.ToFloat();
            //PrintCenterTextAll(debug);
        }
    }

    return Plugin_Continue;
}

public Action TF2_CalcIsAttackCritical(int clientId, int weaponId, char[] weaponname, bool& result)
{
    ACustomBot bot = FBotStatics.GetPlayerAsBot(clientId);
    if(bot)
    {
        int weaponIndex = ConstructObject(weaponId).GetProp(Prop_Send, "m_iItemDefinitionIndex");
        switch (bot.Class)
        {
            case TFClass_Scout:
            {
                if (bot.NextAimTime <= GetGameTime())
                {
                    SetTargetViewAngles(bot);
                    bot.NextAimTime = GetGameTime() + bot.GetAimDelay();
                }
            }
            case TFClass_Soldier:
            {
                if (weaponIndex == 237)
                {
                    return Plugin_Continue;
                }
            }
        }
    }

    return Plugin_Continue;
}

FObject SelectBestTarget(ACustomBot bot, FRotator angle, TFClassType class)
{
    FVector position;
    float fov = bot.GetAimFOV();

    position = bot.GetEyePosition();
    FObject target;

    FVector visiblepos;
    float nearest;
    float maxdistance = 8192.0;
    float closestDistance = maxdistance;

    ArrayList clients = FEntityStatics.GetConnectedClients();
    for (int i = 0; i < clients.Length; i++)
    {
        AClient client = clients.Get(i);
        if (client == bot)
        {
            continue;
        }

        if (!TargetIsValid(bot, client.GetObject()))
        {
            continue;
        }

        visiblepos = client.GetEyePosition();
        visiblepos.Z -= 40.0;

        nearest = FMath.GetAngle(angle, FMath.CalcRotator(position, visiblepos));
        if (nearest > fov)
        {
            continue;
        }
        
        float distance = position.DistanceTo(visiblepos);
        if (class != TFClass_Sniper) // Check distance on non-snipers
        {
            if (distance > maxdistance)
            {
                continue;
            }
        }

        if (FloatAbs(fov - nearest) < 5.0) // For targets that are very close in fov, check our distance to see which is a better target
        {
            if (distance < closestDistance)
            {
                if (CheckVisionTrace(bot, client.GetObject()))
                {
                    fov = nearest;
                    closestDistance = distance;
                    target = client.GetObject();
                }
            }
        }
        else if (nearest < fov)
        {
            if (CheckVisionTrace(bot, client.GetObject()))
            {
                fov = nearest;
                closestDistance = distance;
                target = client.GetObject();
            }
        }
    }

    if (target.Valid())
    {
        return target;
    }
    
    return GetWorld(); // Return world to flag invalid target
}

bool CheckVisionTrace(AClient attacker, FObject target, bool debug = false)
{
    if (!target.Valid())
    {
        if (debug)
        {
            PrintBotDebug(attacker, false, "Vision Trace: Target is invalid");
        }
        return false;
    }

    bool result = false;
    FVector start, end;
    FClient client;
    client = CastToClient(target);

    start = attacker.GetEyePosition();

    if (client.Valid())
    {
        end = client.GetEyePosition();
    }
    else
    {
        end = target.GetPosition();
        end.Z += 40.0;
    }

    FRayTraceSingle trace = new FRayTraceSingle(start, end, MASK_PLAYERSOLID, IgnoreTeamFilter, attacker);
    if (trace.DidHit())
    {
        if (debug)
        {
            PrintBotDebug(attacker, false, "Vision Trace hit entity: %d\nTarget: %d", trace.GetHitEntity().Get(), target.Get());
        }
        FObject hit;
        hit = trace.GetHitEntity();
        if (hit.Valid() && hit.Get() == target.Get())
        {
            result = true;
        }
    }
    else
    {
        PrintBotDebug(attacker, false, "Vision Trace: Trace did not hit");
    }
    delete trace;
    return result;
}

bool IgnoreTeamFilter(int entityId, int mask, AClient attacker)
{
    if (ConstructClient(entityId).Valid())
	{
        return TF2_GetClientTeam(entityId) != attacker.Team;
	}

	return true;
}

void DoStutterStep(ACustomBot bot, FVector velocity, TFClassType class, float delay = 0.0)
{
    if (bot.GetProficiency() < 3)
    {
        // Bots below proficiency 3 will not stutter step
        return;
    }

    if (bot.StepDelay <= GetGameTime())
    {
        if (GetRandomInt(1, 2) == 1)
        {
            bot.StrafeSpeed = GetPlayerMaxSpeed(bot, false) * -1.0;
        }
        else
        {
            bot.StrafeSpeed = GetPlayerMaxSpeed(bot, false);
        }

        if (class == TFClass_Sniper && bot.InCondition(TFCond_Slowed))
        {
            if (bot.GetProficiency() >= 5)
            {
                if (TargetIsValid(bot, bot.GetCurrentTarget()))
                {
                    bot.StepDelay = GetGameTime() + GetRandomFloat(0.1, 0.4);
                }
                else
                {
                    return;
                }
            }
            else
            {
                return;
            }
        }
        else
        {
            bot.StepDelay = GetGameTime() + ((delay > 0.0) ? delay : GetStrafeTime(bot, false));
        }
    }
    ForceBotMovement(false, false, true, false, velocity, bot.StrafeSpeed);
}

float GetStrafeTime(ACustomBot bot, bool scout)
{
    switch (bot.GetProficiency())
    {
        case 0, 1, 2, 3: GetRandomFloat(8.0, 12.0);
        case 4: GetRandomFloat(1.2, 2.0);
        case 5, 6, 7:
        {
            if (scout)
            {
                return GetRandomFloat(0.8, 1.2);
            }
            else
            {
                return GetRandomFloat(0.4, 0.8);
            }
        }
        default:
        {
            if (scout)
            {
                return GetRandomFloat(0.3, 0.6);
            }
            else
            {
                GetRandomFloat(0.2, 0.45);
            }
        }
    }
    return 10.0;
}

bool TargetIsValid(ACustomBot bot, FObject target)
{
    if (!target.Valid())
    {
        return false;
    }

    if (bot.Get() == target.Get())
    {
        return false;
    }

    FClient client;
    client = CastToClient(target);
    if (client.Valid())
    {
        if (!client.Alive())
        {
            return false;
        }

        if (bot.Team == TF2_GetClientTeam(client.Get()))
        {
            return false;
        }

        if (client.InCondition(TFCond_Ubercharged) || client.InCondition(TFCond_UberchargedCanteen) ||
            client.InCondition(TFCond_Cloaked) || client.InCondition(TFCond_Stealthed) ||
            client.InCondition(TFCond_StealthedUserBuffFade) || client.InCondition(TFCond_Bonked))
        {
            return false;
        }

        if (client.InCondition(TFCond_Disguised))
        {
            if (bot.GetProficiency() < 4)
            {
                return false;
            }

            FObject disguise;
            disguise = client.GetObject().GetPropEnt(Prop_Send, "m_hDisguiseTarget");
            if (disguise.Valid())
            {
                return (bot.Get() == disguise.Get())
            }

            if (NearTeammates(client)) // Disguised spies lingering around enemy team members should be easily discovered
            {
                return true;
            }
        }

        if (client.GetObject().GetProp(Prop_Data, "m_takedamage") != 2)
        {
            return false;
        }

        return true;
    }

    return false;
}

bool NearTeammates(FClient client)
{
	int count = 0;
	FVector pos, playerpos;
	pos = client.GetPosition();
    ArrayList clients = FEntityStatics.GetConnectedClients();
    for (int i = 0; i < clients.Length; i++)
    {
        AClient test = clients.Get(i);
        if (test && test.Get() != client.Get() && test.Team == view_as<TFTeam>(client.GetTeam()))
        {
            playerpos = test.GetPosition();
            if (pos.DistanceTo(playerpos) < 300.0)
            {
                count++;
            }
        }
    }
	return (count > 2);
}

void RefreshAmmo(ACustomBot bot, int primaryId, int secondaryId)
{
    FObject primary, secondary;
    primary = ConstructObject(primaryId);
    secondary = ConstructObject(secondaryId);

    int ammotype = 1;
    // Check primary and make sure it is a weapon with a clip
    if (primary.Valid())
    {
        if (primary.HasProp(Prop_Send, "m_iClip1"))
        {
            int clip = bot.GetPreservedClip(TFWeaponSlot_Primary);
            if (clip > 0)
            {
                primary.SetProp(Prop_Send, "m_iClip1", clip);
            }
        }

        int ammo = bot.GetPreservedAmmo(TFWeaponSlot_Primary);
        if (ammo > 0)
        {
            bot.SetProp(Prop_Send, "m_iAmmo", ammo, ammotype);
        }

        bot.SetPreservedAmmo(0, TFWeaponSlot_Primary);
        bot.SetPreservedClip(0, TFWeaponSlot_Primary);
    }

    // repeat for secondary
    ammotype = 2
    if (secondary.Valid())
    {
        if (secondary.HasProp(Prop_Send, "m_iClip1"))
        {
            int clip = bot.GetPreservedClip(TFWeaponSlot_Secondary);
            if (clip > 0)
            {
                secondary.SetProp(Prop_Send, "m_iClip1", clip);
            }
        }

        int ammo = bot.GetPreservedAmmo(TFWeaponSlot_Secondary);
        if (ammo > 0)
        {
            bot.SetProp(Prop_Send, "m_iAmmo", ammo, ammotype);
        }

        bot.SetPreservedAmmo(0, TFWeaponSlot_Secondary);
        bot.SetPreservedClip(0, TFWeaponSlot_Secondary);
    }
}

void TryKeepSlot(ACustomBot bot, int primaryId, int secondaryId, int slot, float duration)
{
    if (bot.AmmoPreserveDelay <= GetGameTime())
    {
        FObject primary, secondary;
        primary = ConstructObject(primaryId);
        secondary = ConstructObject(secondaryId);

        int ammotype = 0;
        if (slot == 2 || slot == 1)
        {
            ammotype = 1;
            if (primary.Valid())
            {
                if (primary.HasProp(Prop_Send, "m_iClip1"))
                {
                    int clip = primary.GetProp(Prop_Send, "m_iClip1");
                    bot.SetPreservedClip(clip, TFWeaponSlot_Primary);
                    primary.SetProp(Prop_Send, "m_iClip1", 0);
                }
            }

            int ammo = bot.GetProp(Prop_Send, "m_iAmmo", ammotype);
            bot.SetPreservedAmmo(ammo, TFWeaponSlot_Primary);
            bot.SetProp(Prop_Send, "m_iAmmo", 0, ammotype);
        }

        if (slot == 2 || slot == 0)
        {
            ammotype = 2;
            if (secondary.Valid())
            {
                if (secondary.HasProp(Prop_Send, "m_iClip1"))
                {
                    int clip = secondary.GetProp(Prop_Send, "m_iClip1");
                    bot.SetPreservedClip(clip, TFWeaponSlot_Secondary);
                    secondary.SetProp(Prop_Send, "m_iClip1", 0);
                }
            }

            int ammo = bot.GetProp(Prop_Send, "m_iAmmo", ammotype);
            bot.SetPreservedAmmo(ammo, TFWeaponSlot_Secondary);
            bot.SetProp(Prop_Send, "m_iAmmo", 0, ammotype);
        }

        if (slot == 2)
        {
            if (!IsWeaponSlotActive(bot, TFWeaponSlot_Melee))
            {
                BotSwitchToSlot(bot, TFWeaponSlot_Melee);
            }
        }
    }

    bot.AmmoPreserveDelay = GetGameTime() + 1.0;
    bot.SetTimer("TFBot.AmmoRefreshTimer", ConstructTimer(duration, false, false, true));
}

void BotSwitchToSlot(ACustomBot bot, int slot)
{
	if (slot >= 0 && slot <= 5 && bot && bot.Alive())
	{
		FObject weapon;
        weapon = ConstructObject(GetPlayerWeaponSlot(bot.Get(), slot));
		if (weapon.Valid())
		{
            bot.SetPropEnt(Prop_Send, "m_hActiveWeapon", weapon);
		}
	}
}

bool IsWeaponSlotActive(ACustomBot bot, int slot)
{
    return GetPlayerWeaponSlot(bot.Get(), slot) == GetEntPropEnt(bot.Get(), Prop_Send, "m_hActiveWeapon");
}

bool ShouldBotFlee(ACustomBot bot)
{
    if (bot && bot.MaxHealth > 0)
    {
        float hpratio = float(GetHealth(bot)) / float(bot.MaxHealth);
        float threshold = bot.GetBotData().HealthThreshold;

        if (hpratio <= threshold)
        {
            return true;
        }
    }

    return false;
}

/*
int GetBotHealthThreshold(ACustomBot bot)
{
    return RoundToFloor(bot.GetBotData().HealthThreshold * float(bot.MaxHealth));
}
*/

bool BotCanAttack(ACustomBot bot, TFClassType class)
{
    if (class == TFClass_Spy)
    {
        // Bot is a spy that is cloaked or disguised, do not engage targets
        if (bot.InCondition(TFCond_Cloaked) || bot.InCondition(TFCond_Disguised))
        {
            return false;
        }
    }

    return true;
}

bool AcceptableAngle(ACustomBot bot, FObject target)
{
    FVector botpos, targpos;
    botpos = bot.GetPosition();
    targpos = target.GetPosition();

    FRotator targangle;
    targangle = FMath.CalcRotator(botpos, targpos);

    NormalizeAngles(targangle);
    if (FloatAbs(targangle.Pitch) > 44.0)
    {
        return false;
    }

    return true;
}

void SetTargetViewAngles(ACustomBot bot, bool head = false, bool proj = false, bool ground = true)
{
    FVector aimpos, botpos, aimvec;
    FRotator aimangle;
    float inaccuracy = 0.0;

    FObject target;
    target = bot.GetCurrentTarget();
    if (target.Valid() && CheckVisionTrace(bot, target) && TargetInFOV(bot, target, bot.GetAimFOV()))
    {
        inaccuracy = bot.GetInaccuracy();
        if (head)
        {

        }
        else if (!proj)
        {
            aimpos = target.GetPosition();
            aimpos.Z += 40.0;
        }

        botpos = bot.GetEyePosition();

        if (proj)
        {

            if (!ground)
            {

            }
        }

        aimvec = Vector_MakeFromPoints(botpos, aimpos);
        aimangle = Vector_GetAngles(aimvec);

        // Inaccuracy calculation
        float min = inaccuracy * -1.0;
        float max = inaccuracy;
        float pitch = GetRandomFloat(min, max);
        float yaw = GetRandomFloat(min, max);
        aimangle.Pitch += pitch;
        aimangle.Yaw += yaw;

        NormalizeAngles(aimangle);
        TeleportEntity(bot.Get(), NULL_VECTOR, aimangle.ToFloat(), NULL_VECTOR);
    }
}

bool TargetInFOV(ACustomBot bot, FObject target, float fov)
{
    FVector botpos, targpos
    FRotator botangle;
    float fovcheck = 0.0;

    botangle = bot.GetEyeAngles();
    botpos = bot.GetEyePosition();
    targpos = target.GetPosition();
    targpos.Z += 40.0;

    fovcheck = FMath.GetAngle(botangle, FMath.CalcRotator(botpos, targpos));
    if (fovcheck <= fov)
    {
        return true;
    }

    return false;
}
