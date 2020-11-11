#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2attributes>
#include <tf2_stocks>
#include <tf2items>
#include <smlib>

#define MAX_PLAYERS_ARRAY 36
#define MAX_PLAYERS (MAX_PLAYERS_ARRAY < (MaxClients + 1) ? MAX_PLAYERS_ARRAY : (MaxClients + 1))

bool CanKill[MAXPLAYERS+1] = false;
bool IsClosest[MAXPLAYERS+1] = false;
bool ChancedHit[MAXPLAYERS+1] = false;
bool IgnoreWalls[MAXPLAYERS+1] = false;
bool HeadshotOnly[MAXPLAYERS+1] = false;
bool IgnoreClient[MAXPLAYERS+1] = false;
bool RageStab[MAXPLAYERS+1] = false;
bool CanBackstab[MAXPLAYERS+1] = false;
bool RadarEnabled[MAXPLAYERS+1] = false;
bool ProjPrediction[MAXPLAYERS+1] = false;
float closestdist[MAXPLAYERS+1] = 0.0;
int ProjectileType[MAXPLAYERS+1] = 0;
bool CanLead[MAXPLAYERS+1] = false;
float LeadDelay[2048] = 99999.0;
//int Self[MAXPLAYERS+1];
int ClosestPlayer[MAXPLAYERS+1];
float NearestPlayer = 9999.0;

new Sprite;

Handle radarhud;

public Plugin:myinfo =
{
	name = "HVH Config",
	author = "IvoryPal",
	description = "Yes",
	version = "1.0",
	url = ""
}

public void OnPluginStart()
{
	RegAdminCmd("sm_hvhking", CommandCheckKill, ADMFLAG_ROOT);
	RegAdminCmd("sm_ignoreclient", CommandIgnore, ADMFLAG_ROOT);
	//RegAdminCmd("sm_togglechance", CommandCheckChance, ADMFLAG_ROOT);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	Sprite = PrecacheModel("materials/sprites/blueglow2.vmt");

	radarhud = CreateHudSynchronizer();

	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (IsValidClient(clientIdx))
		{
			//SDKHook(clientIdx, SDKHook_GetMaxHealth, OnGetMaxHealth);  //Temporary:  Used to prevent boss overheal
			SDKHook(clientIdx, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public void OnMapStart()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		CanKill[i] = false;
		ChancedHit[i] = false;
		IgnoreWalls[i] = false;
		IsClosest[i] = false;
		HeadshotOnly[i] = false;
		IgnoreClient[i] = false;
		ProjectileType[i] = 0;
		RageStab[i] = false;
		CanBackstab[i] = false;
		RadarEnabled[i] = false;
		closestdist[i] = 0.0;
		ProjPrediction[i] = false;
	}
}

public void OnClientPutInServer(int client)
{
	CanKill[client] = false;
	ChancedHit[client] = false;
	IgnoreWalls[client] = false;
	IsClosest[client] = false;
	HeadshotOnly[client] = false;
	IgnoreClient[client] = false;
	ProjectileType[client] = 0;
	RageStab[client] = false;
	CanBackstab[client] = false;
	RadarEnabled[client] = false;
	closestdist[client] = 0.0;
	ProjPrediction[client] = false;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action CommandCheckKill(int client, int args)
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
				Menu_Config(target);
			}
		}
	}
	else
	{
		if (IsPlayerAlive(client) && IsValidClient(client))
		{
			Menu_Config(client);
		}
	}
	return Plugin_Handled;
}

public Action CommandIgnore(int client, int args)
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

			if (IsPlayerAlive(target) && IsValidClient(target) && target != client)
			{
				ToggleIgnore(target, client);
			}
		}
	}
	else
	{
		if (IsPlayerAlive(client) && IsValidClient(client))
		{
			PrintToChat(client, "Specify a client name that is not yourself");
		}
	}
	return Plugin_Handled;
}

public void ToggleIgnore(int client, int initiator) //Allows ignoring specific clients
{
		char name[32];
		GetClientName(client, name, sizeof(name));
		if (IgnoreClient[client])
		{
			IgnoreClient[client] = false;
			PrintToChat(initiator, "Client %s will not be ignored", name);
		}
		else if (!IgnoreClient[client])
		{
			IgnoreClient[client] = true;
			PrintToChat(initiator, "Client %s will be ignored", name);
		}
}


