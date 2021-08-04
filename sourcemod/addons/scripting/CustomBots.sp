//Currently rewriting with better syntax
//Future versions will be a bit easier to follow

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf2items>
#include <custombots>

#define PLUGIN_VERSION  "1.0"
#define FAR_FUTURE 999999.0
#define MAXTEAMS	4

#define Address(%1) view_as<Address>(%1)
#define int(%1) view_as<int>(%1)

int g_iOffsetStudioHdr;

Handle g_hLookupBone;
Handle g_hGetBonePosition;
Handle g_hWearableEquip;
Handle g_hGameConfig;
Handle g_BotQuota;
Handle g_SpawnBots;
Handle gravscale;
Handle g_hSdkEquipWearable;
bool g_bSdkStarted;

float JumpTimer[MAXPLAYERS+1] = FAR_FUTURE;
float DoubleJumpTimer[MAXPLAYERS+1] = FAR_FUTURE;
bool Jump[MAXPLAYERS+1];
float HeadShotDelay[MAXPLAYERS+1] = FAR_FUTURE;
int JumpDelayCount[MAXPLAYERS+1];
bool IsScoped[MAXPLAYERS+1];

bool RoundInProgress = false;
bool bPointLocked[2048];
bool ShouldBotHook = false;
bool b5CPMap = false;

int Captures;
int iForcedIndex = 0;

float ZeroVec[3] = {0.0, 0.0, 0.0};

//Should probably make all these variable groups into structs...

//Map Navigation Vars
float RJPos[MAXRJPOS][3];									// Rocket Jump node Position
float RJAngles[MAXRJPOS][3];								// Rocket Jump node Angles
float RJDistance[MAXRJPOS];									// Rocket Jump node Radius
float RJNewAngles[MAXRJPOS][3];
float FallBackPos[MAXFALLBACK][3];							// Fallback node Position
float NodeRadius[MAXFALLBACK];								// Fallback node Radius
bool RJPosExists[MAXRJPOS];									// Does this Rocket Jump node exist
int FallBackIndex[MAXTEAMS];								// Fallback Index for team
int FallBackTeam[MAXFALLBACK];								// Fallback node corresponding team
int RJAir[MAXRJPOS];
int RJDifficulty[MAXRJPOS];
int RJTeam[MAXRJPOS];										// Rocket Jump node corresponding team
int RJPosCount;
int SnipePosCount;
int FallBackCount;

//Nav Editor Vars
CBNavType CurrentNavType[MAXPLAYERS+1]; 					//Type of nav point being configured
float NavPosition[MAXPLAYERS+1][3];							//Position of nav point
float NavAngles[MAXPLAYERS+1][3];							//(Rocket Jump) Angles of nav point
float NavTargetAngles[MAXPLAYERS+1][3];					 	//(Rocket Jump) Where bot should look towards after jumping
float NavRadius[MAXPLAYERS+1] = 100.0; 						//(Rocket Jump) Radius of nav point
int NavTeam[MAXPLAYERS+1]; 									//Team associated with nav point
int NavAir[MAXPLAYERS+1]; 									//(Rocket Jump) Is this a nav point for consecutive rocket jumps
int NavDifficulty[MAXPLAYERS+1]; 							//(Rocket Jump) Difficulty to decide whether a bot will use this nav point
bool NavPositionSelected[MAXPLAYERS+1] = false;
bool NavAngleSelected[MAXPLAYERS+1] = false;


//Bot Specific vars
float Inaccuracy[MAXPLAYERS+1];
float AimDelay[MAXPLAYERS+1];
float AimDelayAdd[MAXPLAYERS+1];
float AimFOV[MAXPLAYERS+1];
float AggroTime[MAXPLAYERS+1];
float AggroDelay[MAXPLAYERS+1];
float AttackRange[MAXPLAYERS+1];
float flSniperAimTime[MAXPLAYERS+1];
float flHealthThreshold[MAXPLAYERS+1];
float flHeightThreshold[MAXPLAYERS+1];
float NoiseMakerDelay[MAXPLAYERS+1];
float NoiseMakerDelayAdd[MAXPLAYERS+1];
int BotIndex[MAXPLAYERS+1];
int BotAggroTarget[MAXPLAYERS+1];
int iClassPriority[MAXPLAYERS+1];
int iBotClass[MAXPLAYERS+1];
int iBotOffClass[MAXPLAYERS+1];
int DamageTaken[MAXPLAYERS+1];
int iAntiAim[MAXPLAYERS+1];
int NoiseMaker[MAXPLAYERS+1];
bool bFleeing[MAXPLAYERS+1];
bool PreferJump[MAXPLAYERS+1];
bool bIsAttacking[MAXPLAYERS+1];
bool bPreferMelee[MAXPLAYERS+1];
bool bAimGround[MAXPLAYERS+1];
char sBotName[MAXPLAYERS+1][MAX_NAME_LENGTH];

//Bot vars
int shield[MAXPLAYERS+1];
int iObstructions[MAXPLAYERS+1];
int iPreservedAmmoP[MAXPLAYERS+1];
int iPreservedClipP[MAXPLAYERS+1];
int iPreservedAmmoS[MAXPLAYERS+1];
int iPreservedClipS[MAXPLAYERS+1];
float flBotKeepPrimaryDelay[MAXPLAYERS+1];
float flBotAmmoDuration[MAXPLAYERS+1] = FAR_FUTURE;
float flAmmoPreserveDelay[MAXPLAYERS+1];
float DamageDelay[MAXPLAYERS+1];
float StepDelay[MAXPLAYERS+1];
float StrafeSpeed[MAXPLAYERS+1];
float CallMedicDelay[MAXPLAYERS+1];
float RJForwardDelay[MAXPLAYERS+1];
float RJForwardTime[MAXPLAYERS+1];
float RJPreservedAngles[MAXPLAYERS+1][3];
float RJCooldown[MAXPLAYERS+1];
float RJDelay[MAXPLAYERS+1];
float flNavDelay[MAXPLAYERS+1];
bool NavJump[MAXPLAYERS+1];
bool bInCaptureArea[MAXPLAYERS+1];
bool bScoutSingleJump[MAXPLAYERS+1];
bool bIsHookedBot[MAXPLAYERS+1];
//bool CanSeeTarget[MAXPLAYERS+1];

//Bot Index Vars
bool IndexTaken[MAXBOTS+1];

char sBotDisconnectMessage[128]; //Message to use for bot disconnect

//Forwards

GlobalForward g_BotResupply;
GlobalForward g_BotDeath;
GlobalForward g_BotAttack;
GlobalForward g_BotJump;
GlobalForward g_BotRocketJump;
GlobalForward g_BotTakeDamage;

ConVar g_playerBot;

