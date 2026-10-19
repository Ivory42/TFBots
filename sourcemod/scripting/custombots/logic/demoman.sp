void Demo_OnCombatTick(ACustomBot bot, FObject target, int& buttons, float distance)
{
    if (IsWeaponSlotActive(bot, TFWeaponSlot_Melee))
    {
        float charge = 0.0;
        if (bot.GetShield().Valid())
        {
            charge = bot.GetPropFloat(Prop_Send, "m_flChargeMeter");
        }
        if (distance <= 50.0)
        {
            buttons |= IN_ATTACK;
        }
        else if (bot.InCondition(TFCond_Charging))
        {
            buttons &= ~IN_ATTACK;
        }

        if (650.0 > distance >= bot.GetAttackRange() && CheckVisionTrace(bot, target))
        {
            if (charge >= 100.0)
            {
                buttons |= IN_ATTACK2;
            }
        }
        else
        {
            buttons &= ~IN_ATTACK2;
        }
    }
}

bool Demo_IsDemoKnight(ACustomBot bot)
{
    if (bot)
    {
        if (bot.Class == TFClass_DemoMan)
        {
            if (BotHasShield(bot) && GetPlayerWeaponSlot(bot.Get(), TFWeaponSlot_Primary) <= 0)
            {
                return true;
            }
        }
    }
    return false;
}