public Action Menu_Config(int client)
{
	Menu hvh = new Menu(MenuHVH, MENU_ACTIONS_ALL);
	hvh.SetTitle("HVH King Settings");

	hvh.AddItem("#choice5", "Exit");

	if (CanKill[client])
		hvh.AddItem("#choice1", "Silent Aim: On");
	else
		hvh.AddItem("#choice1", "Silent Aim: Off");

	if (ChancedHit[client])
		hvh.AddItem("#choice2", "Inaccuracy: On");
	else
		hvh.AddItem("#choice2", "Inaccuracy: Off");

	if (IgnoreWalls[client])
		hvh.AddItem("#choice3", "Ignore Walls: On");
	else
		hvh.AddItem("#choice3", "Ignore Walls: Off");

	if (HeadshotOnly[client])
		hvh.AddItem("#choice4", "Force Headshots: On");
	else
		hvh.AddItem("#choice4", "Force Headshots: Off");

	if (RadarEnabled[client])
		hvh.AddItem("radar", "Class Radar: On");
	else
		hvh.AddItem("radar", "Class Radar: Off");

	if (RageStab[client])
		hvh.AddItem("stab", "Auto Backstab: On");
	else
		hvh.AddItem("stab", "Auto Backstab: Off");

	hvh.AddItem("rocket", "Projectile Config");

	hvh.ExitButton = false;
	hvh.Display(client, 60);

	return Plugin_Handled;
}