public Plugin myinfo =
{
	name = "Custom Bots",
	author = "IvoryPal",
	description = "Individualized TFBot logic.",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart()
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

	//Debug commands
	RegAdminCmd("sm_botjump", RocketJump, ADMFLAG_ROOT);
	RegAdminCmd("sm_spawnbot", CMDSpawnBot, ADMFLAG_ROOT);
	RegAdminCmd("sm_sethp", CMDSetHP, ADMFLAG_ROOT);

	//Nav editor
	RegAdminCmd("sm_naveditor", CMDCreateNavPoint, ADMFLAG_ROOT);
	RegAdminCmd("sm_reloadnodes", CMDReloadNodes, ADMFLAG_ROOT);

	//Convars
	g_SpawnBots = CreateConVar("tf_bot_allow_join", "0", "Can TFBots randomly join and leave the server");
	g_BotQuota = FindConVar("tf_bot_quota");
	gravscale = FindConVar("sv_gravity");

	//Forwards.. some of these are a bit useless, will probably rework forwards at a future date
	g_BotResupply = new GlobalForward("CB_OnBotResupply", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_BotAttack = new GlobalForward("CB_OnBotAttack", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_BotDeath = new GlobalForward("CB_OnBotDeath", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_BotJump = new GlobalForward("CB_OnBotJump", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_BotRocketJump = new GlobalForward("CB_OnBotBlastJump", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_BotTakeDamage = new GlobalForward("CB_OnBotTakeDamage", ET_Single, Param_Cell, Param_Cell, Param_Cell, Param_Any, Param_Cell, Param_Cell, Param_Cell);

	//debug for testing bot aim
	g_playerBot = CreateConVar("tf_bot_allow_player_aim", "0", "Allow players to aim like bots");

	GenerateDirectories();

	//Hook join message
	HookUserMessage(GetUserMessageId("SayText2"), UserMessage_SayText2, true);

	//SDKCalls

	//Bone names and positions in the world
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x8B\xEC\x56\x8B\xF1\x80\xBE\x41\x03\x00\x00\x00\x75\x2A\x83\xBE\x6C\x04\x00\x00\x00\x75\x2A\xE8\x2A\x2A\x2A\x2A\x85\xC0\x74\x2A\x8B\xCE\xE8\x2A\x2A\x2A\x2A\x8B\x86\x6C\x04\x00\x00\x85\xC0\x74\x2A\x83\x38\x00\x74\x2A\xFF\x75\x08\x50\xE8\x2A\x2A\x2A\x2A\x83\xC4\x08\x5E", 68);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	if ((g_hLookupBone = EndPrepSDKCall()) == INVALID_HANDLE)SetFailState("Failed to create SDKCall for CBaseAnimating::LookupBone signature!");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x8B\xEC\x83\xEC\x30\x56\x8B\xF1\x80\xBE\x41\x03\x00\x00\x00", 16);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	if ((g_hGetBonePosition = EndPrepSDKCall()) == INVALID_HANDLE)SetFailState("Failed to create SDKCall for CBaseAnimating::GetBonePosition signature!");

	g_iOffsetStudioHdr = FindSendPropInfo("CBaseAnimating", "m_flFadeScale") + 28;
	PrintToServer("g_iOffsetStudioHdr %i", g_iOffsetStudioHdr);

	//Cosmetics
	g_hGameConfig = LoadGameConfigFile("Bots.Wearables");

	if (!g_hGameConfig)
	{
		SetFailState("Failed to find Bots.Wearables.txt gamedata! Can't continue.");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Virtual, "EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWearableEquip = EndPrepSDKCall();

	if (!g_hWearableEquip)
	{
		SetFailState("Failed to prepare the SDKCall for giving cosmetics. Try updating gamedata or restarting your server.");
	}

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
			OnClientPutInServer(i);
	}

}

public void GenerateDirectories()
{
	char sPath[64];
	BuildPath(Path_SM, sPath, sizeof sPath, "configs/navpoints/");

	if (!DirExists(sPath))
	{
		CreateDirectory(sPath, 511);

		if (!DirExists(sPath)) //Failed to create directory
			SetFailState("Failed to create navpoints directory (configs/navpoints/) - Please manually create this path");
	}
	LogMessage("Successfully generated navpoints directory");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("CB_SpawnBotByIndex", Native_SpawnBotByIndex);
	CreateNative("CB_HookBot", Native_HookBot);
	CreateNative("CB_SetBotParameterFloat", Native_SetParamFloat);
	CreateNative("CB_SetBotParameterInt", Native_SetParamInt);
	CreateNative("CB_SetBotParameterBool", Native_SetParamBool);
	CreateNative("CB_IsCustomBot", Native_CustomBot);
	CreateNative("CB_GetBotClass", Native_GetBotClass);
	CreateNative("CB_GetBotOffClass", Native_GetBotOffClass);
	return APLRes_Success;
}

/*********************************************************************************

	NATIVES

*********************************************************************************/

public int Native_SpawnBotByIndex(Handle plugin, int args)
{
	int botid = GetNativeCell(1);
	int team = GetNativeCell(2);
	iForcedIndex = botid;
	//PrintToChatAll("bot ID: %i", iForcedIndex);
	char text[64];
	Format(text, sizeof text, "tf_bot_add 1 scout %s expert", team == 2 ? "red" : "blue");
	ShouldBotHook = true;
	ServerCommand(text);
}

public int Native_GetBotClass(Handle plugin, int args)
{
	int bot = GetNativeCell(1);
	if (IsCustomBot(bot))
	{
		return iBotClass[bot];
	}
	return 0;
}

public int Native_GetBotOffClass(Handle plugin, int args)
{
	int bot = GetNativeCell(1);
	if (IsCustomBot(bot))
	{
		return iBotOffClass[bot];
	}
	return 0;
}

public int Native_SetParamFloat(Handle plugin, int args)
{
	int bot = GetNativeCell(1);
	float value = GetNativeCell(2);
	CBParamType param = GetNativeCell(3);

	if (IsCustomBot(bot))
	{
		switch (param)
		{
			case CBParam_Aggro: AggroDelay[bot] = value;
			case CBParam_AimDelay: AimDelayAdd[bot] = value;
			case CBParam_Range: AttackRange[bot] = value;
			case CBParam_FOV: AimFOV[bot] = value;
			case CBParam_Inaccuracy: Inaccuracy[bot] = value;
			case CBParam_SniperAimTime: flSniperAimTime[bot] = value;
			case CBParam_SoldierGroundHeight: flHealthThreshold[bot] = value;
			case CBParam_HPRatio: flHealthThreshold[bot] = value;
			default: LogMessage("Tried to set a non-float parameter with CB_SetBotParameterFloat, please use a different parameter type!");
		}
	}
	else
		LogMessage("Tried to set a parameter on a bot that isn't hooked!");
}

public int Native_SetParamInt(Handle plugin, int args)
{
	int bot = GetNativeCell(1);
	int value = GetNativeCell(2);
	CBParamType param = GetNativeCell(3);

	if (IsCustomBot(bot))
	{
		switch (param)
		{
			case CBParam_Class: iBotClass[bot] = value;
			case CBParam_OffClass: iBotOffClass[bot] = value;
			case CBParam_AA: iAntiAim[bot] = value;
			case CBParam_ClassPriority: iClassPriority[bot] = value;
			default: LogMessage("Tried to set a non-integer parameter with CB_SetBotParameterInt, please use a different parameter type!");
		}
	}
	else
		LogMessage("Tried to set a parameter on a bot that isn't hooked!");
}

public int Native_SetParamBool(Handle plugin, int args)
{
	int bot = GetNativeCell(1);
	bool value = GetNativeCell(2);
	CBParamType param = GetNativeCell(3);

	if (IsCustomBot(bot))
	{
		switch (param)
		{
			case CBParam_PreferJump: PreferJump[bot] = value;
			case CBParam_SoldierAimGround: bAimGround[bot] = value;
			default: LogMessage("Tried to set a non-boolean parameter with CB_SetBotParameterBool, please use a different parameter type!");
		}
	}
	else
		LogMessage("Tried to set a parameter on a bot that isn't hooked!");
}

public int Native_HookBot(Handle plugin, int args)
{
	int bot = GetNativeCell(1);

	if (IsValidClient(bot))
	{
		if (IsFakeClient(bot))
		{
			if (BotIndex[bot] < 1)
				bIsHookedBot[bot] = true;
			else
				LogMessage("Tried to hook a bot that already has an index assigned!");
		}
		else
			LogMessage("Tried to hook a player that is not a bot!");
	}
}

public int Native_CustomBot(Handle plugin, int args)
{
	int bot = GetNativeCell(1);

	if (IsCustomBot(bot))
		return true;

	return false;
}

/******************************************************************************

	CP/AD CAPTURE POINT TRACKING

******************************************************************************/

public Action OnPointCapped(Handle cpEvent, const char[] name, bool dontBroadcast)
{
	Captures++;
	int cp = GetEventInt(cpEvent, "cp");
	if (Captures == 1)
		SetCapturePointLocked(cp, true);
	int team = GetEventInt(cpEvent, "team");
	switch (team)
	{
		case 2:
		{
			SetCapturePointLocked(cp + 1);
			SetCapturePointLocked(cp - 1, true);
		}
		case 3:
		{
			SetCapturePointLocked(cp + 1, true);
			SetCapturePointLocked(cp - 1);
		}
	}
	CreateTimer(0.5, DelaySetPoints);
}

public Action DelaySetPoints(Handle cpTimer)
{
	SetFallBackPoints();
	return Plugin_Stop;
}

stock void SetCapturePointLocked(int PointIndex, bool unlock = false)
{
	int ent = MaxClients+1;
	while ((ent = FindEntityByClassname(ent, "team_control_point")) != -1)
	{
		int pIndex = GetEntProp(ent, Prop_Data, "m_iPointIndex");
		if (pIndex == PointIndex)
		{
			if (unlock)
			{
				bPointLocked[ent] = false;
				//PrintToChatAll("Point %i Unlocked", PointIndex);
			}
			else
			{
				bPointLocked[ent] = true;
				//PrintToChatAll("Point %i Locked", PointIndex);
			}
		}
	}
}

public Action OnPlayerConnect(Handle cEvent, const char[] name, bool dontBroadcast)
{
	char strNetworkId[50];
	GetEventString(cEvent, "networkid", strNetworkId, sizeof(strNetworkId));
	char strAddress[50];
	GetEventString(cEvent, "address", strAddress, sizeof(strAddress));

	//PrintToChatAll("Checking bot: %s", strNetworkId);
	if (StrEqual(strNetworkId, "BOT"))
	{
		//PrintToChatAll("Bot Joined");
		SetEventBroadcast(cEvent, true);
	}
	return Plugin_Continue;
}

public bool IsControlPoints()
{
	char sMap[64];
	GetCurrentMap(sMap, sizeof sMap);

	if (StrContains(sMap, "cp_") != -1 && b5CPMap)
		return true;

	return false;
}



/*------------------------------------------------------------------------

	NAVIGATION EDITOR
	Wowie, this was a trip to get working
	-This allows users to manually set positions for bots to perform actions
	-Rocket Jump Nodes allow soldiers to rocket jump with given view angles (bots can now do rollouts!)
	-Sniper positions are pretty self explanatory
	-Fallback nodes are meant for 5CP and can only be accessed on 5CP maps
		- These nodes will be where bots fallback to when they decide they don't have enough teammates alive to contest the other team

	TODO:
		-Add engineer nodes and maybe even sticky jumping nodes... maybe
		-Implement difficulty values for rocket jump nodes so not all soldier bots perform the same jumps

------------------------------------------------------------------------*/

public Action CMDReloadNodes(int client, int args)
{
	char sMap[64];
	char sFallBack[64] = "";
	GetCurrentMap(sMap, sizeof sMap);
	ReloadNodes();

	if (IsControlPoints())
		Format(sFallBack, sizeof sFallBack, "\n - %i Fallback Positions found", FallBackCount);

	PrintToChatAll("[CB] Reloaded bot navigation\n - %i Sniper nodes found\n - %i Rocket Jump nodes found%s\n - Map: %s", SnipePosCount, RJPosCount, sFallBack, sMap);
}


public Action CMDCreateNavPoint(int client, int args)
{
	NavigationEditor(client);
}

public Action NavigationEditor(int client)
{
	ResetNavInfo(client);
	Menu NavEditor = new Menu(NavEditorCallback, MENU_ACTIONS_ALL);
	NavEditor.SetTitle("Bot Navigation Editor");
	NavEditor.AddItem("nav", "Create Nav Point");
	NavEditor.AddItem("-1", "Exit");
	SetMenuExitButton(NavEditor, true);
	NavEditor.Display(client, 60);
	return Plugin_Handled;
}

public int NavEditorCallback(Menu menu, MenuAction action, int client, int param1)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param1, info, sizeof(info));
			if (StrEqual(info, "nav"))
			{
				NavMenu(client);
			}
			if (StrEqual(info, "-1"))
			{
				delete menu;
				return 0;
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

public Action NavMenu(int client)
{
	Menu NavPoint = new Menu(NavPointCallback, MENU_ACTIONS_ALL);
	NavPoint.SetTitle("Select a Nav Type");
	NavPoint.AddItem("sniper", "Sniper Nav");
	NavPoint.AddItem("rj", "Rocket Jump Nav");
	if (IsControlPoints())
		NavPoint.AddItem("fallback", "FallBack Node");
	NavPoint.AddItem("-1", "Back");
	SetMenuExitButton(NavPoint, true);
	NavPoint.Display(client, 60);
	return Plugin_Handled;
}

public int NavPointCallback(Menu menu, MenuAction action, int client, int param1)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param1, info, sizeof(info));
			if (StrEqual(info, "sniper"))
			{
				CurrentNavType[client] = CBNavType_SniperPos;
			}
			if (StrEqual(info, "rj"))
			{
				CurrentNavType[client] = CBNavType_RocketJump;
			}
			if (StrEqual(info, "fallback"))
			{
				CurrentNavType[client] = CBNavType_FallBackPos;
			}
			if (StrEqual(info, "-1"))
			{
				NavigationEditor(client);
				return 0;
			}
			CreateNavPointMenu(client, CurrentNavType[client]);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

public Action CreateNavPointMenu(int client, CBNavType NavType)
{
	Menu NavPoint = new Menu(CreateNavCallback, MENU_ACTIONS_ALL);
	char sTitle[64];
	switch (NavType)
	{
		case CBNavType_RocketJump:
		{
			Format(sTitle, sizeof sTitle, "Select Position and Angle for this node");
		}
		default:
		{
			Format(sTitle, sizeof sTitle, "Select Position for this node");
		}
	}
	NavPoint.SetTitle(sTitle);
	NavPoint.AddItem("pos", "Position: Copy Position");
	if (NavType == CBNavType_RocketJump)
		NavPoint.AddItem("angle", "Angles: Copy ViewAngles");

	NavPoint.AddItem("continue", "Continue", CanProceedMenu(client, NavType) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	NavPoint.AddItem("-1", "Back");
	SetMenuExitButton(NavPoint, true);
	NavPoint.Display(client, 180);
	return Plugin_Handled;
}

public int CreateNavCallback(Menu menu, MenuAction action, int client, int param1)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param1, info, sizeof(info));
			if (StrEqual(info, "pos"))
			{
				GetClientAbsOrigin(client, NavPosition[client]);
				PrintToChat(client, "[CB] Position - x: %.1f, y: %.1f, z: %.1f", NavPosition[client][0], NavPosition[client][1], NavPosition[client][2]);
				NavPositionSelected[client] = true;
				CreateNavPointMenu(client, CurrentNavType[client]);
			}
			if (StrEqual(info, "angle"))
			{
				GetClientEyeAngles(client, NavAngles[client]);
				PrintToChat(client, "[CB] Angles - Pitch: %.1f Yaw: %.1f", NavAngles[client][0], NavAngles[client][1]);
				NavAngleSelected[client] = true;
				CreateNavPointMenu(client, CurrentNavType[client]);
			}
			if (StrEqual(info, "continue"))
			{
				switch (CurrentNavType[client])
				{
					case CBNavType_RocketJump:
					{
						SetNavTargetAngles(client);
					}
					case CBNavType_FallBackPos: SetNavRadius(client);
					case CBNavType_SniperPos: SetNavTeam(client);
				}
			}
			if (StrEqual(info, "-1"))
			{
				NavMenu(client);
				return 0;
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

public Action SetNavTargetAngles(int client)
{
	Menu NavPoint = new Menu(NavTargetCallback, MENU_ACTIONS_ALL);
	NavPoint.SetTitle("Set Target Angles for this node\n - OPTIONAL This will be the angles the bot looks towards after completing the jump\n - This can be left NULL to not set a view target");
	NavPoint.AddItem("angle", "NewAngle: Copy ViewAngles");
	NavPoint.AddItem("continue", "Continue");
	NavPoint.AddItem("-1", "Back");
	SetMenuExitButton(NavPoint, true);
	NavPoint.Display(client, 180);
	return Plugin_Handled;
}

public int NavTargetCallback(Menu menu, MenuAction action, int client, int param1)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param1, info, sizeof(info));
			if (StrEqual(info, "angle"))
			{
				GetClientEyeAngles(client, NavTargetAngles[client]);
				PrintToChat(client, "[CB] Angles - Pitch: %.1f Yaw: %.1f", NavTargetAngles[client][0], NavTargetAngles[client][1]);
				SetNavTargetAngles(client);
			}
			if (StrEqual(info, "continue"))
			{
				switch (CurrentNavType[client])
				{
					case CBNavType_RocketJump:
					{
						SetNavRadius(client);
					}
				}
			}
			if (StrEqual(info, "-1"))
			{
				CreateNavPointMenu(client, CurrentNavType[client]);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

public Action SetNavRadius(int client)
{
	Menu NavPoint = new Menu(NavRadiusCallback, MENU_ACTIONS_ALL);
	NavPoint.SetTitle("Set Node Radius:\n - This determines how close a bot needs to be to this node to use it\n\n - Value: %ihu", RoundToFloor(NavRadius[client]));
	NavPoint.AddItem("1", "+1hu");
	NavPoint.AddItem("5", "+5hu");
	NavPoint.AddItem("50", "+50hu");
	NavPoint.AddItem("100", "+100hu");
	NavPoint.AddItem("-1", "-1hu");
	NavPoint.AddItem("-5", "-5hu");
	NavPoint.AddItem("-50", "-50hu");
	NavPoint.AddItem("-100", "-100hu");
	NavPoint.AddItem("continue", "Continue");
	NavPoint.AddItem("back", "Back");
	SetMenuExitButton(NavPoint, true);
	NavPoint.Display(client, 180);
	return Plugin_Handled;
}

public int NavRadiusCallback(Menu menu, MenuAction action, int client, int param1)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param1, info, sizeof(info));
			if (StrEqual(info, "continue"))
			{
				PrintToChat(client, "[CB] Set node radius: %i", RoundToFloor(NavRadius[client]));
				switch(CurrentNavType[client])
				{
					case CBNavType_RocketJump: SetNavAir(client);
					case CBNavType_FallBackPos: SetNavTeam(client);
				}
			}
			else if (StrEqual(info, "back"))
			{
				switch (CurrentNavType[client])
				{
					case CBNavType_RocketJump: SetNavTargetAngles(client);
					case CBNavType_FallBackPos: CreateNavPointMenu(client, CurrentNavType[client]);
				}
			}
			else
			{
				float amount = StringToFloat(info);
				NavRadius[client] += amount;
				SetNavRadius(client);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

public Action SetNavAir(int client)
{
	Menu NavPoint2 = new Menu(NavAirCallback, MENU_ACTIONS_ALL);
	NavPoint2.SetTitle("Should this node only be used by bots that are blast jumping?");
	NavPoint2.AddItem("true", "Air: True");
	NavPoint2.AddItem("false", "Air: False");
	NavPoint2.AddItem("-1", "Back");
	SetMenuExitButton(NavPoint2, true);
	NavPoint2.Display(client, 180);
	return Plugin_Handled;
}

public int NavAirCallback(Menu menu, MenuAction action, int client, int param1)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param1, info, sizeof(info));
			if (StrEqual(info, "true"))
			{
				NavAir[client] = 1;
				SetNavTeam(client);
			}
			if (StrEqual(info, "false"))
			{
				NavAir[client] = 0;
				SetNavTeam(client);
			}
			if (StrEqual(info, "-1"))
			{
				SetNavRadius(client);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

public Action SetNavTeam(int client)
{
	Menu NavPoint = new Menu(NavTeamCallback, MENU_ACTIONS_ALL);
	NavPoint.SetTitle("What team this node should be used by");
	NavPoint.AddItem("0", "Team: Both");
	NavPoint.AddItem("2", "Team: RED");
	NavPoint.AddItem("3", "Team: BLU");
	NavPoint.AddItem("back", "Back");
	SetMenuExitButton(NavPoint, true);
	NavPoint.Display(client, 180);
	return Plugin_Handled;
}

public int NavTeamCallback(Menu menu, MenuAction action, int client, int param1)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param1, info, sizeof(info));
			if (StrEqual(info, "back"))
			{
				switch (CurrentNavType[client])
				{
					case CBNavType_RocketJump: SetNavAir(client);
					case CBNavType_FallBackPos: SetNavRadius(client);
					case CBNavType_SniperPos: CreateNavPointMenu(client, CurrentNavType[client]);
				}
			}
			else
			{
				int team = StringToInt(info);
				NavTeam[client] = team;
				ConfirmNavPoint(client);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

public Action ConfirmNavPoint(int client)
{
	Menu NavPoint = new Menu(NavFinalizeCallback, MENU_ACTIONS_ALL);
	char sNavName[64], sTeamName[64];
	GetLiteralNavName(CurrentNavType[client], sNavName, sizeof sNavName);
	GetLiteralTeamName(NavTeam[client], sTeamName, sizeof sTeamName);
	NavPoint.SetTitle("Create Navigation Node?:\n\nType: %s\nTeam: %s", sNavName, sTeamName);
	NavPoint.AddItem("confirm", "Create");
	NavPoint.AddItem("cancel", "Cancel");
	SetMenuExitButton(NavPoint, true);
	NavPoint.Display(client, 180);
	return Plugin_Handled;
}

public int NavFinalizeCallback(Menu menu, MenuAction action, int client, int param1)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param1, info, sizeof(info));
			if (StrEqual(info, "confirm"))
			{
				PrepareNavInfo(client);
				NavigationEditor(client);
			}
			if (StrEqual(info, "cancel"))
			{
				ResetNavInfo(client);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

public void PrepareNavInfo(int client)
{
	char sMapName[64];
	GetCurrentMap(sMapName, sizeof sMapName);

	WriteNodeToKv(client, sMapName, CurrentNavType[client], NavPosition[client], NavTeam[client], NavAngles[client], NavTargetAngles[client], NavRadius[client], NavAir[client], NavDifficulty[client]);
}

public void ResetNavInfo(int client)
{
	NavPosition[client] = NULL_VECTOR;
	NavPositionSelected[client] = false;
	NavAngles[client] = NULL_VECTOR;
	NavAngleSelected[client] = false;
	NavTargetAngles[client] = NULL_VECTOR;
	NavAir[client] = 0;
	NavTeam[client] = 0;
	NavRadius[client] = 100.0;
	NavDifficulty[client] = 0;
}

stock void WriteNodeToKv(int client, char[] mapname, CBNavType NavType, float pos[3], int iTeam, float angles[3] = {0.0, 0.0, 0.0}, float targetangles[3] = {0.0, 0.0, 0.0}, float radius = 100.0, int air = 0, int diff = 0)
{
	KeyValues kv = new KeyValues("NavPoints");
	char sPath[64];
	BuildPath(Path_SM, sPath, sizeof sPath, "configs/navpoints/%s.txt", mapname);

	if (!FileExists(sPath))
	{
		Handle fFile = OpenFile(sPath, "w");
		CloseHandle(fFile);
	}
	kv.ImportFromFile(sPath);

	int NavPoints;
	char sNavId[8];

	switch (NavType)
	{
		case CBNavType_SniperPos:
		{
			kv.JumpToKey("sniper", true);
			NavPoints = GetNavPoints(mapname, NavType);
			if (NavPoints > MAXSNIPEPOS)
			{
				PrintToChat(client, "[CB] Already at max sniper nav positions!");
				kv.Rewind();
				delete kv;
				return;
			}
			IntToString(NavPoints, sNavId, sizeof sNavId);

			//Create new position
			kv.JumpToKey(sNavId, true);
			kv.SetVector("pos", pos);
			kv.SetNum("team", iTeam);

			kv.Rewind();
			kv.ExportToFile(sPath);
			delete kv;
			PrintToChat(client, "Created sniper pos {#%i}:\n - Pos: x: %.2f y: %.2f z: %.2f\n - Team: %i", NavPoints, pos[0], pos[1], pos[2], iTeam);
			return;
		}
		case CBNavType_RocketJump:
		{
			kv.JumpToKey("rj", true);
			NavPoints = GetNavPoints(mapname, NavType);
			if (NavPoints > MAXRJPOS)
			{
				PrintToChat(client, "[CB] Already at max rocket jump positions!");
				kv.Rewind();
				delete kv;
				return;
			}
			IntToString(NavPoints, sNavId, sizeof sNavId);

			//Create new position
			kv.JumpToKey(sNavId, true);
			kv.SetVector("pos", pos);
			kv.SetVector("ang", angles);
			kv.SetVector("NewAng", targetangles);
			kv.SetFloat("distance",	radius);
			kv.SetNum("Air", air);
			kv.SetNum("Difficulty", diff);
			kv.SetNum("team", iTeam);

			kv.Rewind();
			kv.ExportToFile(sPath);
			delete kv;
			PrintToChat(client, "Created RJ pos {#%i}:\n - Pos: x: %.2f y: %.2f z: %.2f\n - Pitch: %.2f\n - Yaw: %.2f - \nTeam: %i", NavPoints, pos[0], pos[1], pos[2], angles[0], angles[1], iTeam);
			return;
		}
		case CBNavType_FallBackPos:
		{
			kv.JumpToKey("fallback", true);
			NavPoints = GetNavPoints(mapname, NavType);
			if (NavPoints > MAXFALLBACK)
			{
				PrintToChat(client, "[CB] Already at max fallback positions!");
				kv.Rewind();
				delete kv;
				return;
			}
			IntToString(NavPoints, sNavId, sizeof sNavId);

			//Create new position
			kv.JumpToKey(sNavId, true);
			kv.SetVector("pos", pos);
			kv.SetFloat("radius", radius);
			kv.SetNum("team", iTeam);

			kv.Rewind();
			kv.ExportToFile(sPath);
			delete kv;
			PrintToChat(client, "Created FallBack pos {#%i}:\n - Pos: x: %.2f y: %.2f z: %.2f\nTeam: %i", NavPoints, pos[0], pos[1], pos[2], iTeam);
			return;
		}
	}
	kv.Rewind();
	delete kv;
	return;
}

stock int GetNavPoints(const char[] currentMap, CBNavType NavType)
{
	KeyValues kv = new KeyValues("NavPoints");
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof sPath, "configs/navpoints/%s.txt", currentMap);

	if (!FileExists(sPath))
	{
		Handle fFile = OpenFile(sPath, "w");
		CloseHandle(fFile);
	}

	kv.ImportFromFile(sPath);

	int count = 0;

	char sNavId[8];
	switch (NavType)
	{
		case CBNavType_SniperPos:
		{
			if (kv.JumpToKey("sniper"))
			{
				for (int i = 0; i < MAXSNIPEPOS; i++)
				{
					IntToString(i, sNavId, sizeof sNavId);
					//LogMessage("Found NavID: %i", i);
					if (kv.JumpToKey(sNavId))
					{
						count++
						kv.GoBack();
					}
					else
						break;
				}
			}
		}
		case CBNavType_RocketJump:
		{
			if (kv.JumpToKey("rj"))
			{
				for (int i = 0; i < MAXRJPOS; i++)
				{
					IntToString(i, sNavId, sizeof sNavId);
					if (kv.JumpToKey(sNavId))
					{
						count++
						kv.GoBack();
					}
					else
						break;
				}
			}
		}
		case CBNavType_FallBackPos:
		{
			if (kv.JumpToKey("fallback"))
			{
				for (int i = 0; i < MAXFALLBACK; i++)
				{
					IntToString(i, sNavId, sizeof sNavId);
					if (kv.JumpToKey(sNavId))
					{
						count++
						kv.GoBack();
					}
					else
						break;
				}
			}
		}
	}
	kv.Rewind();
	delete kv;
	LogMessage("NavCount ended at: %i", count);
	return count;
}

stock char[] GetLiteralNavName(CBNavType NavType, char[] sNavName, int iSize)
{
	switch (NavType)
	{
		case CBNavType_RocketJump: Format(sNavName, iSize, "Rocket Jump Node");
		case CBNavType_SniperPos: Format(sNavName, iSize, "Sniper Position Node");
		case CBNavType_FallBackPos: Format(sNavName, iSize, "Fallback Position Node");
		default: Format(sNavName, iSize, "INVALID NODE NAME");
	}
}

stock char[] GetLiteralTeamName(int iTeam, char[] sTeamName, int iSize)
{
	switch (iTeam)
	{
		case 0: Format(sTeamName, iSize, "Both");
		case 2: Format(sTeamName, iSize, "RED");
		case 3: Format(sTeamName, iSize, "BLU");
		default: Format(sTeamName, iSize, "INVALID TEAM NAME");
	}
}

stock bool CanProceedMenu(int client, CBNavType NavType)
{
	switch (NavType)
	{
		case CBNavType_RocketJump:
		{
			if (NavPositionSelected[client] && NavAngleSelected[client])
				return true;
		}
		case CBNavType_SniperPos:
		{
			if (NavPositionSelected[client])
				return true;
		}
	}
	return false;
}




public Action OnPlayerJoinTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	//int iTeam = GetEventInt(event, "team");
	//char strTeamName[32];
	//GetTeamName(iClient, strTeamName, sizeof strTeamName);
	char botname[64];

	if (IsCustomBot(iClient) && iClient != 0)
	{
		if (BotIndex[iClient] > 0)
		{
			GetBotName(iClient, botname, sizeof botname);
			//PrintToChatAll("%s was automatically assigned to team %s", botname, strTeamName);
			SetEventBroadcast(event, true);
		}
	}
	return Plugin_Continue;
}

public Action UserMessage_SayText2(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
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

public void OnMapStart()
{
	KeyValues kv = new KeyValues("BotIndexes");
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof sPath, "configs/botindexes.txt");
	kv.ImportFromFile(sPath);

	kv.GetString("message", sBotDisconnectMessage, sizeof sBotDisconnectMessage, "Kicked from server");
	delete kv;

	b5CPMap = FindControlPoints();

	CreateTimer(35.0, TimerCheckPlayers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public bool FindControlPoints()
{
	int ent = MaxClients+1;
	int count;
	while ((ent = FindEntityByClassname(ent, "team_control_point")) != -1)
	{
		count++;
	}
	if (count >= 5)
		return true;

	return false;
}

public Action CMDSpawnBot(int client, int args)
{
	char sCommand[8];
	GetCmdArg(1, sCommand, sizeof sCommand);
	iForcedIndex = StringToInt(sCommand);
	ShouldBotHook = true;
	ServerCommand("tf_bot_add 1");
}

public Action TimerCheckPlayers(Handle pTimer)
{
	if (GetConVarInt(g_SpawnBots) == 0) return Plugin_Continue;
	int botcount = GetConVarInt(g_BotQuota);
	if (botcount >= 4)
	{
		int leave = GetRandomInt(1, 100);
		if (leave <= 14)
		{
			botcount--;
			char comm[64];
			Format(comm, sizeof comm, "tf_bot_quota %i", botcount);
			ServerCommand(comm);
		}
	}
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))
		{
			count++;
		}
	}
	if (count > 0)
	{
		int chance = GetRandomInt(1, 100);
		if (chance <= 21 && botcount < MAXBOTS)
		{
			botcount++;
			char comm2[64];
			Format(comm2, sizeof comm2, "tf_bot_quota %i", botcount);
			ShouldBotHook = true;
			ServerCommand(comm2);
		}
	}
	else if(count == 0)
	{
		ShouldBotHook = false;
		ServerCommand("tf_bot_quota 0");
	}
	return Plugin_Continue;
}

public void OnMapEnd()
{
	FreeBotIndexes();
}

public void FreeBotIndexes()
{
	for (int index = 1; index <= MAXBOTS; index++)
	{
		IndexTaken[index] = false;
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
	if (IsFakeClient(client))
	{
		IsScoped[client] = false;
		HeadShotDelay[client] = FAR_FUTURE;
		if (ShouldBotHook)
			BotIndex[client] = GetFreeBotIndex(iForcedIndex);

		//PrintToChatAll("index = %i", BotIndex[client]);
		if (BotIndex[client])
		{
			CreateTimer(0.2, SetBotVars, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		ShouldBotHook = false;
	}
}

public Action SetBotVars(Handle bTimer, int bot)
{
	if (IsValidClient(bot) && IsFakeClient(bot))
	{
		if (BotIndex[bot] > 0)
		{
			KeyValues kv = new KeyValues("BotIndexes");

			char sPath[PLATFORM_MAX_PATH];
			BuildPath(Path_SM, sPath, sizeof sPath, "configs/botindexes.txt");
			kv.ImportFromFile(sPath);

			char sBotIndex[8];
			IntToString(BotIndex[bot], sBotIndex, sizeof sBotIndex);

			if (!kv.JumpToKey(sBotIndex))
			{
				//PrintToChatAll("Could not find bot index: %i", BotIndex[bot]);
				delete kv;
				return;
			}

			kv.GetString("name", sBotName[bot], MAX_NAME_LENGTH);
			SetClientInfo(bot, "name", sBotName[bot]);
			PrintToChatAll("%s has joined the game", sBotName[bot]);
			PrintToChatAll("%s was automatically assigned to team %s", sBotName[bot], (GetClientTeam(bot) == 2) ? "RED" : "BLU");

			//Set bot behavior
			AimDelayAdd[bot] = kv.GetFloat("aimdelay", 0.0); //Cooldown on autoaim usage
			AimFOV[bot] = kv.GetFloat("aimfov", 180.0); //FoV for target acquisition
			Inaccuracy[bot] = kv.GetFloat("inaccuracy", 0.0); //deviation to add onto autoaim

			AggroDelay[bot] = kv.GetFloat("aggrotime", 0.0); //How long a target is aggro'd for
			iClassPriority[bot] = kv.GetNum("prioritize"); //Class priority
			AttackRange[bot] = kv.GetFloat("range", 800.0); //Preferred combat range

			flSniperAimTime[bot] = kv.GetFloat("aimtime", 1.0); //Steady rate for snipers
			flHealthThreshold[bot] = kv.GetFloat("health_threshold", 0.2); //Health threshold for when bots will try to flee

			flHeightThreshold[bot] = kv.GetFloat("height", 0.0); //Soldier height threshold

			if (kv.GetNum("preferjump") == 1)
				PreferJump[bot] = true;
			else
				PreferJump[bot] = false;

			delete kv;
			return;
		}
	}
}

stock char[] GetBotName(int bot, char[] botname, int buffer)
{
	KeyValues kv = new KeyValues("BotIndexes");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof sPath, "configs/botindexes.txt");
	kv.ImportFromFile(sPath);

	char sBotIndex[8];
	IntToString(BotIndex[bot], sBotIndex, sizeof sBotIndex);

	if (!kv.JumpToKey(sBotIndex))
	{
		delete kv;
		return;
	}

	kv.GetString("name", botname, buffer);
	delete kv;
}

stock int GetFreeBotIndex(int iIndex = 0)
{
	if (iIndex > 0)
	{
		if (iIndex < MAXBOTS)
			IndexTaken[iIndex] = true;

		iForcedIndex = 0;
		return iIndex;
	}
	bool foundindex = false;
	if (IndexSlotsFree())
	{
		while (!foundindex)
		{
			if (!IndexSlotsFree()) break;
			int index = GetRandomInt(1, MAXBOTS);
			if (!IndexTaken[index])
			{
				if (BotPresetExists(index))
				{
					foundindex = true;
					IndexTaken[index] = true;

					iForcedIndex = 0;
					return index;
				}
				else
					continue;
			}
			else
			{
				continue;
			}
		}
	}
	iForcedIndex = 0;
	return 0;
}

public void OnClientDisconnect(int client)
{
	if (IsFakeClient(client))
	{
		if (BotIndex[client] <= MAXBOTS)
			IndexTaken[BotIndex[client]] = false;
		ClearBotVars(client);
	}
}

public void ClearBotVars(int client)
{
	if (IsFakeClient(client))
	{
		Inaccuracy[client] = 0.0;
		AggroTime[client] = 0.0;
		AggroDelay[client] = 0.0;
		AimFOV[client] = 0.0;
		AimDelay[client] = 0.0;
		AimDelayAdd[client] = 0.0;
		iClassPriority[client] = 1;
		iAntiAim[client] = 0;
		PreferJump[client] = false;
		bFleeing[client] = false;
		flSniperAimTime[client] = 1.0;
		flHealthThreshold[client] = 0.2;
		NoiseMaker[client] = 0;
	}
}

public bool IndexSlotsFree()
{
	for (int index = 1; index <= MAXBOTS; index++)
	{
		if (!IndexTaken[index] && BotPresetExists(index))
		{
			return true;
		}
	}
	//PrintToChatAll("No valid indexes found");
	return false;
}

public bool BotPresetExists(int preset)
{
	KeyValues kv = new KeyValues("BotIndexes");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof sPath, "configs/botindexes.txt");
	kv.ImportFromFile(sPath);

	char sBotIndex[8];
	IntToString(preset, sBotIndex, sizeof sBotIndex);

	if (kv.JumpToKey(sBotIndex))
	{
		delete kv;
		return true;
	}
	delete kv;
	return false;
}

public Action RocketJump(int bot, int args)
{
	for (int iBot = 1; iBot <= MaxClients; iBot++)
	{
		if (IsFakeClient(iBot) && IsValidClient(iBot) && TF2_GetPlayerClass(iBot) == TFClass_Soldier)
		{
			JumpTimer[iBot] = GetEngineTime()+0.1;
		}
	}
}

public Action PlayerResupply(Handle EventH, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(GetEventInt(EventH, "userid"));

	if (IsCustomBot(bot))
	{
		TFClassType class = TF2_GetPlayerClass(bot);
		if (BotIndex[bot] > 0)
			SetupLoadout(bot, class);
		else if (bIsHookedBot[bot])
			SetBotClass(bot, iBotClass[bot], iBotOffClass[bot]);

		//Call Resupply Forward
		Call_StartForward(g_BotResupply);

		Call_PushCell(bot);
		Call_PushCell(BotIndex[bot]);
		Call_PushCell(bIsHookedBot[bot]);

		Call_Finish();
	}
	return Plugin_Continue;
}

public Action CMDSetHP(int client, int args)
{
	new String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int	target_count;
	bool targets = true;
	bool tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		targets = false;
	}

	if (targets)
	{
		for (int i = 0; i < target_count; i++)
		{
			int target = target_list[i];

			if (IsPlayerAlive(target) && IsValidClient(target))
			{
				SetHP(target);
			}
		}
	}
	else
	{
		if (IsPlayerAlive(client) && IsValidClient(client))
		{
			SetHP(client);
		}
	}
	return Plugin_Handled;
}

public int SetBotClass(int bot, int class, int offclass)
{
	if (GetRandomInt(1, 100) <= 35)
		class = offclass;

	if (class == 5) //Medics
	{
		if (GetPlayersOnTeam(GetClientTeam(bot)) < 3)
			class = offclass;
	}

	SetEntProp(bot, Prop_Send, "m_iDesiredPlayerClass", class);
	TF2_SetPlayerClass(bot, view_as<TFClassType>(class));

	return class;
}

public void SetupLoadout(int bot, TFClassType class)
{
	if (IsValidClient(bot) && IsFakeClient(bot))
	{
		if (BotIndex[bot] > 0)
		{
			KeyValues kv = new KeyValues("BotIndexes");

			char sPath[PLATFORM_MAX_PATH];
			BuildPath(Path_SM, sPath, sizeof sPath, "configs/botindexes.txt");
			kv.ImportFromFile(sPath);

			char sBotIndex[8];
			IntToString(BotIndex[bot], sBotIndex, sizeof sBotIndex);

			char pWeaponName[64]; //Primary classname
			char sWeaponName[64]; //Secondary classname
			char mWeaponName[64]; //Melee classname

			//Class Settings
			char sClassName[64];

			//Item Indexes
			int pWeapon, sWeapon, mWeapon, hat, cosmetic1, cosmetic2;

			//Primary attribs
			int pEffect, pKillstreak, pAussie, pSheen, pKEffect; //pUnusual;

			//Secondary attribs
			int sEffect, sKillstreak, sAussie, sSheen, sKEffect; // sUnusual;

			//Melee attribs
			int mEffect, mKillstreak, mAussie, mSheen, mKEffect; //mUnusual;

			//Hat attribs
			int HatEffect, HatPaintR, HatPaintB;

			//Cosmetic1 attribs
			int cEffect1, cPaint1R, cPaint1B;

			//Cosmetic2 attribs
			int cEffect2, cPaint2R, cPaint2B;


			if (!kv.JumpToKey(sBotIndex))
			{
				//PrintToChatAll("Could not find bot index: %i", BotIndex[bot]);
				delete kv;
				return;
			}

			// Do we prefer melee
			if (kv.GetNum("melee") == 1)
				bPreferMelee[bot] = true;
			else
				bPreferMelee[bot] = false;

			// Do we prefer to shoot ground positions
			if (kv.GetNum("aimground") == 1)
				bAimGround[bot] = true;
			else
				bAimGround[bot] = false;

			iBotClass[bot] = kv.GetNum("class");
			iBotOffClass[bot] = kv.GetNum("offclass");

			int SelectedClass = SetBotClass(bot, iBotClass[bot], iBotOffClass[bot]);

			GetLiteralClassName(SelectedClass, sClassName, sizeof sClassName);

			if (StrEqual(sClassName, "sniper"))
				AttackRange[bot] *= 50.0;
			else
				AttackRange[bot] = GetBotAttackRange(bot);

			iAntiAim[bot] = kv.GetNum("antiaim", 0);

			if (kv.GetNum("noisemaker") > 0)
			{
				NoiseMaker[bot] = kv.GetNum("noisemaker");
				NoiseMakerDelayAdd[bot] = kv.GetFloat("noisemaker_delay", 1.0);
			}

			//Select proper class loadout
			if (kv.JumpToKey(sClassName))
			{
				//Setup Weapons
				if (kv.JumpToKey("weapons"))
				{
					//PrintToChatAll("Found weapons for bot index: %i", BotIndex[bot]);
					if (kv.JumpToKey("primary"))
					{
						//PrintToChatAll("Found primary weapon for bot");
						kv.GetString("classname", pWeaponName, sizeof pWeaponName);
						pWeapon = kv.GetNum("index");
						//pUnusual = kv.GetNum("unusual");
						pEffect = kv.GetNum("effect", 0);
						pKillstreak = kv.GetNum("killstreak", 0);
						pAussie = kv.GetNum("aussie", 0);
						pSheen = kv.GetNum("sheen", 0);
						pKEffect = kv.GetNum("kEffect", 0);

						TF2_RemoveWeaponSlot(bot, TFWeaponSlot_Primary);
						if(StrContains(pWeaponName, "tf_wearable" , false) != -1)
							CreateHat(bot, pWeapon);
						else
							SpawnBotWeapon(bot, pWeaponName, pWeapon, pEffect, pKillstreak, pAussie, pSheen, pKEffect, 0);

						//PrintToChatAll("Found primary weapon with index: %i\nAttributes:\n - Killstreak: %i\n - Sheen: %i\n - KEffect: %i\n - Aussie: %i\n - Effect: %i", pWeapon, pKillstreak, pSheen, pKEffect, pAussie, pEffect);
						kv.GoBack();
					}
					if (kv.JumpToKey("secondary"))
					{
						//PrintToChatAll("Found secondary weapon");
						kv.GetString("classname", sWeaponName, sizeof sWeaponName);
						sWeapon = kv.GetNum("index");
						//sUnusual = kv.GetNum("unusual");
						sEffect = kv.GetNum("effect", 0);
						sKillstreak = kv.GetNum("killstreak", 0);
						sAussie = kv.GetNum("aussie", 0);
						sSheen = kv.GetNum("sheen", 0);
						sKEffect = kv.GetNum("kEffect", 0);

						TF2_RemoveWeaponSlot(bot, TFWeaponSlot_Secondary);
						if (StrContains(sWeaponName, "tf_wearable" , false) != -1)
							CreateHat(bot, sWeapon);
						else
							SpawnBotWeapon(bot, sWeaponName, sWeapon, sEffect, sKillstreak, sAussie, sSheen, sKEffect, 1);

						kv.GoBack();
					}
					if (kv.JumpToKey("melee"))
					{
						//PrintToChatAll("Found melee weapon");
						kv.GetString("classname", mWeaponName, sizeof mWeaponName);
						mWeapon = kv.GetNum("index");
						mEffect = kv.GetNum("effect", 0);
						mKillstreak = kv.GetNum("killstreak", 0);
						mAussie = kv.GetNum("aussie", 0);
						mSheen = kv.GetNum("sheen", 0);
						mKEffect = kv.GetNum("kEffect", 0);

						TF2_RemoveWeaponSlot(bot, TFWeaponSlot_Melee);
						if (StrContains(mWeaponName, "tf_wearable" , false) != -1)
							CreateHat(bot, mWeapon);
						else
							SpawnBotWeapon(bot, mWeaponName, mWeapon, mEffect, mKillstreak, mAussie, mSheen, mKEffect, 2);

						kv.GoBack();
					}
					kv.GoBack();
					TF2_SwitchToSlot(bot, TFWeaponSlot_Primary);
				}
				if (kv.JumpToKey("cosmetics"))
				{
					if (kv.JumpToKey("hat"))
					{
						//PrintToChatAll("found hat");
						hat = kv.GetNum("index");
						HatEffect = kv.GetNum("effect", 0);
						HatPaintR = kv.GetNum("paint", 0);
						HatPaintB = kv.GetNum("paint2", 0);

						CreateHat(bot, hat, _, _, HatEffect, HatPaintR, HatPaintB);
						kv.GoBack();
					}
					if (kv.JumpToKey("cosmetic1"))
					{
						//PrintToChatAll("found cosmetic");
						cosmetic1 = kv.GetNum("index");
						cEffect1 = kv.GetNum("effect");
						cPaint1R = kv.GetNum("paint");
						cPaint1B = kv.GetNum("paint2");

						CreateHat(bot, cosmetic1, _, _, cEffect1, cPaint1R, cPaint1B);
						kv.GoBack();
					}
					if (kv.JumpToKey("cosmetic2"))
					{
						//PrintToChatAll("Found cosmetic2");
						cosmetic2 = kv.GetNum("index");
						cEffect2 = kv.GetNum("effect");
						cPaint2R = kv.GetNum("paint");
						cPaint2B = kv.GetNum("paint2");

						CreateHat(bot, cosmetic2, _, _, cEffect2, cPaint2R, cPaint2B);
						kv.Rewind();
						delete kv;
					}
				}
			}
			if (!HasShield(bot))
			{
				shield[bot] = -1;
			}
			else
			{
				//PrintToChatAll("bot has shield: %i", shield[bot]);
			}
			delete kv;
			return;
		}

		//Regular TFBots
		int chance = GetRandomInt(1, 100);
		switch (class)
		{
			case TFClass_Soldier:
			{
				if (chance <= 50)
				{
					TF2_RemoveWeaponSlot(bot, TFWeaponSlot_Primary);
					CreateWeapon(bot, "tf_weapon_rocketlauncher_directhit", 127, 1, 6, "", true, true);
				}
				TF2_RemoveWeaponSlot(bot, TFWeaponSlot_Melee);
				CreateWeapon(bot, "tf_weapon_shovel", 416, 1, 6, "", true, true);
			}
			case TFClass_Medic:
			{
				if (chance <= 50)
				{
					TF2_RemoveWeaponSlot(bot, TFWeaponSlot_Secondary);
					CreateWeapon(bot, "tf_weapon_medigun", 35, 1, 6, "", true, true);
				}
				TF2_RemoveWeaponSlot(bot, TFWeaponSlot_Primary);
				CreateWeapon(bot, "tf_weapon_crossbow", 305, 1, 6, "", true, true);
			}
			case TFClass_Scout:
			{
				CreateHat(bot, 538, 6); //Killer Exclusive
			}
		}
		int weapon = GetPlayerWeaponSlot(bot, TFWeaponSlot_Primary);
		int killstreak = GetRandomInt(0, 10);
		if (killstreak <= 5)
			ApplyKillstreak(bot, weapon);
	}
	return;
}

stock void SpawnBotWeapon(int bot, char[] classname, int index, int effect, int killstreak, int aussie, int sheen, int kEffect, int WeaponSlot, int quality = 6)
{
	if (IsValidClient(bot) && IsFakeClient(bot))
	{
		TF2_RemoveWeaponSlot(bot, WeaponSlot);
		int bot_wep = CreateWeapon(bot, classname, index, 1, quality, "", true, true);
		if (IsValidEntity(bot_wep) && bot_wep > MaxClients)
		{
			if (effect != 0)
				TF2Attrib_SetByDefIndex(bot_wep, 134, float(effect));

			if (killstreak != 0)
			{
				TF2Attrib_SetByName(bot_wep, "killstreak tier", 1.0);
				if (sheen != 0)
					TF2Attrib_SetByDefIndex(bot_wep, 2014, float(sheen));
				if (kEffect != 0)
					TF2Attrib_SetByDefIndex(bot_wep, 2013, float(kEffect));
			}

			if (aussie == 1)
			{
				//PrintToChatAll("Aussie Weapon");
				TF2Attrib_SetByName(bot_wep, "is australium item", 1.0);
				TF2Attrib_SetByName(bot_wep, "item style override", 1.0);
			}
		}
		TF2_SwitchToSlot(bot, WeaponSlot);
	}
}

public void ApplyKillstreak(int bot, int weapon)
{
	if (IsValidEntity(weapon) && weapon > MaxClients)
	{
		int sheen = GetRandomInt(-5, 7);
		TF2Attrib_SetByName(weapon, "killstreak tier", 1.0);
		if (sheen > 0)
		{
			TF2Attrib_SetByDefIndex(weapon, 2014, float(sheen));
			int effect = GetRandomInt(2002, 2008);
			TF2Attrib_SetByDefIndex(weapon, 2013, float(effect));
		}
	}
}

public int GetPlayersOnTeam(int team)
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (GetClientTeam(i) == team)
				count++;
		}
	}
	return count;
}

