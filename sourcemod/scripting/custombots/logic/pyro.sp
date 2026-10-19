
void Pyro_OnCombatTick(ACustomBot bot, int& buttons, float distance, FBotLogicInfo info)
{
    switch (info.PrimaryIndex)
    {
        case 594:
        {
            if (bot.GetPropFloat(Prop_Send, "m_flRageMeter") >= 100.0)
            {
                buttons |= IN_ATTACK2;
            }
        }
    }

    if (distance <= 450.0)
    {
        buttons |= IN_ATTACK;
    }

    if (distance >= 125.0)
    {
        buttons &= ~IN_ATTACK2;
    }
}