public int MenuHVH(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if (StrEqual(info, "#choice1"))
			{
				ToggleBot(param1);
				Menu_Config(param1);
			}
			if (StrEqual(info, "#choice2"))
			{
				ToggleChance(param1);
				Menu_Config(param1);
			}
			if (StrEqual(info, "#choice3"))
			{
				ToggleWalls(param1);
				Menu_Config(param1);
			}
			if (StrEqual(info, "#choice4"))
			{
				ToggleHS(param1);
				Menu_Config(param1);
			}
			if (StrEqual(info, "stab"))
			{
				ToggleStab(param1);
				Menu_Config(param1);
			}
			if (StrEqual(info, "radar"))
			{
				ToggleRadar(param1);
				Menu_Config(param1);
			}
			if (StrEqual(info, "rocket"))
			{
					Menu_Homing(param1);
			}
			if (StrEqual(info, "#choice5"))
			{
				return 0;
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

/*
------------------------------------------------------------------
The homing projectiles have multiple settings                    -
Visible - Tracks the nearest target visible to the player        -
Projectile - Tracks the closest target visible to the projectile -
Aim - Projectliles track the player's aim                        -
------------------------------------------------------------------
*/

public Action Menu_Homing(int client)
{
	Menu hvh = new Menu(MenuProjectiles, MENU_ACTIONS_ALL);
	hvh.SetTitle("Projectile Configuration");

	switch (ProjectileType[client])
	{
		case 0: hvh.AddItem("home", "Homing Behavior: Disabled");
		case 1: hvh.AddItem("home", "Homing Behavior: Visible");
		case 2: hvh.AddItem("home", "Homing Behavior: Projectile");
		case 3: hvh.AddItem("home", "Homing Behavior: Aim");
	}
	if (ProjPrediction[client])
		hvh.AddItem("lead", "Projectile Prediction: On");
	else
		hvh.AddItem("lead", "Projectile Prediction: Off");

	hvh.AddItem("exit", "Back");
	hvh.ExitButton = false;
	hvh.Display(client, 60);

	return Plugin_Handled;
}

public int MenuProjectiles(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if (StrEqual(info, "home"))
			{
				ToggleHR(param1);
				Menu_Homing(param1);
			}
			if (StrEqual(info, "lead"))
			{
				ToggleProjPred(param1);
				Menu_Homing(param1);
			}
			if (StrEqual(info, "exit"))
			{
				Menu_Config(param1);
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

public void ToggleHR(int client)
{
	switch (ProjectileType[client])
	{
		case 0:
		{
			ProjectileType[client] = 1;
			PrintToChat(client, "Projectiles will target the nearest visible player");
		}
		case 1:
		{
			ProjectileType[client] = 2;
			PrintToChat(client, "Projectiles will seek the nearest player, regardless of visibility");
		}
		case 2:
		{
			ProjectileType[client] = 3;
			PrintToChat(client, "Projectiles will target your view angle");
		}
		case 3:
		{
			ProjectileType[client] = 0;
			PrintToChat(client, "Homing Projectiles Disabled");
		}
	}
}

public void ToggleProjPred(int client)
{
	if (ProjPrediction[client])
	{
		PrintToChat(client, "Disabled Projectile Prediction");
		ProjPrediction[client] = false;
	}
	else if (!ProjPrediction[client])
	{
		PrintToChat(client, "Enabled Projectile Prediction");
		ProjPrediction[client] = true;
	}
}

public void OnEntityCreated(int proj, const char[] classname)
{
	if (StrContains(classname, "tf_projectile", false) != -1)
	{
		SDKHook(proj, SDKHook_SpawnPost, ProjectileSpawned);
	}
}

public void ProjectileSpawned(int entity)
{
	new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if (IsValidClient(owner) && ProjPrediction[owner])
	{
		PrintToChat(owner, "Projectile");
		CanLead[owner] = true;
		LeadDelay[entity] = GetEngineTime()+0.05;
	}
}


public void ToggleBot(int client)
{
	if (CanKill[client])
	{
		CanKill[client] = false;
		PrintToChat(client, "Silent Aim disabled.");
	}
	else if (!CanKill[client])
	{
		CanKill[client] = true;
		PrintToChat(client, "Silent Aim enabled.");
	}
}

public void ToggleRadar(int client)
{
	if (RadarEnabled[client])
	{
		RadarEnabled[client] = false;
		PrintToChat(client, "Radar disabled.");
	}
	else if (!RadarEnabled[client])
	{
		RadarEnabled[client] = true;
		PrintToChat(client, "Radar enabled.");
	}
}

public void ToggleStab(int client)
{
	if (RageStab[client])
	{
		RageStab[client] = false;
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		TF2Attrib_RemoveByName(weapon, "melee range multiplier"); //placeholder
		PrintToChat(client, "Rage Backstab disabled.");
	}
	else if (!RageStab[client])
	{
		RageStab[client] = true;
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		TF2Attrib_SetByName(weapon, "melee range multiplier", 15.1); //placeholder - will eventually store client posistions based on latency
		PrintToChat(client, "Rage Backstab enabled.");
	}
}

public void ToggleHS(int client)
{
	if (HeadshotOnly[client])
	{
		HeadshotOnly[client] = false;
		PrintToChat(client, "Headshots off.");
	}
	else if (!HeadshotOnly[client])
	{
		HeadshotOnly[client] = true;
		PrintToChat(client, "Headshots on.");
	}
}

public void ToggleChance(int client)
{
	if (ChancedHit[client])
	{
		ChancedHit[client] = false;
		PrintToChat(client, "Innacuracy Disabled.");
	}
	else if (!ChancedHit[client])
	{
		ChancedHit[client] = true;
		PrintToChat(client, "Inaccuracy enabled.");
	}
}

public void ToggleWalls(int client)
{
	if (IgnoreWalls[client])
	{
		IgnoreWalls[client] = false;
		PrintToChat(client, "Walls will not be ignored.");
	}
	else if (!IgnoreWalls[client])
	{
		IgnoreWalls[client] = true;
		PrintToChat(client, "Walls will be ignored.");
	}
}

public void OnGameFrame()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (RadarEnabled[i])
			{
				RadarTick(i);
			}
			//RadarTick(i);
			if (TF2_GetPlayerClass(i) == TFClass_Spy && IsWeaponSlotActive(i, 2) && RageStab[i])
			{
				CheckBackstab(i);
			}
		}
		if(ProjectileType[i] >= 1)
		{
			SetHomingProjectile(i, "tf_projectile_arrow");
			SetHomingProjectile(i, "tf_projectile_energy_ball");
			SetHomingProjectile(i, "tf_projectile_flare");
			SetHomingProjectile(i, "tf_projectile_healing_bolt");
			SetHomingProjectile(i, "tf_projectile_rocket");
			SetHomingProjectile(i, "tf_projectile_sentryrocket");
			SetHomingProjectile(i, "tf_projectile_syringe");
		}
		if (ProjPrediction[i])
		{
			TryPredictPosition(i, "tf_projectile_rocket");
			ShowPredictionLoc(i);
		}
	}
}

/*
-----------------------------------------------------
Radar is still a WiP                                -
Displays nearest player class, HP, and name         -
Provides distance to the nearest player             -
-----------------------------------------------------
*/

public void RadarTick(int client)
{
	float playerpos[3], enemypos[3];
	GetClientAbsOrigin(client, playerpos);

	for (new playerid = 1; playerid <= MaxClients; playerid++)
	{
		if (IsValidClient(playerid) && GetClientTeam(playerid) != GetClientTeam(client) && IsClientInGame(playerid))
		{
			GetClientAbsOrigin(playerid, enemypos);
			float distance = GetVectorDistance(playerpos, enemypos);
			if (distance <= closestdist[client] || closestdist[client] == 0.0)
			{
				closestdist[client] = distance;
				ClosestPlayerInfo(client, distance, playerid);
			}
		}
	}
}

public void ClosestPlayerInfo(int client, float distance, int target)
{
	SetHudTextParams(0.1, 0.2, 0.02, 0, 20, 255, 255);
	TFClassType class = TF2_GetPlayerClass(target);
	char classname[64];
	char name[32];
	GetClientName(target, name, sizeof(name));

	switch (class)
	{
		case TFClass_Scout: classname = "Scout";
		case TFClass_Soldier: classname = "Soldier";
		case TFClass_Pyro: classname = "Pyro";
		case TFClass_DemoMan: classname = "Demoman";
		case TFClass_Heavy: classname = "Heavy";
		case TFClass_Engineer: classname = "Engineer";
		case TFClass_Sniper: classname = "Sniper";
		case TFClass_Medic: classname = "Medic";
		case TFClass_Spy: classname = "Spy";
		default: classname = "N/A";
	}

	ShowSyncHudText(client, radarhud, "Closest Player: %s\nDistance: %.1f\nClass: %s", name, distance, classname);
}

public void ShowPredictionLoc(int client)
{
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	switch (weapon)
	{
		//preserved
	}
}

public void TryPredictPosition(int client, const char[] classname)
{
	int entity = -1;
	int Target = -1;
	while((entity = FindEntityByClassname(entity, classname))!=INVALID_ENT_REFERENCE)
	{
		int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(!IsValidEntity(owner)) continue;
		Target = SelectBestTarget(client);
		if(!Target || !IsValidClient(Target)) continue;
		if(owner == client && Target != client)
		{
			if (!CanLead[client] || !ProjPrediction[client])
				return;

			float ProjLocation[3], ProjVector[3], ProjSpeed, ProjAngle[3], TargetLocation[3], AimVector[3], vAngles[3], flDistance, flAngleFactor, TargetVelocity[3];
			if (Target == owner) return;
			PrintToChat(owner, "Target: %i", Target);
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", ProjLocation);
			GetClientAbsOrigin(Target, TargetLocation);
			GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", ProjVector);
			GetEntPropVector(Target, Prop_Data, "m_vecAbsVelocity", TargetVelocity);
			ProjSpeed = GetVectorLength(ProjVector);
			flDistance = GetVectorDistance(ProjLocation, TargetLocation);
			flAngleFactor = flDistance / ProjSpeed;
			for (new axis = 0; axis < 3; axis++)
			{
					TargetLocation[axis]+= TargetVelocity[axis]*flAngleFactor;
			}
			TE_SetupGlowSprite(TargetLocation, Sprite, 0.02, 2.0, 60);
			TE_SendToClient(owner);
			PrintToChat(owner, "Distance: %.1f\nVelocity: %.1f\nAngleFactor: %.1f", flDistance, ProjSpeed, flAngleFactor);

			MakeVectorFromPoints(ProjLocation, TargetLocation , AimVector);
			//AddVectors(ProjVector, AimVector, ProjVector);
			NormalizeVector(AimVector, AimVector);
			GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
			GetVectorAngles(AimVector, ProjAngle);
			SetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
			GetClientEyeAngles(owner, vAngles);
			ScaleVector(AimVector, ProjSpeed);
			SetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", AimVector);
			TeleportEntity(entity, NULL_VECTOR, ProjAngle, AimVector);
			if (LeadDelay[entity] <= GetEngineTime())
				CanLead[client] = false;
		}
	}
}

public void SetHomingProjectile(int client, char[] classname)
{
	int entity = -1;
	int Target = -1;
	float targetpos3[3], playerpos[3];
	while((entity = FindEntityByClassname(entity, classname))!=INVALID_ENT_REFERENCE)
	{
		int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(!IsValidEntity(owner)) continue;
		if(StrEqual(classname, "tf_projectile_sentryrocket", false)) owner = GetEntPropEnt(owner, Prop_Send, "m_hBuilder");
		switch (ProjectileType[client])
		{
				case 1: Target = SelectBestTarget(client);
				case 2: Target = GetClosestTarget(entity, owner);
				case 3:
				{
					float vAngles[3], vPos[3];
					Target = client;

					GetClientEyePosition(client,vPos);
					GetClientEyeAngles(client, vAngles);

					Handle trace = TR_TraceRayFilterEx(vPos, vAngles, MASK_PLAYERSOLID, RayType_Infinite, FilterAim, client);

					if(TR_DidHit(trace))
					{
						TR_GetEndPosition(targetpos3, trace);
						GetClientAbsOrigin(client, playerpos);
						float distancefl = GetVectorDistance(playerpos, targetpos3);
						PrintToChat(client, "Distance: %.1f", distancefl);
					}
					CloseHandle(trace);
				}
		}
		if(!Target || !IsValidClient(Target)) continue;
		if(owner == client && Target != client && ProjectileType[client] != 3)
		{
			float ProjLocation[3], ProjVector[3], ProjSpeed, ProjAngle[3], TargetLocation[3], AimVector[3];
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", ProjLocation);
			GetClientAbsOrigin(Target, TargetLocation);
			TargetLocation[2] += 60.0;
			MakeVectorFromPoints(ProjLocation, TargetLocation , AimVector);
			GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", ProjVector);
			ProjSpeed = GetVectorLength(ProjVector);
			AddVectors(ProjVector, AimVector, ProjVector);
			NormalizeVector(ProjVector, ProjVector);
			GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
			GetVectorAngles(ProjVector, ProjAngle);
			SetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
			ScaleVector(ProjVector, ProjSpeed);
			SetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", ProjVector);
		}
		else if (owner == client && ProjectileType[client] == 3)
		{
			float ProjLocation[3], ProjVector[3], ProjSpeed, ProjAngle[3], TargetLocation[3], AimVector[3];
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", ProjLocation);
			TargetLocation = targetpos3;
			TargetLocation[2] += 60.0;
			MakeVectorFromPoints(ProjLocation, TargetLocation , AimVector);
			GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", ProjVector);
			ProjSpeed = GetVectorLength(ProjVector);
			AddVectors(ProjVector, AimVector, ProjVector);
			NormalizeVector(ProjVector, ProjVector);
			GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
			GetVectorAngles(ProjVector, ProjAngle);
			SetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
			ScaleVector(ProjVector, ProjSpeed);
			SetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", ProjVector);
		}
	}
}

public bool FilterAim(int entity, int contentsMask, int client)
{
	//return entity > MAX_PLAYERS || !entity;
	if (entity == client)
	{
			return false;
	}
	return true;
}

/*
-----------------------------------------------------------------------------
Settings for silent aim														-
The player's view angles are NOT changed at all in this setup				-
Instead, a line trace is created between the player and the nearest target	-
This is completely undetectable from spectators								-
Walls will block these line traces unless 'Ignore Walls' is disabled		-
-----------------------------------------------------------------------------
*/

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool& result)
{
	if (CanKill[client])
	{
		//Self[client] = client;
		int target = SelectBestTarget(client);
		if (target == client)
				return Plugin_Continue;

		//PrintToChat(client, "TargetID: %i", target);

		bool IsPrimary = false;

		if (IsWeaponSlotActive(client, 0) && TF2_GetPlayerClass(client) == TFClass_Sniper)
		{
			float charge2 = GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage"); //Normally the damage dealt will not scale based on a sniper's charge, this fixes that
			float damagemod;
			if (charge2 <= 50.0)
			{
				damagemod = 50.0; // 50 base damage
			}
			else if (50.0 < charge2 <= 150.0)
			{
				damagemod = charge2; //base damage set to charge scale
			}
			if (ChancedHit[client]) // handles whether the aimbot is fully accurate or has a chance to miss
			{
				int hitchance = GetRandomInt(1, 10);
				if (hitchance <= 9)
				{
					int critchance = GetRandomInt(1, 10);
					if (critchance <= 6)
					{
						TraceAttack(client, target, damagemod*1.1, true); //headshot
					}
					else
					{
						TraceAttack(client, target, damagemod, false); //no headshot
					}
				}
			}
			if (!ChancedHit[client] && !IgnoreWalls[client])
			{
				TraceAttack(client, target, damagemod*1.1, true);
			}
			else if (IgnoreWalls[client] && !ChancedHit[client])
			{
				IsClosest[target] = true;
				SDKHooks_TakeDamage(target, client, client, damagemod*1.1, DMG_CRIT);
			}
		}
		else if (IsWeaponSlotActive(client, 1) && TF2_GetPlayerClass(client) == TFClass_Sniper)
		{
			if (!ChancedHit[client] && IgnoreWalls[client])
			{
				SDKHooks_TakeDamage(target, client, client, 8.0, DMG_CRIT);
			}
			else if (!IgnoreWalls[client] && !ChancedHit[client])
			{
				TraceAttack(target, client, 8.0, true);
			}
		}
		if (TF2_GetPlayerClass(client) == TFClass_Heavy)
		{
				if (IsWeaponSlotActive(client, 0))
				{
						if (ChancedHit[client] && !IgnoreWalls[client])
						{
								int hitchance = GetRandomInt(1, 20);
								if (hitchance <= 15)
								{
										int critchance2 = GetRandomInt(1, 20);
										if (critchance2 <= 5)
										{
												TraceAttack(client, target, 9.0, true);
										}
										else
										{
												TraceAttack(client, target, 9.0, false);
										}
								}
						}
						if (ChancedHit[client] && IgnoreWalls[client])
						{
								SDKHooks_TakeDamage(target, client, client, 9.0, DMG_GENERIC);
						}
						if (IgnoreWalls[client] && !ChancedHit[client])
						{
								SDKHooks_TakeDamage(target, client, client, 9.0, DMG_GENERIC);
						}
						if (!IgnoreWalls[client] && !ChancedHit[client])
						{
								TraceAttack(client, target, 9.0, false);
						}
				}
		}
	}
	return Plugin_Continue;
}

