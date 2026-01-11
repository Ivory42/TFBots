
#include <sdktools>
#include <custombots>

#define PLUGIN_VERSION  "1.5.0"

Handle GetBonePosition;
Handle EquipWearable;

ConVar SpawnBots;
ConVar BotQuota;
ConVar Gravscale;
ConVar BotDisconnectMessage;

int OffsetStudioHdr;

bool MapIsCP = false;
bool ShouldBotHook = false; // If true, next spawned bot will have custom functionality

int ForcedIndex; // If non-zero, will force the next spawned bot to use this index.

ArrayList AvailableBotList; // List of available bot indices for random bot selections
StringMap BotPrefabs; // Stringmap containing all cached bot prefabs

#include "BotEvents.sp"
#include "BotHandler.sp"

public void OnPluginStart()
{
	Events_OnPluginStart();

	//Debug commands
	RegAdminCmd("sm_spawnbot", CMDSpawnBot, ADMFLAG_ROOT);
	//RegAdminCmd("sm_sethp", CMDSetHP, ADMFLAG_ROOT);

	//Nav editor
	//RegAdminCmd("sm_naveditor", CMDCreateNavPoint, ADMFLAG_ROOT);
	//RegAdminCmd("sm_reloadnodes", CMDReloadNodes, ADMFLAG_ROOT);

	//Convars
	SpawnBots = CreateConVar("tf_bot_allow_join", "1", "Can TFBots randomly join and leave the server");
	BotDisconnectMessage = CreateConVar("tf_bot_disconnect_message", "Disconnect by user", "Message to use for when a bot is disconnected");
	BotQuota = FindConVar("tf_bot_quota");
	Gravscale = FindConVar("sv_gravity");

	//Forwards
	//BotResupplyForward = new GlobalForward("CB_OnBotResupply", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	//BotDeathForward = new GlobalForward("CB_OnBotDeath", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	//BotRocketJump = new GlobalForward("CB_OnBotBlastJump", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	//BotAdded = new GlobalForward("CB_OnBotAdded", ET_Ignore, Param_Cell, Param_Cell, Param_String);

	GenerateDirectories();

	//Hook join message
	HookUserMessage(GetUserMessageId("SayText2"), UserMessage_SayText2, true);

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
	GameData data = LoadGameConfigFile("Bots.Wearables");

	if (!data)
	{
		LogMessage("Failed to find Bots.Wearables.txt gamedata! Bots will not equip cosmetics!");
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
	MapIsCP = FindControlPoints();

	ReloadBotConfigurations();

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

	// Pull prefabs from our config
	KeyValues kv = new KeyValues("BotPrefabs");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof sPath, "configs/botprefabs.cfg");
	kv.ImportFromFile(sPath);

	int index = 1; // Start at 1
	FBotData data;
	kv.GotoFirstSubKey();
	do
	{
		data.Index = index;
		kv.GetSectionName(data.Name, sizeof FBotData::Name);
		data.Class = view_as<TFClassType>(kv.GetNum("class", 1));
		data.Offclass = view_as<TFClassType>(kv.GetNum("offclass"));
		data.PriorityClass = view_as<TFClassType>(kv.GetNum("prioritize"));
		data.Inaccuracy = kv.GetFloat("inaccuracy");
		data.AimDelay = kv.GetFloat("aimdelay");
		data.AimFOV = kv.GetFloat("aimfov", 90.0);
		data.AggroDelay = kv.GetFloat("aggrotime", 10.0);
		data.AttackRange = kv.GetFloat("range");
		data.HealthThreshold = kv.GetFloat("health_threshold");
		data.PreferMelee = view_as<bool>(kv.GetNum("melee"));
		data.PreferJump = view_as<bool>(kv.GetNum("preferjump"));
		data.Proficiency = kv.GetNum("proficiency", 3);

		// Sniper
		data.SniperAimTime = kv.GetFloat("aimtime", 1.5);
		data.SniperConfidence = kv.GetNum("confidence_hs", 1);
		data.PressureDistance = kv.GetFloat("pressure_distance", 400.0);

		// Soldier
		data.SoldierConfidence = kv.GetNum("confidence_rj", 1);
		data.HeightThreshold = kv.GetFloat("height", 300.0);
		data.AimGround = view_as<bool>(kv.GetNum("aimground"));

		char key[32];
		IntToString(index, key, sizeof key);
		AvailableBotList.Push(index);
		BotPrefabs.SetArray(key, data, sizeof FBotData);

		index++;
	}
	while (kv.GotoNextKey());

	delete kv;
	return false;
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
	BuildPath(Path_SM, sPath, sizeof sPath, "configs/navpoints/");

	if (!DirExists(sPath))
	{
		CreateDirectory(sPath, 511);

		if (!DirExists(sPath)) //Failed to create directory
		{
			LogMessage("Failed to create navpoints directory (configs/navpoints/) - Please manually create this path");
			return;
		}
	}
	LogMessage("Successfully generated navpoints directory");
}

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

bool IsControlPoints()
{
	char sMap[64];
	GetCurrentMap(sMap, sizeof sMap);

	if (StrContains(sMap, "cp_") != -1 && MapIsCP)
		return true;

	return false;
}
