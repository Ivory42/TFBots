
#include <sdktools>
#include <custombots>

#define PLUGIN_VERSION  "0.0.1"

Handle GetBonePosition;
Handle EquipWearable;

ConVar SpawnBots;
ConVar BotQuota;
//ConVar Gravscale;
//ConVar BotDisconnectMessage;

int OffsetStudioHdr;

//bool MapIsCP = false;
bool ShouldBotHook = false; // If true, next spawned bot will have custom functionality

FBotData ForceBot; // If a valid data set, will force the next spawned bot to use this data

ArrayList AvailableBotList; // List of available bot indices for random bot selections
StringMap BotPrefabs; // Stringmap containing all cached bot prefabs

#include "BotHandler.sp"

public void OnPluginStart()
{
	BotHandler_OnPluginStart();

	//Debug commands
	RegAdminCmd("sm_spawnbot", CMDSpawnBot, ADMFLAG_ROOT);
	//RegAdminCmd("sm_sethp", CMDSetHP, ADMFLAG_ROOT);

	//Nav editor
	//RegAdminCmd("sm_naveditor", CMDCreateNavPoint, ADMFLAG_ROOT);
	//RegAdminCmd("sm_reloadnodes", CMDReloadNodes, ADMFLAG_ROOT);

	//Convars
	SpawnBots = CreateConVar("tf_bot_allow_join", "0", "Can TFBots randomly join and leave the server");
	//BotDisconnectMessage = CreateConVar("tf_bot_disconnect_message", "Disconnect by user", "Message to use for when a bot is disconnected");
	BotQuota = FindConVar("tf_bot_quota");
	//Gravscale = FindConVar("sv_gravity");

	//Forwards
	//BotResupplyForward = new GlobalForward("CB_OnBotResupply", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	//BotDeathForward = new GlobalForward("CB_OnBotDeath", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	//BotRocketJump = new GlobalForward("CB_OnBotBlastJump", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	//BotAdded = new GlobalForward("CB_OnBotAdded", ET_Ignore, Param_Cell, Param_Cell, Param_String);

	GenerateDirectories();

	//SDKCalls
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x8B\xEC\x83\xEC\x30\x56\x8B\xF1\x80\xBE\x41\x03\x00\x00\x00", 16);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	GetBonePosition = EndPrepSDKCall();

	if (!GetBonePosition)
	{
		LogMessage("WARNING: CustomBots GetBonePosition lookup failed! Bots will not use accurate hit locations!");
	}

	OffsetStudioHdr = FindSendPropInfo("CBaseAnimating", "m_flFadeScale") + 28;
	LogMessage("OffsetStudioHdr = %d", OffsetStudioHdr);

	// Wearables
	GameData data = LoadGameConfigFile("equipwearable");

	if (!data)
	{
		LogMessage("Failed to find equipwearable.txt gamedata! Bots will not equip cosmetics!");
	}
	else
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(data, SDKConf_Virtual, "EquipWearable");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		EquipWearable = EndPrepSDKCall();

		if (!EquipWearable)
		{
			LogMessage("Couldn't load SDK function (CTFPlayer::EquipWearable). Bots will not equip wearables!");
		}

		delete data;
	}
}