/*
	Filter for backstab trace
*/

public bool StabFilter(int ent, int content, int client)
{
	if(ent <= 0 || ent >= 24 || ent == client)
	{
		return false;
	}
	return true;
}

/*
	Line trace for backstabs
*/


public void CheckBackstab(int client)
{
	float startingpos[3], vEyeAngles[3], targetpos[3];
	int ReadyOffset = FindSendPropOffs("CTFKnife", "m_bReadyToBackstab");
	int Knife = GetPlayerWeaponSlot(client, 2);
	GetClientEyePosition(client, startingpos);
	GetClientEyeAngles(client, vEyeAngles);

	Handle tracebs = TR_TraceRayFilterEx(startingpos, vEyeAngles, MASK_PLAYERSOLID, RayType_Infinite, StabFilter, client);
	if (TR_DidHit(tracebs))
	{
		int target = TR_GetEntityIndex(tracebs);
		if (IsValidClient(target))
		{
			GetClientAbsOrigin(target, targetpos);
			float distance = GetVectorDistance(startingpos, targetpos);
			if (distance <= 800.0)
			{
				SetEntData(Knife, ReadyOffset, 1);
				if (!CanBackstab[client])
						CanBackstab[client] = true;
				PrintToChat(client, "can backstab");
			}
			else if (distance > 200.0)
			{
					SetEntData(Knife, ReadyOffset, 0);
					if (CanBackstab[client])
							CanBackstab[client] = false;
			}
		}
		CloseHandle(tracebs);
	}
}

