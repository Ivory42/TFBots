//VERY OLD
//No idea if this even works anymore and I haven't touched it in over a year
//
//The original idea was to allow players to control bots while in spectator...
//it worked but since spectator is handled by the server there tends to be severe delays with higher ping

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2>
#include <tf2items>
#include <freak_fortress_2_extras> //????

//Game settings
int bKillcount = 0;
int rKillcount = 0;
int KillTarget = 0;

//This syntax makes me want to vomit :C

//Bot Settings
Handle g_hBotQuota;
bool:CanMove[MAXPLAYERS+1];
bool:CanJump[MAXPLAYERS+1];
bool:CanShoot[MAXPLAYERS+1];
bool:AbilityOneActivate[MAXPLAYERS+1];
float FirePos[MAXPLAYERS+1][3];
float MoveCooldown[MAXPLAYERS+1] = 99999999.0;
int LastSpawned;
float attackCooldown[MAXPLAYERS+1];
int attackCount[MAXPLAYERS+1];
int CurrentAmmo[MAXPLAYERS+1];
int PlayerHP[MAXPLAYERS+1];
int RespawnTime[MAXPLAYERS+1];

//Hud Setup
new Handle:statHud;
new Handle:reticle;
new Handle:scorehud;

//Player Settings
int TeamNum[MAXPLAYERS+1];
int PlayerBotID[MAXPLAYERS+1];
float rMovePos[3];
float bMovePos[3];
int MoveSprite = -1;
int AttackSprite = -1;
//new LightningSprite;

new String:modName[32];

public Plugin:myinfo =
{
	name = "TF2 MOBA",
	author = "IvoryPal",
	description = "MOBA mode for TF2",
	version = "1.0",
	url = "https://steamcommunity.com/groups/VersusPonyvilleReborn"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_menumoba", RTSMenu);
	RegConsoleCmd("sm_ability1", Ability1);
	HookEvent("post_inventory_application", BotResupply);
	HookEvent("player_death", BotDeath, EventHookMode_Pre);
	//HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("player_team", Event_JoinTeam, EventHookMode_Post);
	AddCommandListener(UnitAttack, "spec_next");
	AddCommandListener(UnitMove, "spec_prev");
	AddCommandListener(CommandEmpty, "spec_mode");
	g_hBotQuota = FindConVar("tf_bot_quota");
	//LightningSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	MoveSprite = PrecacheModel("materials/sprites/blueglow2.vmt");
	AttackSprite = PrecacheModel("materials/sprites/redglow2.vmt");

	//initialize huds
	statHud = CreateHudSynchronizer();
	reticle = CreateHudSynchronizer();
	scorehud = CreateHudSynchronizer();

	//initialize variables
	bKillcount = 0;
	rKillcount = 0;
	KillTarget = 50;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			TeamNum[i] = 0;
		}
	}
}

public Action:Ability1(int client, int args)
{
		attackCount[PlayerBotID[client]] = 0;
		AbilityOneActivate[PlayerBotID[client]] = true;
		//AbilityOneCooldown[client] = GetEngineTime()+3.0;
}

public Action UnitAttack(int client, const char[] command, int argc)
{
	if (attackCooldown[client] >= GetEngineTime())
		return Plugin_Handled;

	new Float:vAng[3], Float:vPos[3];
	//int color[4];

	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);
	new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_PLAYERSOLID, RayType_Infinite, FilterAim, client);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(FirePos[PlayerBotID[client]], trace);
		CanShoot[PlayerBotID[client]] = true;
		attackCooldown[client] = GetEngineTime()+0.5;
		HudSprite(FirePos[PlayerBotID[client]], 1.0, 2.0, 60, client, AttackSprite);
	}
	CloseHandle(trace);
	return Plugin_Handled;
}

int HudSprite(Float:pos[3], Float:lifetime, Float:size, int brightness, int client, int Sprite)
{
	TE_SetupGlowSprite(pos, Sprite, lifetime, size, brightness);
	TE_SendToClient(client);
}

public Action CommandEmpty(int client, const char[] command, int argc)
{
	if (TeamNum[client] >= 1)
	{
		CanJump[PlayerBotID[client]] = true;
		return Plugin_Handled;
	}
	else
		return Plugin_Continue;
}