public void OnMapStart()
{
	// Check for 5cp
	//MapIsCP = FindControlPoints();

	ReloadBotConfigurations();
	ForceBot = CreateBotData();

	FindConVar("tf_bot_reevaluate_class_in_spawnroom").SetBool(false);
	FindConVar("tf_bot_keep_class_after_death").SetBool(true);
	FindConVar("tf_bot_spawn_use_preset_roster").SetBool(false);

	CreateTimer(25.0, TimerCheckPlayers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

void ReloadBotConfigurations()
{
	// Initialize our list of available bot indices
	if (AvailableBotList)
	{
		delete AvailableBotList;
	}
	AvailableBotList = new ArrayList(32);

	// Initialize prefabs
	if (BotPrefabs)
	{
		delete BotPrefabs;
	}
	BotPrefabs = new StringMap();

	char botPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, botPath, sizeof botPath, "configs/custombots/prefabs");

	if (!DirExists(botPath))
	{
		CreateDirectory(botPath, 511);

		if (!DirExists(botPath)) // Failed to create directory. Pause the plugin and prompt the operator to create the directory
		{
			SetFailState("Failed to create bot prefab directory (configs/custombots/prefabs/) - Please manually create this path! The plugin will not work without it.");
		}
	}

	char filename[PLATFORM_MAX_PATH];
	char pathname[PLATFORM_MAX_PATH];
	char internal[64];
	FileType type;
	int botindex = 0;
	Handle directory = OpenDirectory(botPath);
	while (ReadDirEntry(directory, filename, sizeof filename, type))
	{
		if (type != FileType_File)
		{
			continue;
		}

		FormatEx(pathname, sizeof pathname, "%s/%s", botPath, filename);
		FormatEx(internal, sizeof internal, filename);
		ReplaceString(internal, sizeof internal, ".cfg", "");
		ReplaceString(internal, sizeof internal, ".txt", "");

		// Create our prefab from this file
		KeyValues kv = new KeyValues("CustomBot");
		if (!kv.ImportFromFile(pathname))
		{
			LogMessage("Unable to open %s. It will be excluded from the bot list!", filename);
			delete kv;
			continue;
		}
		
		FBotData data;
		data.Index = botindex;
		kv.GetString("name", data.Name, sizeof FBotData::Name);
		FormatEx(data.Config, sizeof FBotData::Config, internal);
		data.Class = view_as<TFClassType>(kv.GetNum("class", 1));
		data.Offclass = view_as<TFClassType>(kv.GetNum("offclass", 1));
		data.PriorityClass = view_as<TFClassType>(kv.GetNum("prioritize"));
		data.Inaccuracy = kv.GetFloat("inaccuracy");
		data.AimDelay = kv.GetFloat("aimdelay");
		data.AimFOV = kv.GetFloat("aimfov", 90.0);
		data.AggroDelay = kv.GetFloat("aggrotime", 10.0);
		data.AttackRange = kv.GetFloat("range");
		data.HealthThreshold = kv.GetFloat("health_threshold");
		data.PreferMelee = view_as<bool>(kv.GetNum("melee"));
		data.Proficiency = kv.GetNum("proficiency", 3);

		if (kv.JumpToKey("movement"))
		{
			data.PreferJump = view_as<bool>(kv.GetNum("preferjump", 0));
			data.PathFindRad = kv.GetFloat("path", 30.0);
			kv.GoBack();
		}
		else
		{
			data.PreferJump = false;
			data.PathFindRad = 30.0;
		}

		SetupBotClasses(kv, data);

		char key[32];
		IntToString(botindex, key, sizeof key);
		AvailableBotList.Push(botindex);
		BotPrefabs.SetArray(key, data, sizeof FBotData);
		botindex++;
	}
}

/************************

Initialize Bot Data

************************/

void SetupBotClasses(KeyValues kv, FBotData data)
{	
	data.Loadouts = new ArrayList(sizeof FBotLoadout);
	for (TFClassType class = TFClass_Scout; class <= TFClass_Engineer; class++)
	{
		char classname[64];
		GetLiteralClassName(class, classname, sizeof classname);

		if (kv.JumpToKey(classname))
		{
			switch (class)
			{
				case TFClass_Sniper:
				{
					data.SniperAimTime = kv.GetFloat("aimtime", 1.5);
					data.SniperConfidence = kv.GetNum("confidence_pressure", 1);
					data.PressureDistance = kv.GetFloat("pressure_distance", 400.0);
				}
				case TFClass_Soldier:
				{
					data.SoldierConfidence = kv.GetNum("confidence_rj", 1);
					data.HeightThreshold = kv.GetFloat("height", 300.0);
					data.AimGround = view_as<bool>(kv.GetNum("aimground"));
				}
			}

			SetupLoadouts(kv, data, class);
			kv.GoBack();
		}
	}

	if (data.Loadouts.Length == 0)
	{
		delete data.Loadouts;
	}
}

void SetupLoadouts(KeyValues kv, FBotData data, TFClassType class)
{
	FBotLoadout loadout;
	loadout.Class = class;
	bool weapons = false;
	if (kv.JumpToKey("weapons"))
	{
		for (int i = 0; i < 5; i++)
		{
			char slot[32];
			GetSlotName(i, slot, sizeof slot);
			if (kv.JumpToKey(slot))
			{
				FBotWeapon weapon;
				weapon.Enabled = true;
				kv.GetString("classname", weapon.Classname, sizeof FBotWeapon::Classname, "tf_weapon_bat");
				weapon.DefIndex = kv.GetNum("index");
				weapon.Killstreak = kv.GetNum("killstreak");
				weapon.Sheen = kv.GetNum("sheen");
				weapon.KSEffect = kv.GetNum("kEffect");
				weapon.Australium = view_as<bool>(kv.GetNum("australium"));
				weapon.Effect = kv.GetNum("effect");

				if (!StrContains(weapon.Classname, "tf_wearable"))
				{
					weapon.Wearable = true;
				}

				AssignSlot(weapon, loadout, i);
				weapons = true;
				kv.GoBack();
			}
		}

		kv.GoBack();
	}

	if (kv.JumpToKey("wearables"))
	{
		loadout.Wearables = new ArrayList(sizeof FBotWearable);
		for (int i = 1; i < 4; i++)
		{
			char index[32];
			IntToString(i, index, sizeof index);
			if (kv.JumpToKey(index))
			{
				FBotWearable wearable;
				wearable.DefIndex = kv.GetNum("index");
				wearable.Effect = kv.GetNum("effect");
				wearable.Paint1 = kv.GetNum("paint");
				wearable.Paint2 = kv.GetNum("paint2");

				if (wearable.DefIndex > 0)
				{
					wearable.Unusual = true;
				}

				loadout.Wearables.PushArray(wearable, sizeof FBotWearable);
				kv.GoBack();
			}
		}

		// If no wearables are found, free the handle
		if (loadout.Wearables.Length == 0)
		{
			delete loadout.Wearables;
		}
		kv.GoBack();
	}

	if (weapons || loadout.Wearables)
	{
		data.Loadouts.PushArray(loadout, sizeof FBotLoadout);
	}
}

/*********************

Commands

*********************/

Action CMDSpawnBot(int client, int args)
{
	char botname[64];
	GetCmdArg(1, botname, sizeof botname);
	
	if (strlen(botname) > 0)
	{
		FBotData data;
		data = GetBotDataFromName(botname);
		if (data.Index != -1)
		{
			ForceBot = data;
		}
		else
		{
			ReplyToCommand(client, "Invalid bot name provided");
			return Plugin_Handled;
		}
	}
	ShouldBotHook = true;
	ServerCommand("tf_bot_add 1");

	return Plugin_Handled;
}

Action TimerCheckPlayers(Handle timer)
{
	if (!SpawnBots.BoolValue)
	{
		return Plugin_Continue;
	}
	int botcount = BotQuota.IntValue;
	if (botcount >= 4)
	{
		int leave = GetRandomInt(1, 100);
		if (leave <= 14)
		{
			botcount--;
			char comm[64];
			Format(comm, sizeof comm, "tf_bot_quota %d", botcount);
			ServerCommand(comm);
		}
	}
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			count++;
		}
	}
	if (count > 0)
	{
		int chance = GetRandomInt(1, 100);
		if (chance <= 35 && ServerNotFull())
		{
			botcount++;
			ShouldBotHook = true;
			//CreateFakeClient("Custom_bot");
			char comm[64];
			Format(comm, sizeof comm, "tf_bot_quota %d", botcount);
			ServerCommand(comm);
		}
	}
	else if(count == 0)
	{
		ShouldBotHook = false;
		ServerCommand("tf_bot_quota 0");
	}
	return Plugin_Continue;
}