public Action OnTakeDamage(int bot, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (IsValidClient(bot))
	{
		if (IsCustomBot(bot))
		{
			bool IsCritical = false;
			float newDamage = damage;
			if (damagetype == DMG_CRIT)
				IsCritical = true;

			Call_StartForward(g_BotTakeDamage);

			Call_PushCell(bot);
			Call_PushCell(BotIndex[bot]);
			Call_PushCell(bIsHookedBot[bot]);
			Call_PushCell(damage);
			Call_PushCell(IsCritical);
			Call_PushCell(attacker);
			Call_PushCell(inflictor);

			Call_Finish(newDamage);

			damage = newDamage;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action PlayerHurt(Handle pEvent, const char[] name, bool dontBroadcast)
{
	//int attacker = GetClientOfUserId(GetEventInt(pEvent, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(pEvent, "userid"));

	if (IsValidClient(victim))
	{
		if (IsCustomBot(victim))
			CallMedicDelay[victim] = GetEngineTime() + (GetRandomFloat(1.0, 6.0));

		int damage = GetEventInt(pEvent, "damageamount");
		DamageTaken[victim] += damage;
		DamageDelay[victim] = GetEngineTime() + 1.0;
		if (DamageDelay[victim] <= GetEngineTime())
			DamageTaken[victim] = 0;
	}
}

public Action OnPlayerDisconnect(Handle dEvent, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(GetEventInt(dEvent, "userid"));

	if (IsCustomBot(bot))
	{
		char sName[64];
		GetClientName(bot, sName, sizeof sName);
		SetEventBroadcast(dEvent, true);
		PrintToChatAll("%s left the game (%s)", sName, sBotDisconnectMessage);
	}
	return Plugin_Continue;
}

public Action OnNameChange(Handle nEvent, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(GetEventInt(nEvent, "userid"));

	if (IsCustomBot(bot))
	{
		SetEventBroadcast(nEvent, true);
	}
	return Plugin_Continue;
}

public Action PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int bot = GetClientOfUserId(GetEventInt(event, "userid"));
	int critType = GetEventInt(event, "crit_type");

	if (IsValidClient(attacker))
	{
		if (IsFakeClient(attacker))
		{
			if (BotIndex[attacker] == 1) //taunt after every kill scout
			{
				FakeClientCommand(attacker, "voicemenu 2 6");
			}
			if (BotIndex[attacker] == 1000)
			{
				FakeClientCommand(attacker, "say Big Chungus");
			}
		}
	}
	if (IsCustomBot(bot))
	{
		//Call OnBotDeath
		Call_StartForward(g_BotDeath);

		Call_PushCell(bot);
		Call_PushCell(BotIndex[bot]);
		Call_PushCell(bIsHookedBot[bot]);
		Call_PushCell(attacker);
		Call_PushCell(critType);

		Call_Finish();
	}
	return Plugin_Continue;
}

stock float[] moveForward(float vel[3], float MaxSpeed)
{
	vel[0] = MaxSpeed;
	return vel;
}

stock float[] moveBackwards(float vel[3], float MaxSpeed)
{
	vel[0] = -MaxSpeed;
	return vel;
}

stock float[] moveRight(float vel[3], float MaxSpeed)
{
	vel[1] = MaxSpeed;
	return vel;
}

stock float[] moveLeft(float vel[3], float MaxSpeed)
{
	vel[1] = -MaxSpeed;
	return vel;
}

public Action RoundStarted(Handle event, const char[] name, bool dontBroadcast)
{
	ReloadNodes();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsCustomBot(i))
		{
			CreateTimer(0.25, ClientTimer, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	RoundInProgress = true;
	if (IsControlPoints())
		Captures = 0;
}

public Action ClientTimer(Handle Timer, int bot)
{
	if (!RoundInProgress || !IsValidClient(bot) || !IsCustomBot(bot))
		return Plugin_Stop;

	if (PathObstructed(bot))
	{
		JumpTimer[bot] = GetEngineTime() + 0.2;
	}
	return Plugin_Continue;
}

public Action OnRoundEnd(Handle wEvent, const char[] name, bool dontBroadcast)
{
	RoundInProgress = false;
}

public void ReloadNodes()
{
	int control = MaxClients+1;
	while ((control = FindEntityByClassname(control, "team_control_point")) != -1)
	{
		bPointLocked[control] = true;
	}
	ClearNavPositions();
	char currentMap[PLATFORM_MAX_PATH];
	char sFallback[64] = "";
	GetCurrentMap(currentMap, sizeof(currentMap));

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof sPath, "configs/navpoints/%s.txt", currentMap);

	if (!FileExists(sPath))
	{
		LogMessage("No navigation data found for map %s", currentMap);
		return;
	}

	KeyValues kv = new KeyValues("NavPoints");
	kv.ImportFromFile(sPath);

	//Establish Sniper Positions
	if (kv.JumpToKey("sniper"))
	{
		float flSnipeOrigin[MAXSNIPEPOS][3];
		int SnipePos[MAXSNIPEPOS];
		for (int iPos = 0; iPos < MAXSNIPEPOS; iPos++)
		{
			char sIndex[8];
			IntToString(iPos, sIndex, sizeof sIndex);
			if (kv.JumpToKey(sIndex))
			{
				SnipePosCount++;
				kv.GetVector("Pos", flSnipeOrigin[iPos]);
				SnipePos[iPos] = CreateEntityByName("func_tfbot_hint");
				DispatchKeyValue(SnipePos[iPos], "team", "0");
				switch (kv.GetNum("team", 0))
				{
					case 2: DispatchKeyValue(SnipePos[iPos], "team", "2");
					case 3: DispatchKeyValue(SnipePos[iPos], "team", "3");
					default: DispatchKeyValue(SnipePos[iPos], "team", "0");
				}
				TeleportEntity(SnipePos[iPos], flSnipeOrigin[iPos], NULL_VECTOR, NULL_VECTOR);
				kv.GoBack();
			}
			else
			{
				break;
			}
		}
		kv.GoBack();
	}

	//Establish Rocket Jump Points
	if (kv.JumpToKey("rj"))
	{
		float defAng[3] = {75.0, 160.0, 0.0};
		for (int rjPos = 0; rjPos < MAXRJPOS; rjPos++)
		{
			char sIndex[8];
			IntToString(rjPos, sIndex, sizeof sIndex);
			if (kv.JumpToKey(sIndex))
			{
				RJPosCount++;
				RJPosExists[rjPos] = true;
				kv.GetVector("pos", RJPos[rjPos]);
				kv.GetVector("ang", RJAngles[rjPos], defAng);
				kv.GetVector("NewAng", RJNewAngles[rjPos], ZeroVec);
				RJDistance[rjPos] = kv.GetFloat("distance", 100.0);
				RJAir[rjPos] = kv.GetNum("Air", 0);
				RJDifficulty[rjPos] = kv.GetNum("difficulty", 0);
				RJTeam[rjPos] = kv.GetNum("team", 0);
				kv.GoBack();
			}
			else
			{
				break;
			}
		}
		kv.GoBack();
	}

	//Initialize Fallback points only for CP maps
	if (IsControlPoints())
	{
		if (kv.JumpToKey("fallback"))
		{
			for (int fb = 0; fb < MAXFALLBACK; fb++)
			{
				char sIndex[8];
				IntToString(fb, sIndex, sizeof sIndex);
				if (kv.JumpToKey(sIndex))
				{
					FallBackCount++;
					kv.GetVector("pos", FallBackPos[fb]);
					NodeRadius[fb] = kv.GetFloat("radius", 300.0);
					FallBackTeam[fb] = kv.GetNum("team", 0);
					//LogMessage("FallBack Point %i is team: %i", fb, FallBackTeam[fb]);
					kv.GoBack();
				}
				else
					break;
			}
		}
		kv.GoBack();

		Format(sFallback, sizeof sFallback, "\n -%i Fallback Positions", FallBackCount);
	}
	kv.Rewind();
	delete kv;

	LogMessage("Found %i Sniper nav points and %i Rocket Jump positions for map %s.", SnipePosCount, RJPosCount, currentMap);
}

public void ClearNavPositions()
{
	//Clear nav points
	SnipePosCount = 0;
	RJPosCount = 0;
	FallBackCount = 0;

	//Set RJ positions as not existing
	for (int i = 0; i < MAXRJPOS; i++)
	{
		if (RJPosExists[i])
			RJPosExists[i] = false;
	}
}

public Action TF2_CalcIsAttackCritical(int bot, int weapon, char[] weaponname, bool& result)
{
	if (IsCustomBot(bot))
	{
		//float critchance = GetEntPropFloat(weapon, Prop_Send, "m_flLastCritCheckTime");
		//PrintToChatAll("Crit Chance: %.1f", critchance);
		TFClassType class = TF2_GetPlayerClass(bot);
		int health = GetClientHealth(bot);
		int jumpsuccess = 1;
		int wIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

		//Call OnBotAttack
		Action aResult = Plugin_Continue;
		Call_StartForward(g_BotAttack);

		Call_PushCell(bot);
		Call_PushCell(BotIndex[bot]);
		Call_PushCell(bIsHookedBot[bot]);
		Call_PushCell(wIndex);
		Call_PushCell(result);

		Call_Finish(aResult);

		if (aResult == Plugin_Continue)
		{
			switch (class)
			{
				case TFClass_Soldier:
				{
					if (AimDelay[bot] <= GetEngineTime())
					{
						if (IsWeaponSlotActive(bot, 0))
							SetTargetViewAngles(bot, false, true);
						else
							SetTargetViewAngles(bot);
						AimDelay[bot] = GetEngineTime() + AimDelayAdd[bot];
					}
					JumpDelayCount[bot]--;
					int jumpchance = GetRandomInt(1, 10);
					int rocketjump = GetRandomInt(1, 10);
					if (PreferJump[bot])
						jumpsuccess = 5;

					if (rocketjump <= jumpsuccess && JumpDelayCount[bot] <= 0 && health >= 50)
					{
						RJDelay[bot] = GetEngineTime()+0.8;
						JumpDelayCount[bot] = 2;
					}
					else if (jumpchance <= 8)
					{
						Jump[bot] = true;
					}
				}
				case TFClass_Scout:
				{
					if (AimDelay[bot] <= GetEngineTime())
					{
						SetTargetViewAngles(bot);
						AimDelay[bot] = GetEngineTime() + AimDelayAdd[bot];
					}
					if (BotIndex[bot] == 1) //lime scout
					{
						int crit = GetRandomInt(1, 10);
						if (crit <= 3)
						{
							result = true;
							return Plugin_Changed;
						}
					}
					JumpDelayCount[bot]--;
					int jumpchance = GetRandomInt(1, 10);
					if (PreferJump[bot])
						jumpsuccess = 7;

					if (jumpchance <= jumpsuccess && JumpDelayCount[bot] <= 0)
					{
						bScoutSingleJump[bot] = true;
						JumpTimer[bot] = GetEngineTime()+0.1;
						JumpDelayCount[bot] = 2;
					}
				}
				case TFClass_Sniper:
				{
					if (IsWeaponSlotActive(bot, 0) && iAntiAim[bot] == 0 && (AimDelay[bot] <= GetEngineTime()))
					{
						switch (wIndex)
						{
							case 56, 1005, 1092:
							{
								SetTargetViewAngles(bot, true, true);
								AimDelay[bot] = GetEngineTime() + AimDelayAdd[bot];
							}
							default:
							{
								SetTargetViewAngles(bot, true);
								AimDelay[bot] = GetEngineTime() + AimDelayAdd[bot];
							}
						}
					}
				}
				case TFClass_DemoMan:
				{
					JumpDelayCount[bot]--;
					int jumpchance = GetRandomInt(1, 10);
					if (PreferJump[bot])
						jumpsuccess = 8;

					else if (jumpchance <= jumpsuccess)
					{
						Jump[bot] = true;
					}
					if (AimDelay[bot] <= GetEngineTime())
					{
						if (IsWeaponSlotActive(bot, TFWeaponSlot_Primary))
						{
							SetTargetViewAngles(bot, false, true);
							AimDelay[bot] = GetEngineTime() + AimDelayAdd[bot];
						}
					}
				}
				case TFClass_Medic:
				{
					if (AimDelay[bot] <= GetEngineTime())
					{
						if (IsWeaponSlotActive(bot, TFWeaponSlot_Primary))
						{
							SetTargetViewAngles(bot, false, true);
							AimDelay[bot] = GetEngineTime() + AimDelayAdd[bot];
						}
					}
				}
				case TFClass_Pyro:
				{
					if (AimDelay[bot] <= GetEngineTime())
					{
						switch (wIndex)
						{
							case 39, 351, 595, 740, 1081: //flareguns
							{
								SetTargetViewAngles(bot, false, true, false);
								AimDelay[bot] = GetEngineTime() + AimDelayAdd[bot];
							}
							default:
							{
								SetTargetViewAngles(bot);
								AimDelay[bot] = GetEngineTime() + AimDelayAdd[bot];
							}
						}
					}
				}
				case TFClass_Spy:
				{
					if (AimDelay[bot] <= GetEngineTime())
					{
						switch (wIndex)
						{
							case 61, 1006: //amby
							{
								SetTargetViewAngles(bot, true);
								AimDelay[bot] = GetEngineTime() + AimDelayAdd[bot];
							}
							default:
							{
								SetTargetViewAngles(bot);
								AimDelay[bot] = GetEngineTime() + AimDelayAdd[bot];
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

stock void DoAntiAim(int client, int aimtype, bool lagComp = true)
{
	float angle[3];
	GetClientEyeAngles(client, angle);

	if (lagComp)
	{
		SetEntProp(client, Prop_Data, "m_bLagCompensation", true);
		SetEntProp(client, Prop_Data, "m_bPredictWeapons", true);
	}
	else
	{
		SetEntProp(client, Prop_Data, "m_bLagCompensation", false);
		SetEntProp(client, Prop_Data, "m_bPredictWeapons", false);
	}
	switch (aimtype)
	{
		case 1:
		{
			angle[1] += 15.5;
			angle[0] = 70.0;
		}
		case 2:
		{
			angle[1] += 20.0;
			angle[0] = (GetRandomInt(1, 2) == 1 ? 89.0 : -89.0);
		}
	}

	TeleportEntity(client, NULL_VECTOR, angle, NULL_VECTOR);
}

/***********************************************************************************************************

    BOT NAVIGATION

***********************************************************************************************************/


//Check to see if bot is stuck on an object
stock bool PathObstructed(int client)
{
	float clPos[3], clEyePos[3];
	float vecBoxMin[3] = {-30.0, -30.0, 15.0};
	float vecBoxMax[3] = {30.0, 30.0, 40.0};
	GetClientAbsOrigin(client, clPos);
	Handle HullTrace = TR_TraceHullFilterEx(clPos, clPos, vecBoxMin, vecBoxMax, MASK_PLAYERSOLID, CheckCollision, client); //Check around bot to see if they are being blocked
	if (TR_DidHit(HullTrace))
	{
		GetClientEyePosition(client, clEyePos);
		float vecBoxMin2[3] = {-50.0, -50.0, -5.0};
		float vecBoxMax2[3] = {50.0, 50.0, 20.0};
		Handle EyeTrace = TR_TraceHullFilterEx(clEyePos, clEyePos, vecBoxMin2, vecBoxMax2, MASK_PLAYERSOLID, CheckCollision, client); //Check around eye height, make sure it's an object that can be jumped over
		if (TR_DidHit(EyeTrace))
		{
			CloseHandle(EyeTrace);
			CloseHandle(HullTrace);

			iObstructions[client]++;

			//We can't jump over an object at eye level, so do not even try to jump
			return false;
		}
		CloseHandle(EyeTrace);
		CloseHandle(HullTrace);

		iObstructions[client] = 0;

		if (TF2_GetPlayerClass(client) == TFClass_Scout)
		{
			bScoutSingleJump[client] = true;
		}
		//Object is not at eye level, so we can jump over it
		return true;
	}
	CloseHandle(HullTrace);

	iObstructions[client] = 0;

	//Nothing to jump over
	return false;
}

public bool CheckCollision(int entity, int contentsMask, any iOwner)
{
	if (IsValidClient(entity))
		return false;

	char class[64];
	GetEntityClassname(entity, class, sizeof(class));

	if (StrEqual(class, "prop_dynamic"))
	{
		char modelname[64];
		GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof modelname);
		//bInCaptureArea[iOwner] = true;
		//return false;
	}

	if (StrEqual(class, "entity_medigun_shield"))
	{
		if (GetEntProp(entity, Prop_Send, "m_iTeamNum") == GetClientTeam(iOwner))
		{
			return false;
		}
	}
	else if (StrEqual(class, "func_respawnroomvisualizer"))
	{
		return false;
	}
	else if (StrContains(class, "tf_projectile_", false) != -1)
	{
		return false;
	}
	return !(entity == iOwner);
}

stock void DoStutterStep(int client, float velocity[3], TFClassType class, float delay = 0.0)
{
	if (StepDelay[client] <= GetEngineTime())
	{
		int strafedir = GetRandomInt(1, 2);
		if (strafedir == 1)
			StrafeSpeed[client] = GetPlayerMaxSpeed(client) * -1;
		else
			StrafeSpeed[client] = GetPlayerMaxSpeed(client);

		if (class == TFClass_Sniper && TF2_IsPlayerInCondition(client, TFCond_Slowed))
		{
			if (TargetIsValid(client, BotAggroTarget[client]))
				StepDelay[client] = GetEngineTime() + GetRandomFloat(0.1, 0.4);
			else
				return;
		}
		else
			StepDelay[client] = GetEngineTime() + ((delay > 0.0) ? delay : GetRandomFloat(0.2, 0.6));
	}
	moveRight(velocity, StrafeSpeed[client]);
}

//Find nearest FallBack node for each team
stock void SetFallBackPoints()
{
	int ent = MaxClients+1;
	while ((ent = FindEntityByClassname(ent, "team_control_point")) != -1)
	{
		int iTeam = GetEntProp(ent, Prop_Send, "m_iTeamNum");
		if (!bPointLocked[ent])
		{
			float flPos[3], flDistance, flClosest = 99999.0;
			int fallback;
			GetEntPropVector(ent, Prop_Data, "m_vecOrigin", flPos);
			//LogMessage("ControlPoint %i is unlocked and owned by team %i", GetEntProp(ent, Prop_Data, "m_iPointIndex"), iTeam);
			for (int i = 0; i < FallBackCount; i++)
			{
				if (iTeam != FallBackTeam[i]) continue;

				flDistance = GetVectorDistance(flPos, FallBackPos[i]);
				if (flDistance <= flClosest)
				{
					//LogMessage("Closest fallback: %i for team: %i - %.1fhu from Point: %i", i, FallBackTeam[i], flDistance, GetEntProp(ent, Prop_Data, "m_iPointIndex"));
					flClosest = flDistance;
					fallback = i;
				}
			}
			FallBackIndex[iTeam] = fallback;
			//PrintCenterTextAll("Bot Fallback Point Index: %i", fallback);
		}
	}
}

public bool MoveTowardsNode(int bot, bool fallback)
{
	int iTeam = GetClientTeam(bot);
	float vAngles[3], vMoveAngles[3], flEyePos[3], flMoveVec[3], flMovePos[3];
	GetClientEyeAngles(bot, vAngles);
	GetClientEyePosition(bot, flEyePos);
	flMovePos = FallBackPos[iTeam];

	if (iObstructions[bot] >= 5)
	{
		//Allow bot to move freely when stuck
		flNavDelay[bot] = GetEngineTime() + GetRandomFloat(1.25, 3.0);
		return false;
	}

	//Find fallback node and move towards it
	if (fallback)
	{
		if (FallBackIndex[iTeam] != -1)
		{
			// Don't move towards position if within radius
			if (GetVectorDistance(flMovePos, flEyePos) <= NodeRadius[FallBackIndex[iTeam]])
				return false;


			//Set position at eye level to give a more natural movement look
			flMovePos[2] = flEyePos[2];

			//Get vector from bot pos to node
			MakeVectorFromPoints(flMovePos, flEyePos, flMoveVec);
			GetVectorAngles(flMoveVec, vMoveAngles);
			vMoveAngles[0] *= -1.0;
			vMoveAngles[1] += 180.0;

			ClampAngle(vMoveAngles);
			TeleportEntity(bot, NULL_VECTOR, vMoveAngles, NULL_VECTOR);
			bInCaptureArea[bot] = false;
			return true;
		}
	}
	else // move towards nearest active control point
	{
		FindNearestCapturePoint(bot, iTeam, flMovePos); //Sets flMovePos as the nearest capture point position

		// Don't move towards position if within radius
		if (GetVectorDistance(flMovePos, flEyePos) <= 250.0)
			bInCaptureArea[bot] = true;
		if (GetVectorDistance(flMovePos, flEyePos) <= 150.0)
			return false;


		flMovePos[2] = flEyePos[2];

		//Get Vector from bot pos to node
		MakeVectorFromPoints(flMovePos, flEyePos, flMoveVec);
		GetVectorAngles(flMoveVec, vMoveAngles);
		vMoveAngles[0] *= -1.0;
		vMoveAngles[1] += 180.0;

		ClampAngle(vMoveAngles);
		TeleportEntity(bot, NULL_VECTOR, vMoveAngles, NULL_VECTOR);
		bInCaptureArea[bot] = false;
		return true;
	}
	bInCaptureArea[bot] = false;
	return false;
}

stock float[] FindNearestCapturePoint(int bot, int team, float pos[3])
{
	int ent = MaxClients+1;
	while ((ent = FindEntityByClassname(ent, "team_control_point")) != -1)
	{
		int iTeam = GetEntProp(ent, Prop_Send, "m_iTeamNum");
		if (!bPointLocked[ent])
		{
			if (iTeam != team)
			{
				//Set position as control point's position
				GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos);
				break;
			}
		}
	}
}

stock bool ShouldFallBack(int bot)
{
	int iTeam = GetClientTeam(bot);
	int OtherTeam = GetOpposingTeam(iTeam);
	if (OtherTeam == 0) return false;

	int FriendAlive, EnemyAlive;

	//Get number of alive players per team
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			if (GetClientTeam(i) == iTeam)
				FriendAlive++;
			if (GetClientTeam(i) == OtherTeam)
				EnemyAlive++;
		}
	}
	if (EnemyAlive - FriendAlive >= 4) //Difference in team strength 4 or more
		return true;
	return false;
}

public void DoNoiseMaker(int bot)
{
	if (NoiseMakerDelay[bot] <= GetEngineTime())
	{
		char Noise[256], sParticle[256];
		NoiseMakerDelay[bot] = GetEngineTime() + NoiseMakerDelayAdd[bot];
		switch (NoiseMaker[bot])
		{
			case 284: //banshee
			{
				Format(Noise, sizeof Noise, "items/halloween/banshee0%i.wav", GetRandomInt(1, 3));
				Format(sParticle, sizeof sParticle, "halloween_notes");
				PrecacheSound(Noise);
			}
			case 542: //Vuvuzela
			{
				int num = GetRandomInt(1, 17);
				Format(Noise, sizeof Noise, "items/football_manager/vuvezela_%i%i.wav", num < 10 ? 0 : 1, num < 10 ? num : num - 10);
				PrecacheSound(Noise);
				Format(sParticle, sizeof sParticle, "bday_confetti");
			}
		}
		EmitSoundToAll(Noise, bot, SNDCHAN_AUTO, 100);
		int newParticle = CreateParticle(bot, sParticle, 74.0, true);
		CreateTimer(5.0, RemoveParticle, EntIndexToEntRef(newParticle), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action RemoveParticle(Handle Timer, any ref)
{
	int iPart = EntRefToEntIndex(ref);
	if (IsValidEntity(iPart) && iPart > 0)
	{
		char className[64];
		GetEntityClassname(iPart, className, sizeof className);
		if (StrEqual(className, "info_particle_system"))
		{
			AcceptEntityInput(iPart, "Kill");
		}
	}
	return Plugin_Stop;
}

public Action OnPlayerRunCmd(int bot, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(IsValidClient(bot))
	{
		if (!IsFakeClient(bot) && GetConVarBool(g_playerBot))
		{
			if (buttons & IN_RELOAD)
			{
				SetEntProp(bot, Prop_Data, "m_bLagCompensation", false);
				SetEntProp(bot, Prop_Data, "m_bPredictWeapons", false);
				float vAngle2[3];
				GetClientEyeAngles(bot, vAngle2);
				SetPlayerViewAngles(bot, vAngle2, true);
			}
			else
			{
				SetEntProp(bot, Prop_Data, "m_bLagCompensation", true);
				SetEntProp(bot, Prop_Data, "m_bPredictWeapons", true);
			}
		}
		float oAngle[3];
		oAngle = angles;
		if(IsFakeClient(bot))
		{
			if(IsPlayerAlive(bot) && (BotIndex[bot] > 0 || bIsHookedBot[bot]))
			{
				TFClassType class = TF2_GetPlayerClass(bot);
				float speed = GetVectorLength(vel, false);
				if (NoiseMaker[bot] > 0)
					DoNoiseMaker(bot);

				if (speed <= 60.0)
					DoStutterStep(bot, vel, class);

				if (GetHealth(bot) <= 50 && CallMedicDelay[bot] <= GetEngineTime())
				{
					FakeClientCommand(bot, "voicemenu 0 0");
					CallMedicDelay[bot] = GetEngineTime() + (GetRandomFloat(5.0, 35.0));
				}

				if (!(class == TFClass_Sniper && TF2_IsPlayerInCondition(bot, TFCond_Slowed)))
				{
					SetEntProp(bot, Prop_Send, "m_iFOV", 90);
					SetEntProp(bot, Prop_Send, "m_iDefaultFOV", 90);
				}
				int team = GetClientTeam(bot);

				bIsAttacking[bot] = (buttons & IN_ATTACK) != 0;

				if (flBotAmmoDuration[bot] <= GetEngineTime())
					RefreshAmmo(bot, GetPlayerWeaponSlot(bot, TFWeaponSlot_Primary), GetPlayerWeaponSlot(bot, TFWeaponSlot_Secondary));

				char currentMap[PLATFORM_MAX_PATH];
				GetCurrentMap(currentMap, sizeof(currentMap));

				if (JumpTimer[bot] <= GetEngineTime())
				{
					buttons |= IN_JUMP;
					if (class == TFClass_Scout)
					{
						if (!bScoutSingleJump[bot])
							DoubleJumpTimer[bot] = GetEngineTime() + GetRandomFloat(0.1, 0.25);
					}

					Call_StartForward(g_BotJump);

					Call_PushCell(bot);
					Call_PushCell(BotIndex[bot]);
					Call_PushCell(bIsHookedBot[bot]);

					Call_Finish();

					JumpTimer[bot] = FAR_FUTURE;
				}
				if (DoubleJumpTimer[bot] <= GetEngineTime())
				{
					buttons |= IN_JUMP;
					Call_StartForward(g_BotJump);

					Call_PushCell(bot);
					Call_PushCell(BotIndex[bot]);
					Call_PushCell(bIsHookedBot[bot]);

					Call_Finish();

					JumpTimer[bot] = FAR_FUTURE;
					DoubleJumpTimer[bot] = FAR_FUTURE;
				}

				//Find target
				if (AggroTime[bot] <= GetEngineTime())
				{
					float vAngle2[3];
					GetClientEyeAngles(bot, vAngle2);
					BotAggroTarget[bot] = SelectBestTarget(bot, vAngle2, AimFOV[bot]);
					//PrintToChatAll("Aggro Target: %i", BotAggroTarget[bot]);
					if (IsValidClient(BotAggroTarget[bot]) && BotAggroTarget[bot] != bot)
						AggroTime[bot] = GetEngineTime() + AggroDelay[bot];
				}

				if (IsValidClient(BotAggroTarget[bot]) && TargetIsValid(bot, BotAggroTarget[bot]))
				{
					float targetPos[3], botPos[3];
					GetClientAbsOrigin(BotAggroTarget[bot], targetPos);
					GetClientAbsOrigin(bot, botPos);

					bFleeing[bot] = ShouldBotFlee(bot);

					flNavDelay[bot] = GetEngineTime() + 3.0;

					float flDistance = GetVectorDistance(botPos, targetPos);

					int pWeapon = GetEntPropEnt(bot, Prop_Send, "m_hActiveWeapon");
					int pIndex;
					if (IsValidEntity(pWeapon) && pWeapon > MaxClients)
						pIndex = GetEntProp(pWeapon, Prop_Send, "m_iItemDefinitionIndex");

					int sWeapon = GetPlayerWeaponSlot(bot, TFWeaponSlot_Secondary);
					int sIndex;
					if (IsValidEntity(sWeapon) && sWeapon > MaxClients)
						sIndex = GetEntProp(sWeapon, Prop_Send, "m_iItemDefinitionIndex");

					int mWeapon = GetPlayerWeaponSlot(bot, TFWeaponSlot_Melee);
					int mIndex;
					if (IsValidEntity(mWeapon) && mWeapon > MaxClients)
						mIndex = GetEntProp(mWeapon, Prop_Send, "m_iItemDefinitionIndex");

					if (!bFleeing[bot] && class != TFClass_Sniper && class != TFClass_Medic && SpyIsAttacking(bot, class))
					{
						if (flDistance > AttackRange[bot] && AcceptableAngle(bot, BotAggroTarget[bot]) && !bInCaptureArea[bot])
						{
							//PrintCenterTextAll("Bot Distance: %.1f\nAttack Range: %.1f", flDistance, AttackRange[bot]);
							moveForward(vel, GetPlayerMaxSpeed(bot, false));
						}

						switch (class)
						{
							case TFClass_DemoMan:
							{
								if (IsWeaponSlotActive(bot, TFWeaponSlot_Melee)) // demo with melee
								{
									float flCharge;
									if (shield[bot] > MaxClients)
										flCharge = GetEntPropFloat(bot, Prop_Send, "m_flChargeMeter");
									if (flDistance <= 50.0)
										buttons |= IN_ATTACK;
									else if (TF2_IsPlayerInCondition(bot, TFCond_Charging))
										buttons &= ~IN_ATTACK;

									if (650.0 > flDistance >= AttackRange[bot] && CheckTrace(bot, BotAggroTarget[bot]))
									{
										if (flCharge >= 100.0)
											buttons |= IN_ATTACK2;
									}
									else
										buttons &= ~IN_ATTACK2;
								}
							}
							case TFClass_Scout:
							{
								if (flDistance <= AttackRange[bot] + 200.0)
									DoStutterStep(bot, vel, class, GetRandomFloat(0.4, 0.9));

								if (GetEntProp(GetPlayerWeaponSlot(bot, TFWeaponSlot_Primary), Prop_Send, "m_iClip1") == 0 && flBotKeepPrimaryDelay[bot] <= GetEngineTime())
								{
									TryKeepSlot(bot, GetPlayerWeaponSlot(bot, TFWeaponSlot_Primary), GetPlayerWeaponSlot(bot, TFWeaponSlot_Secondary), TFWeaponSlot_Primary, 10.0, buttons);
									flBotKeepPrimaryDelay[bot] = GetEngineTime() + 25.0;
								}
							}
							case TFClass_Pyro:
							{
								switch (pIndex)
								{
									case 594:
									{
										if (GetRageMeter(bot) >= 100.0)
											buttons |= IN_ATTACK2;
									}
								}
								if (flDistance <= 450.0)
									buttons |= IN_ATTACK;

								if (flDistance >= 125.0)
									buttons &= ~IN_ATTACK2;

								switch (sIndex)
								{
									case 39, 351, 740, 1081: //flareguns
									{
										if (TF2_IsPlayerInCondition(BotAggroTarget[bot], TFCond_OnFire) && IsWeaponSlotActive(bot, TFWeaponSlot_Primary))
										{
											//if (TargetIsValid(bot, BotAggroTarget[bot]) && TargetInRange(bot, BotAggroTarget[bot], true, 125.0))
												//TryKeepSlot(bot, GetPlayerWeaponSlot(bot, TFWeaponSlot_Primary), GetPlayerWeaponSlot(bot, TFWeaponSlot_Secondary), TFWeaponSlot_Secondary, 2.0, buttons);
										}
									}
								}
							}
							case TFClass_Soldier:
							{
								switch (mIndex)
								{
									case 416: //market gardener
									{
										if (TF2_IsPlayerInCondition(bot, TFCond_BlastJumping))
										{
											if (TargetIsValid(bot, BotAggroTarget[bot]) && TargetInRange(bot, BotAggroTarget[bot], false, 600.0))
												TryKeepSlot(bot, GetPlayerWeaponSlot(bot, TFWeaponSlot_Primary), GetPlayerWeaponSlot(bot, TFWeaponSlot_Secondary), TFWeaponSlot_Melee, 0.5, buttons);
										}
									}
								}
							}
						}
					}
					else if (bFleeing[bot] && !DemoIsDemoknight(bot))
					{
						switch (class)
						{
							case TFClass_Soldier:
							{
								switch (mIndex)
								{
									case 775: //escape plan
									{
										if (!TargetIsValid(bot, BotAggroTarget[bot]) || !TargetInRange(bot, BotAggroTarget[bot]))
										{
											if (GetHealth(bot) <= GetBotHealthThreshold(bot))
											{
												if (IsWeaponSlotActive(bot, TFWeaponSlot_Primary))
													TF2_SwitchToSlot(bot, TFWeaponSlot_Melee);
											}
										}
									}
								}
							}
						}
					}
				}
				else if (IsControlPoints() && Captures >= 1)		//Movement for CP maps ONLY WHEN NO VALID TARGET EXISTS AND THE FIRST POINT IS CAPTURED
				{
					if (flNavDelay[bot] <= GetEngineTime() && IsPushClass(class) && !bFleeing[bot])
					{
						if (MoveTowardsNode(bot, ShouldFallBack(bot)))
							moveForward(vel, GetPlayerMaxSpeed(bot, false));
					}
					if (class == TFClass_DemoMan && HasShield(bot))
						DemoknightPreventCharge(bot, buttons);
				}
				else
				{
					if (class == TFClass_DemoMan && HasShield(bot))
						DemoknightPreventCharge(bot, buttons);
				}

				switch (class)
				{
					case TFClass_Medic:
					{
						if (MedicShouldUber(bot, MedicGetPatient(bot)))
						{
							buttons |= IN_ATTACK2;
						}
					}
					case TFClass_Pyro:
					{
						int melee = GetPlayerWeaponSlot(bot, TFWeaponSlot_Melee);
						int mIndex = GetEntProp(melee, Prop_Send, "m_iItemDefinitionIndex");
						switch (mIndex)
						{
							case 214: //powerjack
							{
								if (!TargetIsValid(bot, BotAggroTarget[bot]) || !TargetInRange(bot, BotAggroTarget[bot]))
								{
									if (IsWeaponSlotActive(bot, TFWeaponSlot_Primary))
										TF2_SwitchToSlot(bot, TFWeaponSlot_Melee);
								}
							}
						}
					}
					case TFClass_Sniper:
					{
						if (iAntiAim[bot] > 0)
							DoAntiAim(bot, iAntiAim[bot], true);

						int iTarget = GetTargetAim(bot);
						if (CheckTrace(bot, iTarget))
						{
							if (CheckSniperShouldAim(bot))
								buttons |= IN_ATTACK2;
							else if (HeadShotDelay[bot] <= GetEngineTime() && TF2_IsPlayerInCondition(bot, TFCond_Slowed))
								buttons |= IN_ATTACK;

							if ((buttons & IN_ATTACK) && AimDelay[bot] <= GetEngineTime())
							{
								SetTargetViewAngles(bot, true);
							}
						}
					}
					case TFClass_Scout:
					{
						if (bPreferMelee[bot] && !bFleeing[bot])
						{
							if (!IsWeaponSlotActive(bot, TFWeaponSlot_Melee))
								TF2_SwitchToSlot(bot, TFWeaponSlot_Melee);

						}
					}
					case TFClass_Soldier:
					{
						int pWeapon = GetEntPropEnt(bot, Prop_Send, "m_hActiveWeapon");
						int SoldierPrimary = GetEntProp(pWeapon, Prop_Send, "m_iItemDefinitionIndex");
						if (TF2_IsPlayerInCondition(bot, TFCond_BlastJumping) && RJForwardDelay[bot] <= GetEngineTime())
						{
							if (NavJump[bot] && !ZeroVector(RJPreservedAngles[bot]))
							{
								TeleportEntity(bot, NULL_VECTOR, RJPreservedAngles[bot], NULL_VECTOR);
								moveLeft(vel, GetPlayerMaxSpeed(bot));
							}
							else
								moveForward(vel, 500.0);

							if (RJForwardTime[bot] <= GetEngineTime())
							{
								RJForwardDelay[bot] = FAR_FUTURE;
								RJForwardTime[bot] = FAR_FUTURE;
								NavJump[bot] = false;
							}
						}

						if (ShouldRocketJump(bot))
						{
							float newAim[3];
							if (RJDelay[bot] <= GetEngineTime() && IsWeaponSlotActive(bot, TFWeaponSlot_Primary))
							{
								if (!NavJump[bot])
								{
									vel = moveForward(vel, 500.0);
									GetClientEyeAngles(bot, newAim);
									newAim[0] = 60.0;
									newAim[1] = 160.0;
									newAim[2] = 0.0;
									TeleportEntity(bot, NULL_VECTOR, newAim, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel, 500.0);
									RJDelay[bot] = FAR_FUTURE;
									RJForwardDelay[bot] = GetEngineTime() + 0.2;
									RJForwardTime[bot] = GetEngineTime() + 1.2;

									CallRocketJump(bot, SoldierPrimary);
								}
							}
							if (Jump[bot])
							{
								buttons |= IN_JUMP;
								Jump[bot] = false;
							}
							float BotPos[3];
							GetClientAbsOrigin(bot, BotPos);
							float JumpDistance[MAXRJPOS], JumpAim[3];
							switch (team)
							{
								case 2:
								{
									for (int i = 0; i < RJPosCount; i++)
									{
										JumpDistance[i] = GetVectorDistance(BotPos, RJPos[i]);
										if (IsWeaponSlotActive(bot, TFWeaponSlot_Primary) && GetHealth(bot) > 75.0 )
										{
											if (JumpDistance[i] < RJDistance[i] && Soldier_ValidRJPos(bot, i, team))
											{
												GetClientEyeAngles(bot, JumpAim);
												JumpAim[0] = RJAngles[i][0];
												JumpAim[1] = RJAngles[i][1];
												JumpAim[2] = 0.0;
												RJPreservedAngles[bot] = RJNewAngles[i];
												TeleportEntity(bot, NULL_VECTOR, JumpAim, NULL_VECTOR);
												buttons |= IN_JUMP;
												buttons |= IN_DUCK;
												buttons |= IN_ATTACK;
												vel = moveForward(vel, 500.0);
												RJForwardDelay[bot] = GetEngineTime() + 0.08;
												RJForwardTime[bot] = GetEngineTime() + 1.2;
												RJCooldown[bot] = GetEngineTime() + 5.0;

												CallRocketJump(bot, SoldierPrimary);
											}
										}
									}
								}
								case 3:
								{
									for (int i = 4; i < RJPosCount; i++)
									{
										JumpDistance[i] = GetVectorDistance(BotPos, RJPos[i]);
										if (IsWeaponSlotActive(bot, TFWeaponSlot_Primary) && GetHealth(bot) > 75.0)
										{
											if (JumpDistance[i] < RJDistance[i] && Soldier_ValidRJPos(bot, i, team))
											{
												GetClientEyeAngles(bot, JumpAim);
												JumpAim[0] = RJAngles[i][0];
												JumpAim[1] = RJAngles[i][1];
												JumpAim[2] = 0.0;
												RJPreservedAngles[bot] = RJNewAngles[i];
												TeleportEntity(bot, NULL_VECTOR, JumpAim, NULL_VECTOR);
												buttons |= IN_JUMP;
												buttons |= IN_DUCK;
												buttons |= IN_ATTACK;
												vel = moveForward(vel, 500.0);
												RJForwardDelay[bot] = GetEngineTime() + 0.08;
												RJForwardTime[bot] = GetEngineTime() + 1.2;
												RJCooldown[bot] = GetEngineTime() + 5.0;

												CallRocketJump(bot, SoldierPrimary);
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

stock void DemoknightPreventCharge(int bot, int &buttons)
{
	buttons &= ~IN_ATTACK2
}

stock void TryKeepSlot(int bot, int primary, int secondary, int slot, float duration, int &buttons)
{
	if (flAmmoPreserveDelay[bot] <= GetEngineTime())
	{
		int iAmmoType;
		//Make sure weapon exists and has a clip
		if (slot == 2 || slot == 1)
		{
			if (IsValidEntity(primary) && primary > MaxClients)
			{
				//Primary Ammo Type
				iAmmoType = 1;
				if (iAmmoType != -1)
				{
					//Preserve clip and ammo so we can restore it later
					if (HasEntProp(primary, Prop_Send, "m_iClip1"))
					{
						if (GetEntProp(primary, Prop_Send, "m_iClip1") > 0)
						{
							iPreservedClipP[bot] = GetEntProp(primary, Prop_Send, "m_iClip1");
							SetEntProp(primary, Prop_Send, "m_iClip1", 0);
							//PrintToChatAll("Preserved Primary Clip at: %i", iPreservedClipP[bot]);
						}
					}

					if (GetEntProp(bot, Prop_Send, "m_iAmmo", _, iAmmoType) > 0)
					{
						iPreservedAmmoP[bot] = GetEntProp(bot, Prop_Send, "m_iAmmo", _, iAmmoType);
						//PrintToChatAll("Preserved Primary Ammo at: %i", iPreservedAmmoP[bot]);
					}

					//Empty clip and ammo to prevent bot from switching back to this weapon
					SetEntProp(bot, Prop_Send, "m_iAmmo", 0, _, iAmmoType);
				}
			}
		}

		if (slot == 2 || slot == 0)
		{
			//Repeat for secondary
			if (IsValidEntity(secondary) && secondary > MaxClients)
			{
				iAmmoType = 2;
				if (iAmmoType != -1)
				{
					if (HasEntProp(secondary, Prop_Send, "m_iClip1"))
					{
						if (GetEntProp(secondary, Prop_Send, "m_iClip1") > 0)
						{
							iPreservedClipS[bot] = GetEntProp(secondary, Prop_Send, "m_iClip1");
							SetEntProp(secondary, Prop_Data, "m_iClip1", 0);
						}
					}

					if (GetEntProp(bot, Prop_Send, "m_iAmmo", _, iAmmoType) > 0)
						iPreservedAmmoS[bot] = GetEntProp(bot, Prop_Send, "m_iAmmo", _, iAmmoType);

					SetEntProp(bot, Prop_Send, "m_iAmmo", 0, _, iAmmoType);
				}
			}
		}

		if (slot == 2)
		{
			if (!IsWeaponSlotActive(bot, TFWeaponSlot_Melee)) //If we do not already have melee out, switch to it
				TF2_SwitchToSlot(bot, TFWeaponSlot_Melee);
		}
	}

	if (slot == 2)
	{
		if (GetDistance(bot, BotAggroTarget[bot]) < 255.0)
			buttons |= IN_ATTACK;
		else
			buttons &= ~IN_ATTACK;
	}
	//Set duration to hold melee weapon for
	flBotAmmoDuration[bot] = GetEngineTime() + duration;
	flAmmoPreserveDelay[bot] = GetEngineTime() + 1.0;
}

stock void RefreshAmmo(int bot, int primary, int secondary)
{
	int iAmmoType;
	//Make sure weapon exists and has a clip
	if (IsValidEntity(primary) && primary > MaxClients && HasEntProp(primary, Prop_Send, "m_iClip1"))
	{
		//Get ammo type
		iAmmoType = 1;
		if (iAmmoType != -1)
		{
			//Refresh clip and ammo with previously stored values
			//Make sure we have a clip amount stored
			if (iPreservedClipP[bot] > 0)
			{
				SetEntProp(primary, Prop_Send, "m_iClip1", iPreservedClipP[bot]); //set clip
				//PrintToChatAll("Set Primary Clip: %i", iPreservedClipP[bot]);
			}

			//Make sure we have ammo stored
			if (iPreservedAmmoP[bot] > 0)
			{
				SetEntProp(bot, Prop_Send, "m_iAmmo", iPreservedAmmoP[bot], _, iAmmoType); //set primary ammo
				//PrintToChatAll("Set Primary Ammo: %i", iPreservedAmmoP[bot]);
			}

			//Reset stored ammo and clip
			iPreservedClipP[bot] = 0;
			iPreservedAmmoP[bot] = 0;
		}
	}

	//Repeat for secondary
	if (IsValidEntity(secondary) && secondary > MaxClients && HasEntProp(secondary, Prop_Send, "m_iClip1"))
	{
		iAmmoType = 2;
		if (iAmmoType != -1)
		{
			if (iPreservedClipS[bot] > 0)
			{
				SetEntProp(secondary, Prop_Send, "m_iClip1", iPreservedClipS[bot]);
				//PrintToChatAll("Set Secondary Clip: %i", iPreservedClipS[bot]);
			}

			if (iPreservedAmmoS[bot] > 0)
			{
				SetEntProp(bot, Prop_Send, "m_iAmmo", iPreservedAmmoS[bot], _, iAmmoType); //set secondary ammo
				//PrintToChatAll("Set Secondary Ammo: %i", iPreservedAmmoS[bot]);
			}

			iPreservedClipS[bot] = 0;
			iPreservedAmmoS[bot] = 0;
		}
	}
	flBotAmmoDuration[bot] = FAR_FUTURE;
}

stock float GetDistance(int client, int target)
{
	if (!IsValidTarget(client, target)) return 9999.0;

	float clPos[3], tgPos[3];
	GetClientEyePosition(client, clPos);
	GetClientAbsOrigin(target, tgPos);

	return (GetVectorDistance(clPos, tgPos));
}

stock void CallRocketJump(int bot, int weapon)
{
	Call_StartForward(g_BotRocketJump);

	Call_PushCell(bot);
	Call_PushCell(BotIndex[bot]);
	Call_PushCell(bIsHookedBot[bot]);
	Call_PushCell(weapon);

	Call_Finish();
}

stock bool IsPushClass(TFClassType class)
{
	switch(class)
	{
		case TFClass_Sniper, TFClass_Medic, TFClass_Spy, TFClass_Engineer: return false;
		default: return true;
	}
}

stock bool Soldier_ValidRJPos(int bot, int nav, int team)
{
	if (RJTeam[nav] == team || RJTeam[nav] == 0) //correct team
	{
		if (RJAir[nav] == 1) //Nav point requires bot to be in the air
		{
			if (!(GetEntityFlags(bot) & FL_ONGROUND)) //Not on ground
				return true;
			else
				return false;
		}
		else if (RJCooldown[bot] <= GetEngineTime()) //Nav point does not require bot to be in the air
			return true;
	}
	return false;
}

stock bool ZeroVector(float m_vector[3])
{
	for (int axis = 0; axis < 4; axis++)
	{
		if (m_vector[axis] != ZeroVec[axis])
			return false;
	}
	return true;
}

stock void FixAAMovement(int client, const float vOldAngles[3], float vViewAngles[3], float &flForwardMove, float &flSideMove, float fOldForward, float fOldSidemove)
{
	float f1 = (vOldAngles[1] < 0.0) ? (360.0 + vOldAngles[1]) : (vOldAngles[1]);
	float f2 = (vViewAngles[1] < 0.0) ? (360.0 + vViewAngles[1]) : (vViewAngles[1]);

	float deltaView = (f2 < f1) ? (FloatAbs(f2 - f1)) : (360.0 - FloatAbs(f1 - f2));
	deltaView = 360.0 - deltaView;

	flForwardMove = Cosine(DegToRad(deltaView)) * fOldForward + Cosine(DegToRad(deltaView + 90.0)) * fOldSidemove;
	flSideMove = Sine(DegToRad(deltaView)) * fOldForward + Sine(DegToRad(deltaView + 90.0)) * fOldSidemove;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (IsCustomBot(client))
	{
		if (condition == TFCond_Slowed)
		{
			float delay = flSniperAimTime[client];
			delay += (GetRandomFloat(-0.25, 0.85)); //add some variance for more natural aim
			ClampFloat(delay, 0.15); //Clamp delay
			if (iAntiAim[client] > 0)
				delay = 0.20;
			HeadShotDelay[client] = GetEngineTime() + delay;
		}
	}
}

stock float ClampFloat(float val, float min, float max = 999.0)
{
	if (val < min)
		val = min;
	if (val > max)
		val = max;
}

stock float GetRageMeter(int client)
{
	return GetEntPropFloat(client, Prop_Send, "m_flRageMeter");
}

stock bool SpyIsAttacking(int bot, TFClassType class)
{
	if (class == TFClass_Spy)
	{
		if (TF2_IsPlayerInCondition(bot, TFCond_Cloaked) || TF2_IsPlayerInCondition(bot, TFCond_Disguised))
			return false;
	}
	return true;
}

stock bool ShouldRocketJump(int bot)
{
	if (IsValidClient(bot) && IsCustomBot(bot))
	{
		int secondary = GetPlayerWeaponSlot(bot, TFWeaponSlot_Secondary);
		if (!IsValidEntity(secondary)) //No secondary, likely has gunboats
		{
			if (GetHealth(bot) > 30)
				return true;
		}
		else if (GetHealth(bot) > 55)
			return true;
	}
	return false;
}

stock bool DemoIsDemoknight(int bot)
{
	if (IsValidClient(bot) && IsCustomBot(bot))
	{
		TFClassType class = TF2_GetPlayerClass(bot);
		if (class == TFClass_DemoMan)
		{
			if (HasShield(bot) && GetPlayerWeaponSlot(bot, TFWeaponSlot_Primary) <= 0)
				return true;
		}
	}
	return false;
}

stock int MedicGetPatient(int bot)
{
    if (IsValidClient(bot) && IsCustomBot(bot))
	{
		int weapon = GetEntPropEnt(bot, Prop_Send, "m_hActiveWeapon");
		if (IsValidEntity(weapon) && weapon > MaxClients)
		{
			char wepName[128];
			GetEntityClassname(weapon, wepName, sizeof wepName);
			if (StrContains(wepName, "tf_weapon_medigun") != -1)
			{
				if(GetEntProp(weapon, Prop_Send, "m_bHealing") == 1)
				{
					return GetEntPropEnt(weapon, Prop_Send, "m_hHealingTarget");
				}
			}
		}
	}
    return -1;
}

stock bool MedicShouldUber(int bot, int patient = 0)
{
	if (IsValidClient(bot) && IsCustomBot(bot))
	{
		float flChargeMed;
		int medIndex;
		int medigun = GetPlayerWeaponSlot(bot, TFWeaponSlot_Secondary);
		if (IsValidEntity(medigun) && medigun > MaxClients)
		{
			flChargeMed = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
			medIndex = GetEntProp(medigun, Prop_Send, "m_iItemDefinitionIndex");

			if (flChargeMed >= 100.0)
			{
				if (medIndex == 35) // Kritzkrieg
				{
					if (IsValidClient(patient))
					{
						if(bIsAttacking[patient])
							return true;
					}
				}
				else
				{
					if (DamageTaken[bot] >= 50)
						return true;
					if (IsValidClient(patient))
					{
						if (DamageTaken[patient] >= 50)
							return true;
					}
				}
			}
		}
	}
	return false;
}

stock bool ShouldBotFlee(int bot)
{
	if (IsValidClient(bot) && IsCustomBot(bot))
	{
		//Get bot's health variables
		float maxhp = float(GetEntProp(bot, Prop_Data, "m_iMaxHealth"));
		float curhp = float(GetHealth(bot));

		//Setup values to check against
		float hpratio = curhp / maxhp;
		float threshold = flHealthThreshold[bot];

		//PrintCenterTextAll("BotHP: %.1f BotMaxHP: %.1f HPRatio: %.1f Threshold: %.1f Fleeing: %s", curhp, maxhp, hpratio, threshold, bFleeing[bot] ? "True" : "False");
		if (hpratio <= threshold)
			return true;
	}
	return false;
}

stock int GetBotHealthThreshold(int bot)
{
	float maxhp = float(GetEntProp(bot, Prop_Data, "m_iMaxHealth"));
	return (RoundToFloor(flHealthThreshold[bot] * maxhp))
}

stock void SetTargetViewAngles(int bot, bool head = false, bool proj = false, ground = true, bool player = false)
{
	//TFClassType class = TF2_GetPlayerClass(bot);
	float aimpos[3], aimangle[3], botpos[3], aimvec[3], angle[3];

	int target = BotAggroTarget[bot];
	//PrintToChatAll("SetViewAngle | Bot = %i | Target = %i", bot, target);
	if (!IsValidClient(target)) return;

	//Make sure target is visible and within bot's aim FOV
	if (!CheckTrace(bot, target)) return;
	if (!TargetInFOV(bot, target, AimFOV[bot])) return;

	//Does the bot prioritize aiming for the head
	if (head)
	{
		//GetClientEyePosition(target, aimpos);
		GetBestHitBox(bot, target, aimpos);
	}
	else
		GetClientAbsOrigin(target, aimpos);

	GetClientEyePosition(bot, botpos);
	GetClientEyeAngles(bot, angle);

	//Is the bot using a projectile weapon, adjust position and lead target
	if (proj)
	{
		if (!ground)
			aimpos[2] += 35.0;
		else
			aimpos[2] += 3.5;
		TryPredictPosition(bot, target, aimpos, botpos, GetProjSpeed(bot))
	}
	else if (!head) //otherwise add a bit of variance to cover most of the player's hitbox area
	{
		aimpos[2] += GetRandomFloat(10.0, 60.0);
		aimpos[1] += GetRandomFloat(-20.0, 20.0);
	}

	//Get vector between target and bot then get the angle
	MakeVectorFromPoints(aimpos, botpos, aimvec);
	GetVectorAngles(aimvec, aimangle);
	aimangle[0] *= -1.0;
	aimangle[1] += 180.0;

	//Add inaccuracy based on bot's settings
	aimangle[0] += GetRandomFloat((Inaccuracy[bot] * -1), Inaccuracy[bot]);
	aimangle[1] += GetRandomFloat((Inaccuracy[bot] * -1), Inaccuracy[bot]);

	//clamp angles to prevent janking
	ClampAngle(aimangle);
	//SnapEyeAngles(bot, aimpos);
	TeleportEntity(bot, NULL_VECTOR, aimangle, NULL_VECTOR);
}

stock void SetPlayerViewAngles(int client, float angle[3], bool head = false, bool proj = false, ground = true)
{
	//TFClassType class = TF2_GetPlayerClass(bot);
	float aimpos[3], aimangle[3], botpos[3], aimvec[3];

	int target = SelectBestTarget(client, angle, 180.0);

	//Make sure target is visible and within bot's aim FOV
	if (!CheckTrace(client, target)) return;

	//PrintToChatAll("SetViewAngle: Target = %i", target);
	if (!IsValidClient(target)) return;

	//Does the bot prioritize aiming for the head
	if (head)
	{
		//GetClientEyePosition(target, aimpos);
		GetBestHitBox(client, target, aimpos);
	}
	else
		GetClientAbsOrigin(target, aimpos);

	GetClientEyePosition(client, botpos);

	//Is the bot using a projectile weapon, adjust position and lead target
	if (proj)
	{
		if (!ground)
			aimpos[2] += 35.0;
		else
			aimpos[2] += 3.5;
		TryPredictPosition(client, target, aimpos, botpos, GetProjSpeed(client))
	}
	else if (!head) //otherwise add a bit of variance to cover most of the player's hitbox area
	{
		aimpos[2] += GetRandomFloat(10.0, 60.0);
		aimpos[1] += GetRandomFloat(-20.0, 20.0);
	}

	//Get vector between target and bot then get the angle
	MakeVectorFromPoints(aimpos, botpos, aimvec);
	GetVectorAngles(aimvec, aimangle);
	aimangle[0] *= -1.0;
	aimangle[1] += 180.0;

	//clamp angles to prevent janking
	ClampAngle(aimangle);
	//SnapEyeAngles(bot, aimpos);
	TeleportEntity(client, NULL_VECTOR, aimangle, NULL_VECTOR);
}


stock bool TargetInFOV(int bot, int target, float fov)
{
	float vecBotPos[3], vecTargPosition[3], angBotViewAngles[3], fovcheck;

	GetClientEyeAngles(bot, angBotViewAngles);
	GetClientAbsOrigin(bot, vecBotPos);
	GetClientEyePosition(target, vecTargPosition);
	vecTargPosition[2] -= 37.0;

	fovcheck = GetFov(angBotViewAngles, CalcAngle(vecBotPos, vecTargPosition));

	if (fovcheck <= fov)
		return true;

	return false;
}

stock void ClampAngle(float fAngles[3])
{
	while(fAngles[0] > 89.0)  fAngles[0]-=360.0;
	while(fAngles[0] < -89.0) fAngles[0]+=360.0;
	while(fAngles[1] > 180.0) fAngles[1]-=360.0;
	while(fAngles[1] <-180.0) fAngles[1]+=360.0;
}

stock void SetHP(int client, int amount = 10000)
{
	SetEntityHealth(client, amount);
}

stock void AimUp(int bot)
{
	float aimangle[3];
	GetClientEyeAngles(bot, aimangle);
	aimangle[0] = -89.0;
	SetEyeAngles(bot, aimangle);
}

stock int GetTargetAim(int bot)
{
	//SetTargetViewAngles(bot, true);
	int target = BotAggroTarget[bot];
	if (target != bot) return target;
	return bot;
}

stock float[] TryPredictPosition(int bot, int target, float TargetLocation[3], float BotPos[3], float ProjSpeed) //Try and aim where a target will be in the future
{
	if(!target || !IsValidClient(target)) return;
	if(target != bot)
	{
		float flDistance, flTravelTime, TargetVelocity[3];
		GetEntPropVector(target, Prop_Data, "m_vecVelocity", TargetVelocity);
		flDistance = GetVectorDistance(BotPos, TargetLocation);
		flTravelTime = flDistance / ProjSpeed;
		float gravity = GetConVarFloat(gravscale) / 100.0;
		gravity = TargetVelocity[2] > 0.0 ? -gravity : gravity;

		//Try and predict where the target will be when the projectile hits
		TargetLocation[0] += TargetVelocity[0] * flTravelTime;
		TargetLocation[1] += TargetVelocity[1] * flTravelTime;
		if (GetEntityFlags(target) & FL_ONGROUND)
			TargetLocation[2] += TargetVelocity[2] * flTravelTime;
		else
		{
			//PrintToChatAll("Target in air");
			if (bAimGround[bot])
			{
				//PrintToChatAll("Shooting ground");
				TargetLocation[2] = TryGetGroundPosition(target, TargetLocation, flHeightThreshold[bot], flTravelTime, TargetVelocity[2], gravity);
			}
			else
			{
				//PrintToChatAll("Air shot");
				TargetLocation[2] += TargetVelocity[2] * flTravelTime + (gravity + Pow(flTravelTime, 2.0)) - 10.0;

				//Check if target will hit a surface
				float target_curpos[3];
				GetClientAbsOrigin(target, target_curpos);
				Handle position_trace = TR_TraceRayFilterEx(target_curpos, TargetLocation, MASK_PLAYERSOLID, RayType_EndPoint, FilterSelf, target);
				if (TR_DidHit(position_trace))
				{
					TR_GetEndPosition(TargetLocation, position_trace); // If target will hit a surface, fire at that position
				}
				CloseHandle(position_trace);
			}
		}
	}
}

stock float TryGetGroundPosition(int target, float pos[3], float height, float time, float vertvel, float grav)
{
	float DownAngle[3] = {89.0, 0.0, 0.0};
	float endpos[3];

	Handle position_trace = TR_TraceRayFilterEx(pos, DownAngle, MASK_PLAYERSOLID, RayType_Infinite, FilterSelf, target);
	if (TR_DidHit(position_trace))
	{
		TR_GetEndPosition(endpos, position_trace);
		if (GetVectorDistance(endpos, pos) > height) // above height threshold
		{
			endpos[2] = ((pos[2] + vertvel) * time) + (grav + Pow(time, 2.0)) - 10.0;
		}
		CloseHandle(position_trace);
		return endpos[2];
	}
	return pos[2];
}

stock float GetProjSpeed(int bot)
{
	float speed;
	if (IsValidClient(bot))
	{
		speed = 1100.0;
		int weapon = GetEntPropEnt(bot, Prop_Send, "m_hActiveWeapon");
		if (weapon > MaxClients)
		{
			int hIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			switch (hIndex)
			{
				case 127: //Direct Hit
				{
					speed = 1980.0;
				}
				case 414: //Liberty Launcher
				{
					speed = 1540.0;
				}
				case 39, 351, 740, 1081: //flareguns
				{
					speed = 2000.0;
				}
				case 595: //mannmelter
				{
					speed = 3000.0;
				}
				case 305, 1079: //crossbow
				{
					speed = 2000.0;
				}
				case 17, 204, 36, 412: //syringes
				{
					speed = 1000.0;
				}
				case 19, 206, 1007, 1151, 15079, 15077, 15091, 15092, 15116, 15117, 15142, 15158: //Grenade Launchers
				{
					speed = 1216.6;
				}
				case 308: //loch
				{
					speed = 1513.3;
				}
				case 996: //Loose cannon
				{
					speed = 1453.9;
				}
				case 56, 1005, 1092: //huntsman
				{
					speed = 2100.0;
				}
			}
		}
	}
	return speed;
}

stock bool HasEnoughCharge(int bot, int target)
{
	int health = GetClientHealth(target);
	if (health <= 150) return true;
	if (IsWeaponSlotActive(bot, 0))
	{
		int weapon = GetEntPropEnt(bot, Prop_Send, "m_hActiveWeapon");
		float powercharge = (GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage")*3.0);
		if (powercharge >= health)
		{
			return true;
		}
	}
	return false;
}

stock bool IsWeaponSlotActive(int iClient, iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

stock int GetHealth(bot)
{
	return GetEntProp(bot, Prop_Send, "m_iHealth");
}

stock bool IsValidClient(int bot)
{
    if ( !( 1 <= bot <= MaxClients ) || !IsClientInGame(bot) )
        return false;

    return true;
}

stock int SelectBestTarget(int bot, float oAngles[3], float fov) //Gets the closest visible target to the bot
{
	float vecBotPos[3];
	GetClientEyePosition(bot, vecBotPos);
	int target = INVALID_ENT_REFERENCE;

	BotAggroTarget[bot] = INVALID_ENT_REFERENCE;
	//PrintToChatAll("fov: %.1f", fov);

	float vecTargetPos[3], nearest;
	float flClosestDistance = 8192.0;
	float vecVisiblePos[3];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == bot)
			continue;

		if (!IsClientInGame(i))
			continue;

		if (!IsValidTarget(bot, i))
			continue;

		//if (IgnoreClient[i])
			//continue;

		GetClientEyePosition(i, vecVisiblePos);
		vecVisiblePos[2] -= 40.0;

		nearest = GetFov(oAngles, CalcAngle(vecBotPos, vecVisiblePos));
		if (nearest > fov)
			continue;

		float flDistance = GetVectorDistance(vecBotPos, vecVisiblePos);
		//PrintToChatAll("fov difference: %.1f", FloatAbs(fov - nearest));
		if (FloatAbs(fov - nearest) < 5.0)
		{
			//PrintToChatAll("Checking Distance");
			if (flDistance < flClosestDistance)
			{
				//PrintToChatAll("Closest Target");
				if (CheckTrace(bot, i))
				{
					//PrintToChatAll("Found Target is not closest target");
					fov = nearest;
					flClosestDistance = flDistance;
					vecTargetPos = vecVisiblePos;
					target = i;
				}
			}
		}
		else if (nearest < fov)
		{
			//PrintToChatAll("fov difference greater than 5.0");
			if (CheckTrace(bot, i))
			{
				//PrintToChatAll("Found Target is closest target");
				fov = nearest;
				flClosestDistance = flDistance;
				vecTargetPos = vecVisiblePos;
				target = i;
			}
		}
	}
	//PrintToChatAll("Nearest fov: %.1f", nearest);
	if (IsValidClient(target))
		return target;
	else
	{
		//PrintToChatAll("returned bot");
		return bot;
	}
}

stock float CalcAngle(float src[3], float dst[3])
{
	float angles[3];
	float delta[3];
	SubtractVectors(dst, src, delta);

	GetVectorAngles(delta, angles);

	return angles;
}

stock float CalcAngleBuffer(float src[3], float dst[3], float result[3])
{
	float angles[3];
	float delta[3];
	SubtractVectors(dst, src, delta);

	GetVectorAngles(delta, angles);

	result = angles;
}

stock float GetFov(const float viewAngle[3], const float aimAngle[3])
{
	float ang[3], aim[3];

	GetAngleVectors(viewAngle, aim, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(aimAngle, ang, NULL_VECTOR, NULL_VECTOR);

	return RadToDeg(ArcCosine(GetVectorDotProduct(aim, ang) / GetVectorLength(aim, true)));
}

stock bool IsValidTarget(int client, int target)
{
	if (!IsPlayerAlive(target))
		return false;

	if (GetEntProp(target, Prop_Send, "m_lifeState") != 0)
		return false;

	if (GetClientTeam(target) == GetClientTeam(client))
		return false;


	if (TF2_IsPlayerInCondition(target, TFCond_Ubercharged) || TF2_IsPlayerInCondition(target, TFCond_UberchargedHidden)
		 || TF2_IsPlayerInCondition(target, TFCond_UberchargedCanteen) || TF2_IsPlayerInCondition(target, TFCond_Bonked)) {
		return false;
	}
	if (iAntiAim[client] == 0)
	{
		if (TF2_IsPlayerInCondition(target, TFCond_Cloaked) || TF2_IsPlayerInCondition(target, TFCond_Disguised))
			return false;
	}

	if (GetEntProp(target, Prop_Data, "m_takedamage") != 2)
		return false;

	return true;
}

stock bool CheckTrace(int attacker, int victim)
{
	//PrintToChat(attacker, "tracing for target.");
	if (!IsValidClient(victim))
		PrintCenterTextAll("Target not a player - Ent: %i", victim);
	bool result = false;
	float startingpos[3], targetpos[3];
	GetClientEyePosition(attacker, startingpos);

	GetClientEyePosition(victim, targetpos);
	Handle tracecheck = TR_TraceRayFilterEx(startingpos, targetpos, MASK_PLAYERSOLID, RayType_EndPoint, FilterSelf, attacker);
	if (TR_DidHit(tracecheck))
	{
		int ent = TR_GetEntityIndex(tracecheck);
		if(IsValidClient(ent) && ent == victim) //If target is visible and trace result is the target
		{
			//PrintToChatAll("Can see target");
			result = true;
		}
	}
	CloseHandle(tracecheck);
	return result;
}

public bool FilterSelf(int entity, int contentsMask, any iExclude)
{
	char class[64];
	GetEntityClassname(entity, class, sizeof(class));

	if (StrEqual(class, "entity_medigun_shield"))
	{
		if (GetEntProp(entity, Prop_Send, "m_iTeamNum") == GetClientTeam(iExclude))
		{
			return false;
		}
	}
	else if (StrEqual(class, "func_respawnroomvisualizer"))
	{
		return false;
	}
	else if (StrContains(class, "tf_projectile_", false) != -1)
	{
		return false;
	}

	return !(entity == iExclude);
}

stock void SetEyeAngles(int client, float target_point[3])
{
	float angle[3];
	GetVectorAngles(target_point, angle);

	angle[0] = AngleNormalize(angle[0]);
	angle[1] = AngleNormalize(angle[1]);
	angle[2] = 0.0;

	TeleportEntity(client, NULL_VECTOR, angle, NULL_VECTOR);
}

stock float AngleNormalize(float angle)
{
	angle = angle - 360.0 * RoundToFloor(angle / 360.0);
	while (angle > 180.0) angle -= 360.0;
	while (angle < -180.0) angle += 360.0;
	return angle;
}

stock bool AcceptableAngle(int bot, int target)
{
	float botrot[3], botpos[3], targpos[3], botvec[3], targvec[3];
	GetClientEyeAngles(bot, botrot);
	GetClientAbsOrigin(bot, botpos);
	GetClientAbsOrigin(target, targpos);

	botrot[0] = 0.0; //zero pitch;

	GetAngleVectors(botrot, botvec, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(CalcAngle(botpos, targpos), targvec, NULL_VECTOR, NULL_VECTOR); //get forward vector of the angle between target and bot

	float pitch[3];
	GetVectorAngles(targvec, pitch); //Get angles of new vector
	pitch[1] = 0.0; //zero yaw, we only want pitch
	ClampAngle(pitch);
	//GetAngleVectors(pitch, targvec, NULL_VECTOR, NULL_VECTOR); //Get forward vector of the pitch between target and bot

	//float angle = RadToDeg(ArcCosine(GetVectorDotProduct(botvec, targvec))); //Find angle in degrees
	//PrintCenterText(target, "BotYaw: %.1f AnglePitch: %.1f Angle: %.1f", botrot[1], (pitch[0] * -1.0), angle);

	if ((pitch[0] * -1) >= 45.0) //Max walkable slope angle is 45 degrees, so if the angle to a target is steeper than this, it is not an acceptable angle
		return false;
	return true;
}

stock bool CheckSniperShouldAim(int bot)
{
	if (TF2_GetPlayerClass(bot) == TFClass_Sniper && IsValidClient(bot))
	{
		if (IsCustomBot(bot))
		{
			if (AimDelay[bot] <= GetEngineTime() && !TF2_IsPlayerInCondition(bot, TFCond_Slowed))
				return true;
		}
	}
	return false;
}

stock char[] GetLiteralClassName(int iClassIndex, char[] sName, int iBufferSize)
{
	switch (iClassIndex)
	{
		case 1: Format(sName, iBufferSize, "scout");
		case 2: Format(sName, iBufferSize, "sniper");
		case 3: Format(sName, iBufferSize, "soldier");
		case 4: Format(sName, iBufferSize, "demo");
		case 5: Format(sName, iBufferSize, "medic");
		case 6: Format(sName, iBufferSize, "heavy");
		case 7: Format(sName, iBufferSize, "pyro");
		case 8: Format(sName, iBufferSize, "spy");
		case 9: Format(sName, iBufferSize, "engineer");
	}
}

stock bool CreateHat(int client, int itemindex, int quality = 6, int level = 0, int effect = 0, int paint = 0, int paint2 = 0)
{
	char entname[64];
	switch (itemindex)
	{
		case 131, 406, 1099, 1144: //Demo Shields
		{
			Format(entname, sizeof entname, "tf_wearable_demoshield");
		}
		case 57: //razorback
		{
			Format(entname, sizeof entname, "tf_wearable_razorback");
		}
		default: Format(entname, sizeof entname, "tf_wearable");
	}
	int hat = CreateEntityByName(entname);

	if (!IsValidEntity(hat))
	{
		return false;
	}

	char entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex", itemindex);
	SetEntProp(hat, Prop_Send, "m_bInitialized", 1);
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), quality);

	if (level)
	{
		SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomInt(1,100));
	}
	if (effect != 0)
		TF2Attrib_SetByDefIndex(hat, 134, float(effect));

	if (paint != 0) //red team paint
	{
		TF2Attrib_SetByDefIndex(hat, 142, float(paint));
	}
	if (paint2 != 0) //blue team paint
		TF2Attrib_SetByDefIndex(hat, 261, float(paint2));
	else
		TF2Attrib_SetByDefIndex(hat, 261, float(paint));

	DispatchSpawn(hat);
	SDKCall(g_hWearableEquip, client, hat);
	return true;
}

stock int CreateWeapon(int client, char[] name, int index, int level, int quality, char[] attribute, bool visible = true, bool preserve = true)
{
	if(StrEqual(name,"saxxy", false)) // if "saxxy" is specified as the name, replace with appropiate name
	{
		switch(TF2_GetPlayerClass(client))
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
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Soldier:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_soldier", false);
			case TFClass_Pyro:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_pyro", false);
			case TFClass_Heavy:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_hwg", false);
			case TFClass_Engineer:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_primary", false);
			default:		ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_soldier", false);
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
				return -1;
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
		PrintToServer("[CustomBots] Error: Invalid weapon spawned. client=%d name=%s idx=%d attr=%s", client, name, index, attribute);
		return -1;
	}

	int entity = TF2Items_GiveNamedItem(client, weapon);

	CloseHandle(weapon);

	PrepareItem(client, entity, name, visible);

	return entity;
}

stock void PrepareWeapon(int client, int weapon, bool visibility = false)
{
	if (!visibility)
	{
		SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", -1);
		SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", 0.001);
	}
	else
	{
		SetEntProp(weapon, Prop_Send, "m_bValidatedAttachedEntity", 1); // Magic!
	}
	EquipPlayerWeapon(client, weapon);
}

stock int EquipWearable(int client, bool vm, int weapon = 0, bool visactive = true)
{
	int wearable = CreateWearable(client, Mdl, vm);
	if (wearable == -1) return -1;
	wearableOwner[wearable] = client;
	if (weapon > MaxClients)
	{
		tiedEntity[wearable] = weapon;
		hasWearablesTied[weapon] = true;
		onlyVisIfActive[wearable] = visactive;

		int effects = GetEntProp(wearable, Prop_Send, "m_fEffects");
		if (weapon == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")) SetEntProp(wearable, Prop_Send, "m_fEffects", effects & ~32);
		else SetEntProp(wearable, Prop_Send, "m_fEffects", effects |= 32);
	}
	return wearable;
}

stock int CreateWearable(int client, bool vm)
{
	int ent = CreateEntityByName(vm ? "tf_wearable_vm" : "tf_wearable");
	if (!IsValidEntity(ent)) return -1;

	SetEntProp(ent, Prop_Send, "m_fEffects", 129);
	SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(client));
	SetEntProp(ent, Prop_Send, "m_usSolidFlags", 4);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 11);
	DispatchSpawn(ent);
	SetVariantString("!activator");
	ActivateEntity(ent);
	TF2_EquipWearable(client, ent);
	return ent;
}

stock void TF2_EquipWearable(int client, int Ent)
{
	if (g_bSdkStarted == false || g_hSdkEquipWearable == null)
	{
		TF2_SdkStartup();
		LogMessage("Error: Can't call EquipWearable, SDK functions not loaded! If it continues to fail, reload plugin or restart server. Make sure your gamedata is intact!");
	}
	else
	{
		SDKCall(g_hSdkEquipWearable, client, Ent);
	}
}

stock bool TF2_SdkStartup()
{
	Handle hGameConf = LoadGameConfigFile("Bots.Wearables");
	if (hGameConf == null)
	{
		LogMessage("Couldn't load SDK functions. Make sure Bots.Wearables.txt is in your gamedata folder! Restart server if you want wearable weapons.");
		return false;
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSdkEquipWearable = EndPrepSDKCall();

	CloseHandle(hGameConf);
	g_bSdkStarted = true;
	return true;
}

stock void PrepareItem(int client, int entity, const char[] classname, bool visibility = false)
{
	if (!visibility)
	{
		SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
	}
	else
	{
		SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", 1);
	}

	if (StrContains(classname, "tf_wearable")==-1)
	{
		EquipPlayerWeapon(client, entity);
	}
	else
	{
		Wearable_EquipWearable(client, entity);
	}
}

Handle S93SF_equipWearable = null;
stock void Wearable_EquipWearable(int client, int wearable)
{
	if (S93SF_equipWearable == null)
	{
		Handle config = LoadGameConfigFile("Bots.Wearables");
		if(config == null)
		{
			LogError("[CustomBots] Bots.Wearables gamedata could not be found.");
			return;
		}

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(config, SDKConf_Virtual, "EquipWearable");
		CloseHandle(config);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		if ((S93SF_equipWearable=EndPrepSDKCall()) == null)
		{
			LogError("[CustomBots] Couldn't load SDK function (CTFPlayer::EquipWearable). SDK call failed.");
			return;
		}
	}
	SDKCall(S93SF_equipWearable, client, wearable);
}

stock void TF2_SwitchToSlot(int client, int slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		char classname[64];
		int wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, classname, sizeof(classname)))
		{
			FakeClientCommandEx(client, "use %s", classname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

stock float GetPlayerMaxSpeed(int client, bool backwards = false)
{
	float speed;
	switch (TF2_GetPlayerClass(client))
	{
		case TFClass_Scout:
		{
			speed = 400.0;
			if (backwards)
				speed = 360.0;
		}
		case TFClass_Soldier:
		{
			speed = 240.0;
			if (backwards)
				speed = 216.0;
		}
		case TFClass_Pyro, TFClass_Sniper, TFClass_Engineer:
		{
			speed = 300.0;
			if (backwards)
				speed = 270.0;
			if (TF2_IsPlayerInCondition(client, TFCond_Slowed))
				speed = 80.0;
		}
		case TFClass_Medic, TFClass_Spy:
		{
			speed = 320.0;
			if (backwards)
				speed = 288.0;
		}
		case TFClass_DemoMan:
		{
			speed = 280.0;
			if (backwards)
				speed = 252.0;
		}
		case TFClass_Heavy:
		{
			speed = 230.0;
			if (backwards)
				speed = 207.0;
		}
	}
	return speed;
}

stock bool TargetInRange(int client, int target, bool flare = false, float distance = 0.0)
{
	if (TargetIsValid(client, target) && IsCustomBot(client) && IsValidClient(client))
	{
		float pos[3], targpos[3];
		GetClientEyePosition(client, pos);
		GetClientAbsOrigin(target, targpos);
		targpos[2] += 30.0;

		if (CheckTrace(client, target))
		{
			float flDistance = GetVectorDistance(pos, targpos);
			if (flare)
			{
				//PrintCenterTextAll("Flare Override: %.1f\nCurrentDistance: %.1f", distance, flDistance);
				if (flDistance >= distance)
					return true;
				else
					return false;
			}
			if (distance > 0.0)
			{
				//PrintCenterTextAll("Bot Pos: %.1f %.1f %.1f\nTarget Pos: %.1f %.1f %.1f\nRange: %.1f\nCurrent Distance: %.1f", pos[0], pos[1], pos[2], targpos[0], targpos[1], targpos[2], distance, flDistance);
				if (flDistance <= distance)
					return true;
				else
					return false;
			}
			if (flDistance <= AttackRange[client])
			{
				return true;
			}
		}
	}
	return false;
}

stock bool TargetIsValid(int bot, int target)
{
	if (target == bot)
		return false;
	if (!IsValidClient(target))
		return false;
	if (!IsPlayerAlive(target))
		return false;

	if (TF2_IsPlayerInCondition(target, TFCond_Ubercharged))
		return false;

	return true;
}

stock float GetBotAttackRange(int bot)
{
	if (IsValidClient(bot) && IsCustomBot(bot))
	{
		if (BotIndex[bot] > 0)
		{
			float flRange;
			KeyValues kv = new KeyValues("BotIndexes");

			char sPath[PLATFORM_MAX_PATH];
			BuildPath(Path_SM, sPath, sizeof sPath, "configs/botindexes.txt");
			kv.ImportFromFile(sPath);

			char sBotIndex[8];
			IntToString(BotIndex[bot], sBotIndex, sizeof sBotIndex);

			if (!kv.JumpToKey(sBotIndex))
			{
				//PrintToChatAll("Could not find bot index: %i", BotIndex[bot]);
				delete kv;
				return 0.0;
			}

			flRange = kv.GetFloat("range", 800.0);

			delete kv;
			return flRange;
		}
	}
	return 800.0;
}

stock bool HasShield(int client)
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "tf_wearable_razorback")) != -1)
	{
		if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
		{
			shield[client] = entity;
			return true;
		}
	}
	entity = -1;
	while ((entity = FindEntityByClassname(entity, "tf_wearable_demoshield")) != -1)
	{
		if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
		{
			shield[client] = entity;
			return true;
		}
	}
	return false;
}

/*

Hitbox selection and positions

This is where we determine how a bot will attack a target

*/

enum //hitgroups
{
	HITGROUP_GENERIC,
	HITGROUP_HEAD,
	HITGROUP_CHEST,
	HITGROUP_STOMACH,
	HITGROUP_LEFTARM,
	HITGROUP_RIGHTARM,
	HITGROUP_LEFTLEG,
	HITGROUP_RIGHTLEG,

	NUM_HITGROUPS
};

int g_iHitBoxOrderHeadshot[] = //Gets hitboxes in this order
{
	HITGROUP_HEAD,
	HITGROUP_CHEST,
	HITGROUP_STOMACH,
	HITGROUP_GENERIC,
	HITGROUP_LEFTARM,
	HITGROUP_RIGHTARM,
	HITGROUP_LEFTLEG,
	HITGROUP_RIGHTLEG,
}

int g_iHitBoxOrderBullet[] =
{
	HITGROUP_STOMACH,
	HITGROUP_CHEST,
	HITGROUP_GENERIC,
	HITGROUP_HEAD,
	HITGROUP_LEFTARM,
	HITGROUP_RIGHTARM,
	HITGROUP_LEFTLEG,
	HITGROUP_RIGHTLEG,
}

stock bool GetBestHitBox(int client, int entity, float vBestOut[3], bool head = false)
{
	Address pStudioHdr = Address(Dereference(Address(GetEntData(entity, g_iOffsetStudioHdr))));
	if (pStudioHdr == Address_Null)
		return false;

	int m_nHitboxSet = GetEntProp(entity, Prop_Send, "m_nHitboxSet");
	if (m_nHitboxSet != 0)
		return false;

	Address pHitBoxSet = pStudioHdr + Address(ReadInt(pStudioHdr + Address(0xB0)));
	if (pHitBoxSet == Address_Null)
		return false;

	int iNumHitboxes = ReadInt(pHitBoxSet + Address(0x4));

	pHitBoxSet += Address(0xC);

	//Loop all hitgroups
	for (int i = 0; i < NUM_HITGROUPS; i++)
	{
		//Match hitgroup to order we want to check
		int hitGroup = (head ? (g_iHitBoxOrderHeadshot[i]) : (g_iHitBoxOrderBullet[i]));

		if (head && hitGroup != HITGROUP_HEAD)
			continue;

		for (int iHitBox = 0; iHitBox < iNumHitboxes; iHitBox++)
		{
			Address pbox = Address(pHitBoxSet + Address(iHitBox * 68));
			if (pbox == Address_Null)
				continue;

			int iBone = ReadInt(pbox);
			int iGroup = ReadInt(pbox + Address(0x4));

			if (iGroup != hitGroup)
				continue;

			float vBonePosition[3], vBoneAngles[3];
			GetBonePosition(entity, iBone, vBonePosition, vBoneAngles);
			bool bVisible = false;

			if (head && iGroup == HITGROUP_HEAD)
			{
				float vMins[3]; vMins = ExtractVectorFromAddress(pbox + Address(0x8));
				float vMaxs[3]; vMaxs = ExtractVectorFromAddress(pbox + Address(0x14));

				//Hitbox Size
				float vSize[3];
				vSize[0] = FloatAbs(vMaxs[0]) + FloatAbs(vMins[0]);
				vSize[1] = FloatAbs(vMaxs[1]) + FloatAbs(vMins[1]);
				vSize[2] = FloatAbs(vMaxs[2]) + FloatAbs(vMins[2]);

				//Hitbox Origin
				float vCenter[3];
				AddVectors(vMins, vMaxs, vCenter);
				ScaleVector(vCenter, 0.5);

				//Angle vectors
				float vForward[3], vLeft[3], vUp[3];
				GetAngleVectors(vBoneAngles, vForward, vLeft, vUp);

				//Center bone pos to hitbox
				vBonePosition[0] += vLeft[2] * vCenter[2];
				vBonePosition[1] += vLeft[0] * vCenter[0];
				vBonePosition[2] -= vLeft[2] * vCenter[1];
			}

			float eyePos[3];
			GetClientEyePosition(client, eyePos);
			bVisible = (IsPointVisible(client, entity, eyePos, vBonePosition, hitGroup));


			if (bVisible)
			{
				vBestOut = vBonePosition;

				return true;
			}
		}
	}

	return false;
}

stock int ReadInt(Address pAddr)
{
	if (pAddr == Address_Null)
	{
		return -1;
	}

	return LoadFromAddress(pAddr, NumberType_Int32);
}

stock float[] VelocityExtrapolate(int client, float eyepos[3])
{
	float absVel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", absVel);

	float v[3];

	v[0] = eyepos[0] + (absVel[0] * GetTickInterval());
	v[1] = eyepos[1] + (absVel[1] * GetTickInterval());
	v[2] = eyepos[2] + (absVel[2] * GetTickInterval());

	return v;
}

stock bool IsPointVisible(int looker, int target, float start[3], float point[3], int expectedHitGroup, bool bHeahdshot = true)
{
	TR_TraceRayFilter(start, point, MASK_SHOT | CONTENTS_GRATE, RayType_EndPoint, AimTargetFilter, looker);

	int hitGroup = TR_GetHitGroup();
	int hitEnt = TR_GetEntityIndex();
	//PrintToChatAll("Found Hitgroup: %i | Entity: %i | Target: %N", hitGroup, hitEnt, target);

	if (!TR_DidHit() || hitEnt == target)
	{
		//Ignore hitgroup expectance if not headshot only.
		if (bHeahdshot && hitGroup == expectedHitGroup)
		{
			return true;
		}
		else
		{
			return true;
		}
	}

	return false;
}

stock int LookupBone(int iEntity, const char[] szName)
{
	return SDKCall(g_hLookupBone, iEntity, szName);
}

public bool AimTargetFilter(int entity, int contentsMask, any iExclude)
{
	char class[64];
	GetEntityClassname(entity, class, sizeof(class));

	if (StrEqual(class, "entity_medigun_shield"))
	{
		if (GetEntProp(entity, Prop_Send, "m_iTeamNum") == GetClientTeam(iExclude))
		{
			return false;
		}
	}
	else if (StrEqual(class, "func_respawnroomvisualizer"))
	{
		return false;
	}
	else if (StrContains(class, "tf_projectile_", false) != -1)
	{
		return false;
	}

	return !(entity == iExclude);
}


stock void GetBonePosition(int iEntity, int iBone, float origin[3], float angles[3])
{
	SDKCall(g_hGetBonePosition, iEntity, iBone, origin, angles);
}

stock Address Transpose(Address pAddr, int iOffset)
{
	return Address(int(pAddr) + iOffset);
}

stock int Dereference(Address pAddr, int iOffset = 0)
{
	if (pAddr == Address_Null)
	{
		return -1;
	}

	return ReadInt(Transpose(pAddr, iOffset));
}

stock int GetOpposingTeam(int team)
{
	int iOther;
	switch (team)
	{
		case 2: iOther = 3;
		case 3: iOther = 2;
		default: iOther = 0;
	}
	return iOther;
}

stock bool IsCustomBot(int bot)
{
	if (IsFakeClient(bot))
	{
		if (BotIndex[bot] > 0 || bIsHookedBot[bot])
			return true;
	}

	return false;
}

stock float[] ExtractVectorFromAddress(Address address)
{
	float v[3];

	v[0] = view_as<float>(ReadInt(address + Address(0x0)));
	v[1] = view_as<float>(ReadInt(address + Address(0x4)));
	v[2] = view_as<float>(ReadInt(address + Address(0x8)));

	return v;
}

stock int CreateParticle(int entity, char[] particleType, float offset = 0.0, bool attach = false)
{
	int particle = CreateEntityByName("info_particle_system");

	char targetName[128];
	float position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[2] += offset;
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	Format(targetName, sizeof(targetName), "target%i", entity);
	DispatchKeyValue(entity, "targetname", targetName);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(targetName);
	if(attach)
	{
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	}
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	return particle;
}
