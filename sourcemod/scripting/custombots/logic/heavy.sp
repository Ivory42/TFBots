void Heavy_OnCombatTick(ACustomBot bot, FObject target, int& buttons)
{
    FClient client;
    client = CastToClient(target);
    if (client.Valid())
    {
        if (client.GetClass() == TFClass_Sniper)
        {
            if (bot.ShouldCrouch)
            {
                buttons |= IN_DUCK;
            }
            if (bot.CrouchTime <= GetGameTime())
            {
                bot.ShouldCrouch = false;
            }
            if (bot.CrouchDelay <= GetGameTime())
            {
                int chance = GetRandomInt(1, 100);
                if (chance >= 35)
                {
                    bot.ShouldCrouch = true;
                    bot.CrouchTime = GetGameTime() + GetRandomFloat(0.1, 0.7);
                    bot.CrouchDelay = GetGameTime() + GetRandomFloat(1.0, 6.0);
                }
            }
        }
    }
}