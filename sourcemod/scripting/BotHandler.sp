
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
	ACustomBot bot = FBotStatics.GetPlayerAsBot(clientId);
	if (bot && ShouldBotHook)
	{
		FBotData data;
		data.Index = GetFreeBotIndex(ForcedIndex);
		ForcedIndex = -1;
		bot.SetBotData(data);

		SDKHook(clientId, SDKHook_GetMaxHealth, BotSetMaxHealth);
		if (data.Index)
		{
			CreateTimer(0.2, SetBotVars, client, TIMER_FLAG_NO_MAPCHANGE);
		}

		ShouldBotHook = false;
	}
}

int GetFreeBotIndex(int force = 0)
{
	int index = 0;
	if (force > 0)
	{
		index = force;
	}
	else // Pick a random bot index from our available list
	{
		int bots = AvailableBotList.Length - 1;
		int selection = GetRandomInt(0, bots);
		index = AvailableBotList.Get(selection);
	}

	// Remove this selected index from our available list.
	int position = AvailableBotList.FindValue(index);
	if (position != -1)
	{
		AvailableBotList.Erase(position);
	}

	return index;
}