/*
	Create a line trace between target and attacker, check if target is visible
*/


public void TraceAttack(int attacker, int victim, float damage, bool crit)
{
	float startingpos[3], targetpos[3];
	GetClientEyePosition(attacker, startingpos);
	GetClientEyePosition(victim, targetpos);
	//PrintToChat(attacker, "tracing for target");

	Handle trace = TR_TraceRayFilterEx(startingpos, targetpos, MASK_PLAYERSOLID, RayType_EndPoint, WorldFilter, attacker);
	if (TR_DidHit(trace))
	{
		int ent = TR_GetEntityIndex(trace);
		if(IsValidClient(ent) && ent == victim) //If target is visible and trace result is the target
		{
			if (crit)
			{
				IsClosest[victim] = true;
				SDKHooks_TakeDamage(victim, attacker, attacker, damage, DMG_CRIT);
			}
			else
			{
				SDKHooks_TakeDamage(victim, attacker, attacker, damage, DMG_GENERIC);
			}
			//PrintToChat(attacker, "target is trace result");
		}
		else if (ent == 0)
		{
			CloseHandle(trace);
		}
		else
		{
			CloseHandle(trace);
		}
		CloseHandle(trace);
	}
}
public bool CheckEntTrace(int entity, int owner, int victim)
{
		float entpos[3], targetpos[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", entpos);
		GetClientAbsOrigin(victim, targetpos);

		Handle tracecheck = TR_TraceRayFilterEx(entpos, targetpos, MASK_PLAYERSOLID, RayType_EndPoint, EntFilter, entity);
		if (TR_DidHit(tracecheck))
		{
				int ent = TR_GetEntityIndex(tracecheck);
				if(IsValidClient(ent) && ent == victim) //If target is visible and trace result is the target
				{
						CloseHandle(tracecheck);
						return true;
				}
				else
				{
						CloseHandle(tracecheck);
						return false;
				}
		}
		CloseHandle(tracecheck);
		return true;
}

public bool EntFilter(int ent, int content, int rocket)
{
	if(ent == rocket || ent == 0)
	{
		return false;
	}
	return true;
}

public bool CheckTrace(attacker, victim)
{
		//PrintToChat(attacker, "tracing for target.");
		float startingpos[3], targetpos[3];
		GetClientEyePosition(attacker, startingpos);

		GetClientEyePosition(victim, targetpos);
		new Handle:tracecheck = TR_TraceRayFilterEx(startingpos, targetpos, MASK_PLAYERSOLID, RayType_EndPoint, WorldFilter, attacker);
		if (TR_DidHit(tracecheck))
		{
				int ent = TR_GetEntityIndex(tracecheck);
				if(IsValidClient(ent) && ent == victim) //If target is visible and trace result is the target
				{
						CloseHandle(tracecheck);
						return true;
				}
				else
				{
						CloseHandle(tracecheck);
						return false;
				}
		}
		CloseHandle(tracecheck);
		return true;
}

public Action Event_PlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new inflictor = GetEventInt(event, "inflictor_entindex");

	if (CanKill[attacker] && IsClosest[client]) //Forces headshot
	{
		SetEventInt(event, "customkill", 1);
		IsClosest[client] = false;
		return Plugin_Changed;
	}

	if (CanBackstab[attacker])
	{
			SetEventInt(event, "customkill", TF_CUSTOM_BACKSTAB); //Forces the kill to be a backstab
			return Plugin_Changed;
	}
	if (HeadshotOnly[attacker])
	{
			SetEventInt(event, "customkill", 1); //Forces kill to be a headshot for bots
			if (IsFakeClient(attacker))
				HeadshotOnly[attacker] = false;
			return Plugin_Changed;
	}
	return Plugin_Continue;
}