bool ServerNotFull()
{
	int players = GetClientCount(false);
	return (players < MaxClients - 1); // Always leave free slots
}

void GenerateDirectories()
{
	char sPath[64];
	BuildPath(Path_SM, sPath, sizeof sPath, "configs/custombots/navpoints/");

	if (!DirExists(sPath))
	{
		CreateDirectory(sPath, 511);

		if (!DirExists(sPath)) //Failed to create directory
		{
			LogMessage("Failed to create navpoints directory (configs/custombots/navpoints/) - Please manually create this path");
			return;
		}
	}
	LogMessage("Successfully generated navpoints directory");
}

/*
bool FindControlPoints()
{
	int ent = -1;
	int count;
	while ((ent = FindEntityByClassname(ent, "team_control_point")) != -1)
	{
		count++;
	}
	if (count >= 5)
		return true;

	return false;
}
*/

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	/*
	CreateNative("CB_SpawnBotByIndex", Native_SpawnBotByIndex);
	CreateNative("CB_HookBot", Native_HookBot);
	CreateNative("CB_SetBotParameterFloat", Native_SetParamFloat);
	CreateNative("CB_SetBotParameterInt", Native_SetParamInt);
	CreateNative("CB_SetBotParameterBool", Native_SetParamBool);
	CreateNative("CB_OverrideParameter", Native_TemporaryOver);
	CreateNative("CB_IsCustomBot", Native_CustomBot);
	CreateNative("CB_GetBotClass", Native_GetBotClass);
	CreateNative("CB_GetBotOffClass", Native_GetBotOffClass);
	CreateNative("CB_GetBotIndex", Native_GetBotIndex);
	*/
	return APLRes_Success;
}

