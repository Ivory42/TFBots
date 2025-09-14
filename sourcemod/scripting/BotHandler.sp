
Action CMDSpawnBot(int client, int args)
{
	char botname[64];
	GetCmdArg(1, botname, sizeof botname);
	ForcedIndex = GetBotIndexFromName(botname);
	ShouldBotHook = true;
	ServerCommand("tf_bot_add 1");
}

public void OnClientPutInServer(int clientId)
{
	ATFBot bot = FBotStatics.GetPlayerAsBot(clientId);
	if (bot && ShouldBotHook)
	{
		//SDKHook(clientId, SDKHook_GetMaxHealth, BotSetMaxHealth);
	}
	if (IsFakeClient(clientId))
	{
		if (ShouldBotHook)
		{
			ATFBot bot = 
			SDKHook(client, SDKHook_GetMaxHealth, BotSetMaxHealth);
			Bot[client].index = GetFreeBotIndex(ForcedIndex);
			if (Bot[client].index)
			{
				CreateTimer(0.2, SetBotVars, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		//PrintToChatAll("index = %i", BotIndex[client]);
		ShouldBotHook = false;
	}
}