public Action UnitMove(int client, const char[] command, int argc)
{
	if (PlayerBotID[client] <= 0)
	{
			PrintToChat(client, "No selected unit");
			return Plugin_Handled;
	}
	else
			PrintToChat(client, "Selected Unit ID: %i", PlayerBotID[client]);

	new Float:vAngles[3], Float:vPos[3], Float:vTargetPos[3];

	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAngles);
	new Handle:trace = TR_TraceRayFilterEx(vPos, vAngles, MASK_PLAYERSOLID, RayType_Infinite, FilterAim, client);

	if(TR_DidHit(trace))
	{
		switch (TeamNum[client])
		{
			case 2:
			{
				TR_GetEndPosition(rMovePos, trace);
				CanMove[PlayerBotID[client]] = true;
				MoveCooldown[client] = GetEngineTime()+3.0;
				HudSprite(rMovePos, 1.0, 2.0, 60, client, MoveSprite);
			}
			case 3:
			{
				TR_GetEndPosition(bMovePos, trace);
				CanMove[PlayerBotID[client]] = true;
				MoveCooldown[client] = GetEngineTime()+3.0;
				HudSprite(bMovePos, 1.0, 2.0, 60, client, MoveSprite);
			}
		}
	}
	CloseHandle(trace);


	//TE_SetupGlowSprite(float pos[3], int Model, float Life, float Size, int Brightness)
	//TE_SendToClient(client, 0.1);
	return Plugin_Handled;
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool& result)
{
		if (IsFakeClient(client))
		{
			//CanMove[client] = false;
			CanShoot[client] = false;
			CurrentAmmo[client] = GetEntProp(weapon, Prop_Data, "m_iClip1");
			SetEntProp(client, PropType:1, "m_iAmmo", 200, _, 1);
			PrintToChatAll("ammo: %i", CurrentAmmo[client]);
		}
}

Float:moveForward(Float:vel[3],Float:MaxSpeed)
{
	vel[0] = MaxSpeed;
	return vel;
}

public Action:Event_JoinTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new selected_team = 0;

	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}

	selected_team = GetEventInt(event, "team");

	switch (selected_team)
	{
		case 1:
		{
			StartMenu(client);
		}
		case 2:
		{
			ChangeClientTeam(client, 1);
			StartMenu(client);
		}
		case 3:
		{
			ChangeClientTeam(client, 1);
			StartMenu(client);
		}
	}
	return Plugin_Continue;
}

public void OnClientAuthorized(int client)
{
	if (!IsFakeClient(client))
	{
		TeamNum[client] = 0;
	}
}

public BotResupply(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (IsFakeClient(client))
	{
		LastSpawned = client;
		switch (TF2_GetPlayerClass(client))
		{
			case TFClass_Soldier:
			{
				TF2_RemoveAllWeapons(client);
				SpawnWeapon2(client, "tf_weapon_rocketlauncher", 18, 1, 6, "6 ; 0.01 ; 97 ; 0.01 ; 76 ; 5", 0, true);
				SetEntProp(client, PropType:1, "m_iAmmo", 200, _, 1);
				//CurrentAmmo[client] = GetEntProp(weapon, Prop_Data, "m_iClip1");
			}
		}
	}
}

public Action:RTSMenu(client, args)
{
	if (IsValidClient(client))
	{
		if (TeamNum[client] >= 2)
				Menu_RTS(client);
	}
}

public Action:StartMenu(int client)
{
	Menu start = new Menu(Start_Menu, MENU_ACTIONS_ALL);
	start.SetTitle("Select a team");

	start.AddItem("#red", "RED");
	start.AddItem("#blue", "BLU");
	start.ExitButton = false;
	start.Display(client, 0);

	return Plugin_Handled;
}

public int Start_Menu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if (StrEqual(info, "#red"))
      {
        TeamNum[param1] = 2;
				PrintToChat(param1, "joined red team");
				Menu_RTS(param1);
      }
			if (StrEqual(info, "#blue"))
			{
				TeamNum[param1] = 3;
				PrintToChat(param1, "joined blue team");
				Menu_RTS(param1);
			}
    }

    case MenuAction_End:
		{
			delete menu;
		}

		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);

			return style;
		}
	}
	return 0;
}

