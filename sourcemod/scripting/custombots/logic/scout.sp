
void Scout_OnCombatTick(ACustomBot bot, FObject target, int& buttons, float distance, FVector velocity, TFClassType class, FBotLogicInfo info)
{
    if (bot)
    {
        if (distance > bot.GetAttackRange() * 1.3)
        {
            buttons &= ~IN_ATTACK;
        }

        FClient client;
        client = CastToClient(target);

        if (distance <= bot.GetAttackRange() + 200.0 || client.GetClass() == TFClass_Sniper)
        {
            DoStutterStep(bot, velocity, class, GetStrafeTime(bot, true));

            if (bot.TimerExpired("TFBot.NextJumpDecisionTimer"))
            {
                int proficiency = bot.GetBotData().Proficiency;
                if (proficiency > 2)
                {
                    float delay = GetRandomFloat(3.0, 6.0);
                    int jumpsuccess = 25;
                    if (proficiency >= 10)
                    {
                        delay = GetRandomFloat(1.8, 2.5);
                        if (client.Valid() && client.GetClass() == TFClass_Soldier || client.GetClass() == TFClass_DemoMan)
                        {
                            jumpsuccess = 100; // Always jump at max proficiency when against projectile classes
                        }
                        else
                        {
                            jumpsuccess = 80; // Slightly higher chance to jump than lower proficiencies
                        }
                    }
                    else if (proficiency > 6)
                    {
                        jumpsuccess = 70;
                    }
                    else if (proficiency > 4)
                    {
                        jumpsuccess = 45
                    }

                    if (bot.JumpDelayCount == 1) // double jump
                    {
                        delay = GetRandomFloat(0.7, 1.8);
                    }

                    if (GetRandomInt(1, 100) <= jumpsuccess) // perform a jump
                    {
                        bot.JumpDelayCount++;
                        if (bot.JumpDelayCount > 1)
                        {
                            bot.JumpDelayCount = 0;
                        }
                        bot.SetTimer("TFBot.JumpTimer", ConstructTimer(0.1, false, false, true));
                    }

                    bot.SetTimer("TFBot.NextJumpDecisionTimer", ConstructTimer(delay, false, false, true));
                }
            }
        }

        if (info.Primary.Valid() && info.Primary.GetProp(Prop_Send, "m_iClip1") == 0 && bot.KeepPrimaryDelay <= GetGameTime())
        {
            TryKeepSlot(bot, info.Primary.Get(), info.Secondary.Get(), TFWeaponSlot_Primary, 10.0);
            bot.KeepPrimaryDelay = GetGameTime() + 25.0;
        }
    }
}