public bool WorldFilter(int ent, int content, int client)
{
	if(ent == client)
	{
		return false;
	}
	return true;
}

public Action OnTakeDamage(int client, &int attacker, &int inflictor, &float damage, &damagetype, &int weapon, float damageForce[3], float damagePosition[3], damagecustom)
{
		if (!IsValidClient(client))
				return Plugin_Continue;
		if (!IsValidClient(attacker))
				return Plugin_Continue;

		if (IsFakeClient(attacker)) //Settings for bots
		{
				if (TF2_GetPlayerClass(attacker) == TFClass_Sniper && IsWeaponSlotActive(attacker, 0))
				{
						if (damagecustom != TF_CUSTOM_HEADSHOT)
						{
							damagetype = DMG_CRIT;
							HeadshotOnly[attacker] = true;
						}
						return Plugin_Changed;
				}
		}

		if (CanBackstab[attacker]) //Sets all damage to deal backstab damage
		{
				damagetype = DMG_CRIT;
				damage = (float(GetClientHealth(client))*6.0)/3.0;
				//CanBackstab[attacker] = false;
				return Plugin_Changed;
		}
		if (HeadshotOnly[attacker]) //sets all damage to deal crit damage
		{
				if (TF2_GetPlayerClass(attacker) == TFClass_Sniper)
				{
					damagetype = DMG_CRIT;
				}
				return Plugin_Changed;
		}
		return Plugin_Continue;
}

