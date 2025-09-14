
void Events_OnPluginStart()
{
	HookEvent("teamplay_round_start", RoundStarted);
	HookEvent("player_death", PlayerDeath, EventHookMode_Post);
	HookEvent("post_inventory_application", PlayerResupply, EventHookMode_Post);
	HookEvent("player_hurt", PlayerHurt, EventHookMode_Pre);
	HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_connect_client", OnPlayerConnect, EventHookMode_Pre);
	HookEvent("player_changename", OnNameChange, EventHookMode_Pre);
	HookEvent("player_team", OnPlayerJoinTeam, EventHookMode_Pre);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Pre);
	HookEvent("teamplay_point_captured", OnPointCapped);
}

Action OnPlayerConnect(Event event, const char[] name, bool dontBroadcast)
{
	char networkId[50];
	event.GetString("networkid", networkId, sizeof networkId);
	char address[50];
	event.GetString("address", address, sizeof address);

	//PrintToChatAll("Checking bot: %s", strNetworkId);
	if (StrEqual(networkId, "BOT"))
	{
		//PrintToChatAll("Bot Joined");
		event.BroadcastDisabled = true;
	}
	return Plugin_Continue;
}

Action OnPlayerJoinTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsCustomBot(client) && client != 0)
	{
		if (Bot[client].index > 0)
		{
			char plname[MAX_NAME_LENGTH];
			Bot[client].GetName(plname, sizeof plname);
			SetClientInfo(client, "name", plname);
			SetEventBroadcast(event, true);
		}
	}
	return Plugin_Continue;
}

Action UserMessage_SayText2(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	char message[256];

	BfReadShort(bf);
	BfReadString(bf, message, sizeof(message));
	if (StrContains(message, "Name_Change") != -1)
	{
		BfReadString(bf, message, sizeof(message));

		int client = -1;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientConnected(i) || !IsFakeClient(i))
			{
				continue;
			}

			char testname[MAX_NAME_LENGTH];
			GetClientName(i, testname, sizeof(testname));
			if (StrEqual(message, testname))
			{
				client = i;
			}
		}

		if (client == -1)
			return Plugin_Continue;

		return Plugin_Handled;
	}

	return Plugin_Continue;
}