/***************************

Bot Join Functions

***************************/

public void EntManager_OnClientRegistered(AClient client)
{
	if (IsFakeClient(client.Get()) && ShouldBotHook)
	{
		ACustomBot bot = view_as<ACustomBot>(client);
		FBotData data;
		data = CreateBotData();
		if (ForceBot.Index != -1)
		{
			data = ForceBot;
			ForceBot = CreateBotData();
		}
		else if (BotPrefabs)
		{
			int index = GetFreeBotIndex();
			char key[32];
			IntToString(index, key, sizeof key);
			BotPrefabs.GetArray(key, data, sizeof FBotData);
		}

		if (data.Index != -1)
		{
			SDKHook(client.Get(), SDKHook_GetMaxHealth, BotSetMaxHealth);
			BotHandler_InitializeBot(bot, data);
		}

		ShouldBotHook = false;
	}
}

Action BotSetMaxHealth(int botId, int& health)
{
	return Plugin_Continue;
}

/*
bool IsControlPoints()
{
	char sMap[64];
	GetCurrentMap(sMap, sizeof sMap);

	if (StrContains(sMap, "cp_") != -1 && MapIsCP)
		return true;

	return false;
}
*/

/***********************
 
Misc Functions

***********************/

void GetLiteralClassName(TFClassType class, char[] name, int size)
{
	switch (class)
	{
		case TFClass_Scout: FormatEx(name, size, "scout");
		case TFClass_Sniper: FormatEx(name, size, "sniper");
		case TFClass_Soldier: FormatEx(name, size, "soldier");
		case TFClass_DemoMan: FormatEx(name, size, "demoman");
		case TFClass_Medic: FormatEx(name, size, "medic");
		case TFClass_Heavy: FormatEx(name, size, "heavy");
		case TFClass_Pyro: FormatEx(name, size, "pyro");
		case TFClass_Spy: FormatEx(name, size, "spy");
		case TFClass_Engineer: FormatEx(name, size, "engineer");
	}
}

void GetSlotName(int slot, char[] name, int size)
{
	switch (slot)
	{
		case TFWeaponSlot_Primary: FormatEx(name, size, "primary");
		case TFWeaponSlot_Secondary: FormatEx(name, size, "secondary");
		case TFWeaponSlot_Melee: FormatEx(name, size, "melee");
		case TFWeaponSlot_Grenade: FormatEx(name, size, "grenade"); // Disguise kit, but won't be used
		case TFWeaponSlot_Building: FormatEx(name, size, "building"); // Spy watches
	}
}

void AssignSlot(FBotWeapon weapon, FBotLoadout loadout, int slot)
{
	switch (slot)
	{
		case TFWeaponSlot_Primary: loadout.Primary = weapon;
		case TFWeaponSlot_Secondary: loadout.Secondary = weapon;
		case TFWeaponSlot_Melee: loadout.Melee = weapon;
		case TFWeaponSlot_Building: loadout.Building = weapon;
	}
}

/*
int GetBotIndexFromName(const char[] name)
{
	int index = -1;
	if (BotPrefabs && BotPrefabs.Size > 0)
	{
		FBotData data;
		StringMapSnapshot snap = BotPrefabs.Snapshot();
		char key[32];
		for (int i = 0; i < snap.Length; i++)
		{
			snap.GetKey(i, key, sizeof key);
			BotPrefabs.GetArray(key, data, sizeof data);

			if (StrEqual(name, data.Name, false) || StrEqual(name, data.Config, false))
			{
				index = data.Index;
				break;
			}
		}

		delete snap;
	}

	return index;
}
*/