public bool IsValidClient(int iClient)
{
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
	{
		return false;
	}
	if (IsClientSourceTV(iClient) || IsClientReplay(iClient))
	{
		return false;
	}
	return true;
}

public int SelectBestTarget(int client) //Closest Target to client
{
		float flMyPos[3];
		flMyPos = GetEyePosition(client);
		int target = INVALID_ENT_REFERENCE;

		float flTargetPos[3];
		float flClosestDistance = 8192.0;
		float vVisiblePos[3];

		for (int i = 1; i <= MaxClients; i++)
		{
				if (i == client)
					continue;

				if (!IsClientInGame(i))
					continue;

				if (!IsKilllablePlayer(client, i))
					continue;

				if (IgnoreClient[i])
					continue;

				vVisiblePos = GetEyePosition(i);

				float flDistance = GetVectorDistance(flMyPos, vVisiblePos);
				if (flDistance < flClosestDistance)
				{
						if (!IgnoreWalls[client] && CheckTrace(client, i))
						{
								//PrintToChat(client, "target is visible");
								flClosestDistance = flDistance;
								flTargetPos = vVisiblePos;
								target = i;
						}
						else if (!IgnoreWalls[client] && !CheckTrace(client, i))
						{
								//PrintToChat(client, "target is not visible, checking next target...");
						}
						else if (IgnoreWalls[client])
						{
								flClosestDistance = flDistance;
								flTargetPos = vVisiblePos;
								target = i;
						}
				}
		}
		if (IsValidClient(target))
				return target;
		else
				return client;
}

