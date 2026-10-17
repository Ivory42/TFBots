void BotHandler_OnPluginStart()
{
	HookEvent("player_spawn", OnPlayerSpawn);
	//HookEvent("teamplay_round_start", RoundStarted);
	//HookEvent("player_death", PlayerDeath, EventHookMode_Post);
	HookEvent("post_inventory_application", PlayerResupply);
	//HookEvent("player_hurt", PlayerHurt, EventHookMode_Pre);
	//HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_connect_client", OnPlayerConnect, EventHookMode_Pre);
	//HookEvent("player_changename", OnNameChange, EventHookMode_Pre);
	HookEvent("player_team", OnPlayerJoinTeam, EventHookMode_Pre);
	//HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Pre);
	//HookEvent("teamplay_point_captured", OnPointCapped);

	//Hook join message
	HookUserMessage(GetUserMessageId("SayText2"), UserMessage_SayText2, true);
}

void BotHandler_InitializeBot(ACustomBot bot, FBotData data)
{
	bot.HookedBot = true;
	bot.SetBotData(data);
	bot.DesiredClass = data.Class;

	RequestFrame(UpdateBot, bot);
}

void UpdateBot(ACustomBot bot)
{
	SetClientInfo(bot.Get(), "name", bot.GetBotData().Name);
	PrintToChatAll("%s has joined the game", bot.GetBotData().Name);
	PrintToChatAll("%s was automatically assigned to team %s", bot.GetBotData().Name, (bot.Team == TFTeam_Red) ? "RED" : "BLU");

	// TODO: Bot Joined Forward
}

void GiveBotItems(ACustomBot bot)
{
	if (bot)
	{
		TFClassType class = TF2_GetPlayerClass(bot.Get());
		FBotLoadout loadout;
		loadout = GetClassLoadout(bot, class);
		FBotWeapon weapon;

		// Weapons
		if (loadout.Primary.Enabled)
		{
			weapon = loadout.Primary;
			TF2_RemoveWeaponSlot(bot.Get(), TFWeaponSlot_Primary);
			if (weapon.Wearable)
			{
				SpawnBotWearable(bot, weapon.DefIndex);
			}
			else
			{
				SpawnBotWeapon(bot, weapon.Classname, weapon.DefIndex, weapon.Effect, weapon.Killstreak, weapon.Australium, weapon.Sheen, weapon.KSEffect);
			}
		}

		if (loadout.Secondary.Enabled)
		{
			weapon = loadout.Secondary;
			TF2_RemoveWeaponSlot(bot.Get(), TFWeaponSlot_Secondary);
			if (weapon.Wearable)
			{
				SpawnBotWearable(bot, weapon.DefIndex);
			}
			else
			{
				SpawnBotWeapon(bot, weapon.Classname, weapon.DefIndex, weapon.Effect, weapon.Killstreak, weapon.Australium, weapon.Sheen, weapon.KSEffect);
			}
		}

		if (loadout.Melee.Enabled)
		{
			weapon = loadout.Melee;
			TF2_RemoveWeaponSlot(bot.Get(), TFWeaponSlot_Melee);
			if (weapon.Wearable)
			{
				SpawnBotWearable(bot, weapon.DefIndex);
			}
			else
			{
				SpawnBotWeapon(bot, weapon.Classname, weapon.DefIndex, weapon.Effect, weapon.Killstreak, weapon.Australium, weapon.Sheen, weapon.KSEffect);
			}
		}

		if (loadout.Building.Enabled)
		{
			weapon = loadout.Building;
			TF2_RemoveWeaponSlot(bot.Get(), TFWeaponSlot_Building);
			if (weapon.Wearable)
			{
				SpawnBotWearable(bot, weapon.DefIndex);
			}
			else
			{
				SpawnBotWeapon(bot, weapon.Classname, weapon.DefIndex, weapon.Effect, weapon.Killstreak, weapon.Australium, weapon.Sheen, weapon.KSEffect);
			}
		}

		// Cosmetics
		if (loadout.Wearables && loadout.Wearables.Length > 0)
		{
			FBotWearable wearable;
			for (int i = 0; i < loadout.Wearables.Length; i++)
			{
				loadout.Wearables.GetArray(i, wearable, sizeof FBotWearable);
				if (wearable.DefIndex > 0)
				{
					SpawnBotWearable(bot, wearable.DefIndex, 6, 0, wearable.Effect, wearable.Paint1, wearable.Paint2);
				}
			}
		}
	}
}

/********************

Events

********************/

Action OnPlayerConnect(Event event, const char[] name, bool dontBroadcast)
{
	char networkId[50];
	event.GetString("networkid", networkId, sizeof networkId);
	char address[50];
	event.GetString("address", address, sizeof address);

	if (StrEqual(networkId, "BOT"))
	{
		event.BroadcastDisabled = true;
	}
	return Plugin_Continue;
}

Action OnPlayerJoinTeam(Event event, const char[] name, bool dontBroadcast)
{
	ACustomBot bot = FBotStatics.GetPlayerAsBot(GetClientOfUserId(event.GetInt("userid")));
	if (bot)
	{
		SetClientInfo(bot.Get(), "name", bot.GetBotData().Name);
		event.BroadcastDisabled = true;
	}
	return Plugin_Continue;
}

void OnPlayerSpawn(Event event, const char[] name, bool dbroad)
{
	int botId = GetClientOfUserId(event.GetInt("userid"));
	ACustomBot bot = FBotStatics.GetPlayerAsBot(botId);
	if (bot)
	{
		if (bot.GetBotData().Index != -1)
		{
			// TF2_SetPlayerClass(bot.Get(), bot.DesiredClass);
		}
	}
}

void PlayerResupply(Event event, const char[] name, bool dontBroadcast)
{
	int botId = GetClientOfUserId(event.GetInt("userid"));
	ACustomBot bot = FBotStatics.GetPlayerAsBot(botId);
	if (bot)
	{
		if (bot.GetBotData().Index != -1)
		{
			TF2_SetPlayerClass(bot.Get(), bot.DesiredClass);
			GiveBotItems(bot);
		}
	}

	// TODO: Call forward for bot resupply
}

// Suppresses chat messages when bots change names
Action UserMessage_SayText2(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	char message[256];

	int clientId = BfReadShort(bf);
	BfReadString(bf, message, sizeof message);
	if (!StrContains(message, "#TF_Name_Change"))
	{
		if (clientId > 0 && clientId <= MaxClients && IsFakeClient(clientId))
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}