public Action:Menu_RTS(int client)
{
	Menu hvh = new Menu(MenuRTS, MENU_ACTIONS_ALL);
	hvh.SetTitle("Select Class");

	hvh.AddItem("#Scout", "Scout");
	hvh.AddItem("#Sniper", "Sniper");
	hvh.AddItem("Soldier", "Soldier");
	hvh.ExitButton = false;
	hvh.Display(client, 0);

	return Plugin_Handled;
}

public int MenuRTS(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			//new TFClass:class;
			if (StrEqual(info, "#Scout"))
      {
        SpawnBot(param1, TFClass_Scout);
				//Menu_Scout(param1);
      }
			if (StrEqual(info, "#Sniper"))
			{
				SpawnBot(param1, TFClass_Sniper);
				//Menu_Sniper(param1);
			}
			if (StrEqual(info, "Soldier"))
			{
				SpawnBot(param1, TFClass_Soldier);
				//Menu_Soldier
			}
    }

    case MenuAction_End:
		{
			delete menu;
		}

		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);

			return style;
		}
	}
	return 0;
}

SpawnBot(int client, TFClassType:class)
{
	if (IsValidClient(client))
	{
		new String:name[32];
		GetClientName(client, name, sizeof(name));
		switch (TeamNum[client])
		{
			case 2: //Red team
			{
				switch (class)
				{
					case TFClass_Scout:
					{
						ServerCommand("tf_bot_add 1 scout red expert %s", name);
					}
					case TFClass_Sniper:
					{
						ServerCommand("tf_bot_add 1 sniper red expert %s", name);
					}
					case TFClass_Soldier:
					{
						ServerCommand("tf_bot_add 1 soldier red expert %s", name);
					}
				}
			}
			case 3: //blue
			{
				switch (class)
				{
					case TFClass_Scout:
					{
						ServerCommand("tf_bot_add 1 scout blue expert %s", name);
					}
					case TFClass_Sniper:
					{
						ServerCommand("tf_bot_add 1 sniper blue expert %s", name);
					}
					case TFClass_Soldier:
					{
						ServerCommand("tf_bot_add 1 soldier blue expert %s", name);
					}
				}
			}
		}
		CreateTimer(0.5, AssignPlayerID, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:AssignPlayerID(Handle:Timer, int client)
{
	PlayerBotID[client] = LastSpawned;
	PrintToChat(client, "Assigned Bot ID: %i", PlayerBotID[client]);
}

public Action:RespawnBot(Handle:Timer, int client)
{
	if (RespawnTime[client] <= 0)
	{
		TF2_RespawnPlayer(client);
		RespawnTime[client] = 5;
		return Plugin_Stop;
	}
	else
	{
		RespawnTime[client]--;
		PrintToChatAll("Respawn: %i", RespawnTime[client]);
	}
	return Plugin_Continue;
}

public Action:TeleBot(Handle:Timer, int client)
{
	new Float:vAngles[3], Float:vPos[3], Float:vTargetPos[3];

	GetClientEyePosition(client,vPos);
	GetClientEyeAngles(client, vAngles);
	new Handle:trace = TR_TraceRayFilterEx(vPos, vAngles, MASK_PLAYERSOLID, RayType_Infinite, FilterAim, client);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(vTargetPos, trace);
	}
	CloseHandle(trace);

	PrintToChat(client, "Spawned bot");

	TeleportEntity(LastSpawned, vTargetPos, NULL_VECTOR, NULL_VECTOR);
}

public bool:FilterAim(int entity, int contentsMask, int client)
{
	//return entity > MAX_PLAYERS || !entity;
	if (entity == client)
	{
			return false;
	}
	return true;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3])
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				if (CanMove[client])
				{
					float chainDistancebot;
					decl Float:camangle[3], Float:clientEyes[3], Float:targetEyes[3];
					GetClientEyePosition(client, clientEyes);
					if (GetClientTeam(client) == 2)
							chainDistancebot = GetVectorDistance(clientEyes, rMovePos)
					else if (GetClientTeam(client) == 3)
							chainDistancebot = GetVectorDistance(clientEyes, bMovePos)
					if (chainDistancebot >= 100.0)
					{
						decl Float:vec[3],Float:angle[3];

						if (GetClientTeam(client) == 2)
								MakeVectorFromPoints(rMovePos, clientEyes, vec);
						else if (GetClientTeam(client) == 3)
								MakeVectorFromPoints(bMovePos, clientEyes, vec);

						GetVectorAngles(vec, camangle);
						camangle[0] *= -1.0;
						camangle[1] += 180.0;

						ClampAngle(camangle);
						TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
						switch (TF2_GetPlayerClass(client))
						{
							case TFClass_Scout: vel = moveForward(vel, 400.0);
							case TFClass_Medic: vel = moveForward(vel, 320.0);
							case TFClass_Soldier: vel = moveForward(vel, 240.0);
							case TFClass_Heavy: vel = moveForward(vel, 230.0);
							default: vel = moveForward(vel, 300.0);
						}
					}
					else if (chainDistancebot < 100.0 && CanMove[client])
					{
						CanMove[client] = false;
					}
				}
				if (CanShoot[client])
				{
					decl Float:AimAngle[3], Float:clientEyes[3], Float:targetEyes[3], Float:vec[3], Float:angle[3];
					GetClientEyePosition(client, clientEyes);

					MakeVectorFromPoints(FirePos[client], clientEyes, vec);
					//GetClientEyeAngles(client, vAngles);
					//new Handle:trace = TR_TraceRayFilterEx(vPos, FirePos[client], MASK_PLAYERSOLID, RayType_EndPoint, FilterAim, client);

					GetVectorAngles(vec, AimAngle);
					AimAngle[0] *= -1.0;
					AimAngle[1] += 180.0;

					ClampAngle(AimAngle);
					TeleportEntity(client, NULL_VECTOR, AimAngle, NULL_VECTOR);
					buttons |= IN_ATTACK;
					CanShoot[client] = false;
				}
				if (CanJump[client])
				{
					buttons |= IN_JUMP;
					CanJump[client] = false;
				}
				if (AbilityOneActivate[client])
				{
					CreateTimer(0.2, Soldier_Barrage, client, TIMER_REPEAT);
					AbilityOneActivate[client] = false;
				}
			}
		}
		else if (!IsFakeClient(client) && GetClientTeam(client) == 1 && IsValidClient(PlayerBotID[client]))
		{
			//RETICLE
			if (TeamNum[client] == 2) //red hud
				SetHudTextParams(-1.0, -1.0, 0.2, 255, 20, 20, 0);
			else if (TeamNum[client] == 3) //blue hud
				SetHudTextParams(-1.0, -1.0, 0.2, 20, 20, 255, 0);

			ShowSyncHudText(client, reticle, "+");

			//ABILITIES
			if (TeamNum[client] == 2) //red hud
				SetHudTextParams(-1.0, 0.7, 0.2, 255, 20, 20, 0);
			else if (TeamNum[client] == 3) //blue hud
				SetHudTextParams(-1.0, 0.7, 0.2, 20, 20, 255, 0);

			PlayerHP[PlayerBotID[client]] = GetPlayerHealth(PlayerBotID[client]);
			char cooldown[16];
			char respawn[32];
			char bothp[16];
			Format(cooldown, sizeof(cooldown), " (%.1fs)", attackCooldown[client] - GetEngineTime());
			Format(respawn, sizeof(respawn), "(Respawn in: %is)", RespawnTime[PlayerBotID[client]]);
			Format(bothp, sizeof(bothp), "Health: %i", PlayerHP[PlayerBotID[client]])
			if (TeamNum[client] != 0)
			{
				switch (TF2_GetPlayerClass(PlayerBotID[client]))
				{
					case TFClass_Soldier:
					{
						ShowSyncHudText(client, statHud, "Primary Attack %s\n1. Barrage\n2. Ability2\n3. Ability3\n%s", attackCooldown[client] <= GetEngineTime() ? "" : cooldown, IsPlayerAlive(PlayerBotID[client]) ? bothp : respawn);
					}
					case TFClass_Scout:
					{
						ShowSyncHudText(client, statHud, "Primary Attack %s\n1. Ability1\n2. Ability2\n3. Ability3\n%s", attackCooldown[client] <= GetEngineTime() ? "" : cooldown, IsPlayerAlive(PlayerBotID[client]) ? bothp : respawn);
					}
					case TFClass_Sniper:
					{
						ShowSyncHudText(client, statHud, "Primary Attack %s\n1. Ability1\n2. Ability2\n3. Ability3\n%s", attackCooldown[client] <= GetEngineTime() ? "" : cooldown, IsPlayerAlive(PlayerBotID[client]) ? bothp : respawn);
					}
					default:
					{
						return Plugin_Continue;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Soldier_Barrage(Handle:Timer, int client)
{
	if (attackCount[client] < 4 && !CanShoot[client])
	{
		CanShoot[client] = true;
		//PrintToChatAll("barrage");
		attackCount[client]++;
	}
	if (attackCount[client] >= 4)
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

stock ClampAngle(Float:fAngles[3])
{
	while(fAngles[0] > 89.0)  fAngles[0]-=360.0;
	while(fAngles[0] < -89.0) fAngles[0]+=360.0;
	while(fAngles[1] > 180.0) fAngles[1]-=360.0;
	while(fAngles[1] <-180.0) fAngles[1]+=360.0;
}

EndRound(int teamnum)
{
	//victory conditions
}

stock bool:IsValidClient(client, bool:replaycheck=true)
{
	if(client<=0 || client>MaxClients)
	{
		return false;
	}

	if(!IsClientInGame(client))
	{
		return false;
	}

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}

	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	return true;
}

stock SpawnWeapon(client, String:name[], index, level, qual, String:att[])
{
	new Handle:hWeapon=TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if(hWeapon==INVALID_HANDLE)
	{
		return -1;
	}

	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count=ExplodeString(att, ";", atts, 32, 32);

	if(count % 2)
	{
		--count;
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2;
		for(new i; i<count; i+=2)
		{
			new attrib=StringToInt(atts[i]);
			if(!attrib)
			{
				LogError("Bad weapon attribute passed: %s ; %s", atts[i], atts[i+1]);
				CloseHandle(hWeapon);
				return -1;
			}

			TF2Items_SetAttribute(hWeapon, i2, attrib, StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(hWeapon, 0);
	}

	new entity=TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

public Action:BotDeath(Handle:event, const String:eventName[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid")), attacker=GetClientOfUserId(GetEventInt(event, "attacker"));

	if (IsFakeClient(attacker) && IsFakeClient(client))
	{
		if (GetClientTeam(attacker) == 2) //red team
		{
			rKillcount++;
			CanMove[client] = false;
			PrintToChatAll("RED Score: %i", rKillcount)
			if (rKillcount >= KillTarget)
			{
				rKillcount = KillTarget;
				EndRound(2);
			}
		}
		else if (GetClientTeam(attacker) == 3) //blue team
		{
			bKillcount++;
			CanMove[client] = false;
			PrintToChatAll("BLU Score: %i", bKillcount)
			if (bKillcount >= KillTarget)
			{
				bKillcount = KillTarget;
				EndRound(3);
			}
		}
	}
	RespawnTime[client] = 5;
	CreateTimer(1.0, RespawnBot, client, TIMER_REPEAT);
	return Plugin_Continue;
}

public bool:IsClientReady(client)
{
	if (TF2_IsPlayerInCondition(client, TFCond_Cloaked)) { return false; }
	if (TF2_IsPlayerInCondition(client, TFCond_Dazed)) { return false; }
	if (TF2_IsPlayerInCondition(client, TFCond_Taunting)) { return false; }
	if (TF2_IsPlayerInCondition(client, TFCond_Bonked)) { return false; }
	if (TF2_IsPlayerInCondition(client, TFCond_RestrictToMelee)) { return false; }
	if (TF2_IsPlayerInCondition(client, TFCond_MeleeOnly)) { return false; }
	if (TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode)) { return false; }
	if (TF2_IsPlayerInCondition(client, TFCond_HalloweenKart)) { return false; }

	return true;
}

GetPlayerHealth(entity, bool:maxHealth=false)
{
	if (maxHealth)
	{
		if (strcmp(modName, "tf") == 0)
			return GetEntData(entity, FindDataMapOffs(entity, "m_iMaxHealth"));
		else
			return 100;
	}
	return GetEntData(entity, FindDataMapOffs(entity, "m_iHealth"));
}