public void GetClosestTarget(int entity, int owner) //Closest Target to entity
{
	float TargetDistance = 0.0;
	int ClosestTarget = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i) || !IsPlayerAlive(i) || i == owner || (GetClientTeam(owner) == GetClientTeam(i))) continue;
		float EntityLocation[3], TargetLocation[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", EntityLocation);
		GetClientAbsOrigin(i, TargetLocation);

		float distance = GetVectorDistance(EntityLocation, TargetLocation);
		if (CheckEntTrace(entity, owner, i))
		{
			if(TargetDistance)
			{
				if(distance < TargetDistance)
				{
					ClosestTarget = i;
					TargetDistance = distance;
				}
			}
			else
			{
				ClosestTarget = i;
				TargetDistance = distance;
			}
		}
	}
	if (IsValidClient(ClosestTarget))
			return ClosestTarget;
	else
			return owner;
}

stock bool IsKilllablePlayer(int client, int target)
{
	if (!IsPlayerAlive(target))
		return false;

	if (GetEntProp(target, Prop_Send, "m_lifeState") != 0)
		return false;

	if (GetClientTeam(target) != GetEnemyTeam(client))
		return false;


	if (TF2_IsPlayerInCondition(target, TFCond_Ubercharged) || TF2_IsPlayerInCondition(target, TFCond_UberchargedHidden)
		 || TF2_IsPlayerInCondition(target, TFCond_UberchargedCanteen) || TF2_IsPlayerInCondition(target, TFCond_Bonked)) {
		return false;
	}

	if (GetEntProp(target, Prop_Data, "m_takedamage") != 2)
		return false;

	return true;
}


stock bool IsWeaponSlotActive(int iClient, int iSlot)
{
return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

stock float[] GetEyePosition(int client)
{
	float v[3];
	GetClientEyePosition(client, v);
	return v;
}

stock int GetEnemyTeam(int ent)
{
	int enemy_team = GetClientTeam(ent);
	switch (enemy_team)
	{
		case 2: enemy_team = 3;
		case 3: enemy_team = 2;
	}
	return enemy_team;
}

stock int GetWeaponIndex(int iWeapon)
{
    return IsValidEnt(iWeapon) ? GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"):-1;
}

stock int GetIndexOfWeaponSlot(int iClient, int iSlot)
{
    return GetWeaponIndex(GetPlayerWeaponSlot(iClient, iSlot));
}

stock bool IsValidEnt(int iEnt)
{
    return iEnt > MaxClients && IsValidEntity(iEnt);
}