FBotData GetBotDataFromName(const char[] name)
{
	FBotData result;
	result = CreateBotData();
	if (BotPrefabs && BotPrefabs.Size > 0)
	{
		FBotData data;
		StringMapSnapshot snap = BotPrefabs.Snapshot();
		char key[32];
		for (int i = 0; i < snap.Length; i++)
		{
			snap.GetKey(i, key, sizeof key);
			BotPrefabs.GetArray(key, data, sizeof data);

			if (StrEqual(name, data.Name, false) || StrEqual(name, data.Config, false))
			{
				result = data;
				break;
			}
		}

		delete snap;
	}

	return result;
}

int GetFreeBotIndex(int force = -1)
{
	int index = -1;
	if (force > -1)
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

FBotLoadout GetClassLoadout(ACustomBot bot, TFClassType class)
{
	FBotLoadout loadout;
	FBotData data;
	data = bot.GetBotData();
	if (data.Loadouts && data.Loadouts.Length > 0)
	{
		for (int i = 0; i < data.Loadouts.Length; i++)
		{
			FBotLoadout test;
			data.Loadouts.GetArray(i, test, sizeof test);
			if (test.Class == class)
			{
				loadout = test;
				break;
			}
		}
	}

	return loadout;
}

void SpawnBotWeapon(ACustomBot bot, char[] classname, int index, int effect, int killstreak, int aussie, int sheen, int kEffect, int quality = 6)
{
	if (bot)
	{
		FWeapon weapon;
		weapon = CreateWeapon(bot, classname, index, 1, quality, "", true, true);
		if (weapon.Valid())
		{
			if (effect > 0)
			{
				weapon.SetAttributeIndex(134, float(effect));
			}

			if (killstreak > 0)
			{
				weapon.SetAttributeName("killstreak tier", 1.0);
				if (sheen > 0)
				{
					weapon.SetAttributeIndex(2014, float(sheen));
				}
				if (kEffect > 0)
				{
					weapon.SetAttributeIndex(2013, float(kEffect));
				}
			}

			if (index == 1071) //gold pan
			{
				weapon.SetAttributeName("item style override", 0.0);
			}

			if (aussie == 1)
			{
				weapon.SetAttributeName("is australium item", 1.0);
				weapon.SetAttributeName("item style override", 1.0);
			}
		}
	}
}

FWeapon CreateWeapon(ACustomBot bot, char[] name, int index, int level, int quality, char[] attribute, bool visible = true, bool preserve = true)
{
	if(StrEqual(name,"saxxy", false)) // if "saxxy" is specified as the name, replace with appropiate name
	{
		switch(TF2_GetPlayerClass(bot.Get()))
		{
			case TFClass_Scout: ReplaceString(name, 64, "saxxy", "tf_weapon_bat", false);
			case TFClass_Soldier: ReplaceString(name, 64, "saxxy", "tf_weapon_shovel", false);
			case TFClass_Pyro: ReplaceString(name, 64, "saxxy", "tf_weapon_fireaxe", false);
			case TFClass_DemoMan: ReplaceString(name, 64, "saxxy", "tf_weapon_bottle", false);
			case TFClass_Heavy: ReplaceString(name, 64, "saxxy", "tf_weapon_club", false);
			case TFClass_Engineer: ReplaceString(name, 64, "saxxy", "tf_weapon_wrench", false);
			case TFClass_Medic: ReplaceString(name, 64, "saxxy", "tf_weapon_bonesaw", false);
			case TFClass_Sniper: ReplaceString(name, 64, "saxxy", "tf_weapon_club", false);
			case TFClass_Spy: ReplaceString(name, 64, "saxxy", "tf_weapon_knife", false);
			default: ReplaceString(name, 64, "saxxy", "tf_weapon_club", false);
		}
	}

	if(StrEqual(name, "tf_weapon_shotgun", false)) // If using tf_weapon_shotgun for Soldier/Pyro/Heavy/Engineer
	{
		switch(TF2_GetPlayerClass(bot.Get()))
		{
			case TFClass_Soldier: ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_soldier", false);
			case TFClass_Pyro: ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_pyro", false);
			case TFClass_Heavy:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_hwg", false);
			case TFClass_Engineer: ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_primary", false);
			default: ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_soldier", false);
		}
	}

	Handle weapon = TF2Items_CreateItem((preserve ? PRESERVE_ATTRIBUTES : OVERRIDE_ALL) | FORCE_GENERATION);
	TF2Items_SetClassname(weapon, name);
	TF2Items_SetItemIndex(weapon, index);
	TF2Items_SetLevel(weapon, level);
	TF2Items_SetQuality(weapon, quality);
	char attributes[32][32];
	int count = ExplodeString(attribute, ";", attributes, 32, 32);
	if (count % 2 != 0)
	{
		count--;
	}

	if (count > 0)
	{
		TF2Items_SetNumAttributes(weapon, count / 2);
		int i2 = 0;
		for (int i = 0; i < count; i += 2)
		{
			int attrib = StringToInt(attributes[i]);
			if (attrib == 0)
			{
				LogError("Bad weapon attribute passed: %s ; %s", attributes[i], attributes[i+1]);
			}
			TF2Items_SetAttribute(weapon, i2, attrib, LibraryExists("tf2x10") ? StringToFloat(attributes[i+1])*10.0 : StringToFloat(attributes[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}

	if (weapon == null)
	{
		LogError("Invalid weapon spawned. client=%d name=%s idx=%d attr=%s", bot.Get(), name, index, attribute);
	}

	int entityId = TF2Items_GiveNamedItem(bot.Get(), weapon);

	delete weapon;

	PrepareItem(bot, ConstructObject(entityId), name, visible);

	return ConstructWeapon(entityId);
}

void PrepareItem(ACustomBot bot, FObject entity, const char[] classname, bool visibility = false)
{
	if (!visibility)
	{
		entity.SetProp(Prop_Send, "m_iWorldModelIndex", -1);
		entity.SetPropFloat(Prop_Send, "m_flModelScale", 0.001);
	}
	else
	{
		entity.SetProp(Prop_Send, "m_bValidatedAttachedEntity", 1);
	}

	if (StrContains(classname, "tf_wearable") == -1)
	{
		EquipPlayerWeapon(bot.Get(), entity.Get());
	}
}

bool SpawnBotWearable(ACustomBot bot, int itemindex, int quality = 6, int level = 0, int effect = 0, int paint = 0, int paint2 = 0)
{
	char entname[64];
	switch (itemindex)
	{
		case 131, 406, 1099, 1144: // Demo Shields
		{
			Format(entname, sizeof entname, "tf_wearable_demoshield");
		}
		case 57: // razorback
		{
			Format(entname, sizeof entname, "tf_wearable_razorback");
		}
		default: Format(entname, sizeof entname, "tf_wearable");
	}
	FObject wearable;
	wearable = FGameplayStatics.CreateObjectDeferred(entname);

	char entclass[64];
	wearable.GetNetClass(entclass, sizeof entclass);
	wearable.SetProp(Prop_Send, "m_iItemDefinitionIndex", itemindex);
	wearable.SetProp(Prop_Send, "m_bInitialized", 1);
	SetEntData(wearable.Get(), FindSendPropInfo(entclass, "m_iEntityLevel"), quality);

	if (level)
	{
		SetEntData(wearable.Get(), FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		SetEntData(wearable.Get(), FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomInt(1,100));
	}

	if (effect > 0)
	{
		TF2Attrib_SetByDefIndex(wearable.Get(), 134, float(effect));
	}

	if (paint > 0) //red team paint
	{
		TF2Attrib_SetByDefIndex(wearable.Get(), 142, float(paint));
	}

	if (paint2 > 0) //blue team paint
	{
		TF2Attrib_SetByDefIndex(wearable.Get(), 261, float(paint2));
	}
	else
	{
		TF2Attrib_SetByDefIndex(wearable.Get(), 261, float(paint));
	}

	FGameplayStatics.FinishSpawn(wearable, ConstructTransform(ConstructVector(), ConstructRotator()));

	if (EquipWearable)
	{
		SDKCall(EquipWearable, bot.Get(), wearable.Get());
		return true;
	}

	return false;
}