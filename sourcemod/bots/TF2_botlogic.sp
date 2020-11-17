#include <sourcemod>
#include <sdktools>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION  "1.0"
#define FAR_FUTURE 999999.0

float JumpTimer[MAXPLAYERS+1] = FAR_FUTURE;
float DoubleJumpTimer[MAXPLAYERS+1] = FAR_FUTURE;
new bool:Jump[MAXPLAYERS+1];
new bool:Headshot[MAXPLAYERS+1] = false;
int JumpDelayCount[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "TFBot Enhanced Logic",
	author = "IvoryPal",
	description = "Custom Jump Logic for TFBots.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/groups/VersusPonyvilleReborn"
}

public OnPluginStart()
{
	HookEvent("teamplay_round_start", RoundStarted);
	HookEvent("player_death", PlayerDeath, EventHookMode_Post);
	RegAdminCmd("sm_botjump", RocketJump, ADMFLAG_ROOT);
	/*
	for (new i = 1; i <= MaxClients; i++)
	{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	*/
}

/*
public OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
*/

public Action:RocketJump(int client, int args)
{
		for (new bot = 1; bot <= MaxClients; bot++)
		{
				if (IsFakeClient(bot) && IsValidClient(bot) && TF2_GetPlayerClass(bot) == TFClass_Soldier)
				{
						JumpTimer[bot] = GetEngineTime()+0.1;
				}
		}
}

/*
public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
		if (!IsValidClient(client))
				return Plugin_Continue;
		if (!IsValidClient(attacker))
				return Plugin_Continue;

		if (TF2_GetPlayerClass(attacker) == TFClass_Sniper && Headshot[attacker])
		{
				{
						damagetype = TF_CUSTOM_HEADSHOT;
						//Headshot[attacker] = false;
				}
				return Plugin_Changed;
		}
		return Plugin_Continue;
}
*/

public Action PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new inflictor = GetEventInt(event, "inflictor_entindex");

	if (Headshot[attacker])
	{
			SetEventInt(event, "customkill", 1);
			Headshot[attacker] = false;
			return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock float moveForward(float vel[3], float MaxSpeed)
{
	vel[0] = MaxSpeed;
	return vel;
}

public Action RoundStarted(Handle event, const char[] name, bool dontBroadcast)
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));

	if(StrContains(currentMap, "ctf_2fort" , false) != -1)
	{
		new snipepos = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos, "team", "2");
		new snipepos2 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos2, "team", "2");
		new snipepos3 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos3, "team", "2");

		float origin[3] = {233.0, 1020.0, 294.0};
		float origin2[3] = {-234.0, 1028.0, 294.0};
		float origin3[3] = {23.0, 881.0, 0.0};

		TeleportEntity(snipepos, origin, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos2, origin2, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos3, origin3, NULL_VECTOR, NULL_VECTOR);

		new snipepos4 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos4, "team", "3");
		new snipepos5 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos5, "team", "3");
		new snipepos6 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos6, "team", "3");

		float origin4[3] = {-224.0, -1042.0, 306.0};
		float origin5[3] = {229.0, -1029.0, 305.0};
		float origin6[3] = {-27.0, -876.0, 298.0};

		TeleportEntity(snipepos4, origin4, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos5, origin5, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos6, origin6, NULL_VECTOR, NULL_VECTOR);
	}
	if(StrContains(currentMap, "tc_hydro" , false) != -1)
	{
		new snipepos = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos, "team", "0");
		new snipepos2 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos2, "team", "0");
		new snipepos3 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos3, "team", "0");
		new snipepos4 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos4, "team", "0");
		new snipepos5 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos5, "team", "0");
		new snipepos6 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos6, "team", "0");

		float origin[3] = {1605.0, 2383.0, 523.0};
		float origin2[3] = {2368.0, 1363.0, 523.0};
		float origin3[3] = {2375.0, 2633.0, 523.0};
		float origin4[3] = {2267.0, -1278.0, 363.0};
		float origin5[3] = {-2136.0, 858.0, 476.0};
		float origin6[3] = {-2133.0, 1427.0, 468.0};

		TeleportEntity(snipepos, origin, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos2, origin2, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos3, origin3, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos4, origin4, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos5, origin5, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos6, origin6, NULL_VECTOR, NULL_VECTOR);
	}
	if(StrContains(currentMap, "koth_harvest_final" , false) != -1)
	{
		new snipepos = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos, "team", "2");
		new snipepos2 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos2, "team", "2");
		new snipepos3 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos3, "team", "2");
		new snipepos10 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos10, "team", "2");
		new snipepos11 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos11, "team", "2");
		new snipepos12 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos12, "team", "2");

		float origin[3] = {922.0, -1043.0, 366.0};
		float origin2[3] = {-1424.0, -395.0, 331.0};
		float origin3[3] = {-930.0, -414.0, 331.0};
		float origin10[3] = {-743.0, -1093.0, 448.0};
		float origin11[3] = {-242.0, -1090.0, 45.0};
		float origin12[3] = {1262.0, 387.0, 300.0};

		TeleportEntity(snipepos, origin, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos2, origin2, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos3, origin3, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos10, origin10, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos11, origin11, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos12, origin12, NULL_VECTOR, NULL_VECTOR);

		new snipepos4 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos4, "team", "3");
		new snipepos5 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos5, "team", "3");
		new snipepos6 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos6, "team", "3");
		new snipepos7 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos7, "team", "3");
		new snipepos8 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos8, "team", "3");
		new snipepos9 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos9, "team", "3");

		float origin4[3] = {-892.0, 1032.0, 367.0};
		float origin5[3] = {1344.0, 296.0, 331.0};
		float origin6[3] = {198.0, 1085.0, 454.0};
		float origin7[3] = {744.0, 1093.0, 449.0};
		float origin8[3] = {892.0, 397.0, 331.0};
		float origin9[3] = {-1295.0, -392.0, 300.0};

		TeleportEntity(snipepos4, origin4, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos5, origin5, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos6, origin6, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos7, origin7, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos8, origin8, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos9, origin9, NULL_VECTOR, NULL_VECTOR);
	}
	if(StrContains(currentMap, "pl_badwater" , false) != -1)
	{
		new snipepos = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos, "team", "3");
		new snipepos2 = CreateEntityByName("func_tfbot_hint");
		DispatchKeyValue(snipepos2, "team", "3");
		new sentrypos = CreateEntityByName("bot_hint_sentrygun");
		DispatchKeyValue(sentrypos, "team", "3");
		new engipos = CreateEntityByName("bot_hint_engineer_nest");
		DispatchKeyValue(engipos, "team", "3");

		float origin[3] = {-183.0, 1921.0, 452.0};
		float origin2[3] = {522.0, 2025.0, 193.0};
		float origin3[3] = {-650.0, 992.0, 232.0};

		TeleportEntity(snipepos, origin, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(snipepos2, origin3, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(sentrypos, origin2, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(engipos, origin2, NULL_VECTOR, NULL_VECTOR);
	}
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool& result)
{
		if (IsFakeClient(client) && TF2_GetPlayerClass(client) == TFClass_Soldier)
		{
				JumpDelayCount[client]--;
				int jumpchance = GetRandomInt(1, 10);
				int rocketjump = GetRandomInt(1, 10);
				if (rocketjump <= 5 && JumpDelayCount[client] <= 0)
				{
						JumpTimer[client] = GetEngineTime()+0.8;
						JumpDelayCount[client] = 3;
				}
				else if (jumpchance <= 8)
				{
						Jump[client] = true;
				}
		}
		else if (IsFakeClient(client) && TF2_GetPlayerClass(client) == TFClass_Scout)
		{
				JumpDelayCount[client]--;
				int jumpchance = GetRandomInt(1, 10);
				if (jumpchance <= 4 && JumpDelayCount[client] <= 0)
				{
						JumpTimer[client] = GetEngineTime()+0.1;
						JumpDelayCount[client] = 2;
				}
		}
		else if (IsFakeClient(client) && TF2_GetPlayerClass(client) == TFClass_Sniper)
		{
				if (IsWeaponSlotActive(client, 0))
				{
						int critchance = GetRandomInt(1, 10);
						if (critchance <= 8)
						{
								Headshot[client] = true;
						}
						else
						{
								Headshot[client] = false;
						}
				}
				else if (Headshot[client])
				{
						Headshot[client] = false;
				}
		}
}

/*
bool:Obstructed(int client)
{
		float startpos[3];
		float traceangle[3] = {-89.0, 0.0, 0.0};
		GetClientEyePosition(client, startpos);
		Handle trace;
		trace = TR_TraceRayFilterEx(startpos, traceangle, MASK_PLAYERSOLID, RayType_Infinite, Filter);
		if(TR_DidHit(trace))
		{
				TR_GetEndPosition(traceangle, trace);
				new Float:wallDistance;
				wallDistance = GetVectorDistance(startpos, traceangle);
				if(wallDistance < 300.0)
				{
						return false;
				}
				else if (wallDistance >= 300.0)
				{
						return true;
				}
		}
		CloseHandle(trace);
		return true;
}
*/


public Action OnPlayerRunCmd(int client, &buttons, &impulse, float vel[3])
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				new TFClassType:class = TF2_GetPlayerClass(client);
				new team = GetClientTeam(client);
				char currentMap[PLATFORM_MAX_PATH];
				GetCurrentMap(currentMap, sizeof(currentMap));

				if (class == TFClass_Scout)
				{
						if (JumpTimer[client] <= GetEngineTime())
						{
								buttons |= IN_JUMP
								DoubleJumpTimer[client] = GetEngineTime()+0.28;
						}
						if (DoubleJumpTimer[client] <= GetEngineTime())
						{
								if (GetEntityFlags(client) & FL_ONGROUND)
								{
										DoubleJumpTimer[client] = FAR_FUTURE;
								}
								else
								{
										buttons |= IN_JUMP;
										JumpTimer[client] = FAR_FUTURE;
										DoubleJumpTimer[client] = FAR_FUTURE;
								}
						}
				}
				if(class == TFClass_Soldier)
				{
						if (JumpTimer[client] <= GetEngineTime())
						{
							vel = moveForward(vel,500.0);
							float newDirection[3];
							GetClientEyeAngles(client, newDirection);
							newDirection[0] = 60.0;
							newDirection[1] = 160.0;
							newDirection[2] = 0.0;
							TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
							buttons |= IN_JUMP;
							buttons |= IN_DUCK;
							buttons |= IN_ATTACK;
							vel = moveForward(vel,300.0);
							JumpTimer[client] = FAR_FUTURE;
						}
						if (Jump[client])
						{
								buttons |= IN_JUMP;
								Jump[client] = false;
						}
					if(StrContains(currentMap, "pl_upward" , false) != -1)
					{
						float clientOrigin[3];
						GetClientAbsOrigin(client, clientOrigin);
						if(team == 2)
						{
							float rocketjump1[3] = {-257.0, -761.0, 68.0};
							float rocketjump2[3] = {255.0, -788.0, 87.0};
							float rocketjumpfix1[3] = {-220.0, -882.0, 332.0};
							float rocketjumpfix2[3] = {229.0, -888.0, 332.0};
							float chainDistance1;
							chainDistance1 = GetVectorDistance(clientOrigin, rocketjump1);
							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, rocketjump2);
							float chainDistance3;
							chainDistance3 = GetVectorDistance(clientOrigin, rocketjumpfix1);
							float chainDistance4;
							chainDistance4 = GetVectorDistance(clientOrigin, rocketjumpfix2);
							if(IsWeaponSlotActive(client, 0) && GetHealth(client) > 100.0)
							{
								if(chainDistance1 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = -90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance2 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = -90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance3 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = -90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance4 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = -90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
							}
						}
						if(team == 3)
						{
							float rocketjump1[3] = {255.0, 741.0, 60.0};
							float rocketjump2[3] = {-252.0, 795.0, 90.0};
							float rocketjump3[3] = {-992.0, -1918.0, 144.0};
							float rocketjumpfix1[3] = {-226.0, 879.0, 300.0};
							float rocketjumpfix2[3] = {231.0, 897.0, 482.0};
							float rocketjumpfix3[3] = {-832.0, -1911.0, 324.0};
							float chainDistance1, chainDistance2, chainDistance3, chainDistance4, chainDeistance6;
							chainDistance1 = GetVectorDistance(clientOrigin,rocketjump1);
							chainDistance2 = GetVectorDistance(clientOrigin,rocketjump2);
							chainDistance5 = GetVectorDistance(clientOrigin,rocketjump3);
							chainDistance3 = GetVectorDistance(clientOrigin,rocketjumpfix1);
							chainDistance4 = GetVectorDistance(clientOrigin,rocketjumpfix2);
							chainDistance6 = GetVectorDistance(clientOrigin,rocketjumpfix3);
							if(IsWeaponSlotActive(client, 0) && GetHealth(client) > 100.0)
							{
								if(chainDistance1 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = 90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance2 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = 90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance5 < 100.0)
								{
									float newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = 179.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance3 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance4 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance6 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										float newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = -179.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
							}
						}
					}
					if(StrContains(currentMap, "pl_badwater" , false) != -1)
					{
						new Float:clientOrigin[3];
						GetClientAbsOrigin(client, clientOrigin);
						if(team == 3)
						{
							new Float:rocketjump1[3] = {2137.0, -1494.0, 196.0};
							new Float:rocketjump2[3] = {621.0, -771.0, 389.0};
							new Float:rocketjump3[3] = {-459.0, 994.0, -60.0};
							new Float:rocketjumpfix1[3] = {1943.0, -1473.0, 453.0};
							new Float:rocketjumpfix2[3] = {450.0, -707.0, 597.0};
							new Float:rocketjumpfix3[3] = {-650.0, 992.0, 232.0};
							new Float:chainDistance1;
							chainDistance1 = GetVectorDistance(clientOrigin,rocketjump1);
							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin,rocketjump2);
							new Float:chainDistance5;
							chainDistance5 = GetVectorDistance(clientOrigin,rocketjump3);
							new Float:chainDistance3;
							chainDistance3 = GetVectorDistance(clientOrigin,rocketjumpfix1);
							new Float:chainDistance4;
							chainDistance4 = GetVectorDistance(clientOrigin,rocketjumpfix2);
							new Float:chainDistance6;
							chainDistance6 = GetVectorDistance(clientOrigin,rocketjumpfix3);
							if(IsWeaponSlotActive(client, 0) && GetHealth(client) > 100)
							{
								if(chainDistance1 < 100.0)
								{
									new Float:newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = -179.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance2 < 100.0)
								{
									new Float:newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = 166.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance5 < 100.0)
								{
									new Float:newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = -179.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance3 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										new Float:newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 179.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance4 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										new Float:newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 166.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance6 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										new Float:newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 179.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
							}
						}
						if(team == 2)
						{
							new Float:rocketjump1[3] = {536.0, 1895.0, 196.0};
							new Float:rocketjump2[3] = {-172.0, 1133.0, -59.0};
							new Float:rocketjump3[3] = {-1699.0, 1283.0, 120.0};
							new Float:rocketjump4[3] = {348.0, -1913.0, 196.0};
							new Float:rocketjump5[3] = {-459.0, 994.0, -60.0};
							new Float:rocketjumpfix1[3] = {529.0, 1763.0, 324.0};
							new Float:rocketjumpfix2[3] = {-19.0, 1287.0, 196.0};
							new Float:rocketjumpfix3[3] = {-1697.0, 1059.0, 324.0};
							new Float:rocketjumpfix4[3] = {471.0, -1904.0, 388.0};
							new Float:rocketjumpfix5[3] = {-650.0, 992.0, 232.0};
							new Float:chainDistance1;
							chainDistance1 = GetVectorDistance(clientOrigin,rocketjump1);
							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin,rocketjump2);
							new Float:chainDistance5;
							chainDistance5 = GetVectorDistance(clientOrigin,rocketjump3);
							new Float:chainDistance7;
							chainDistance7 = GetVectorDistance(clientOrigin,rocketjump4);
							new Float:chainDistance9;
							chainDistance9 = GetVectorDistance(clientOrigin,rocketjump5);
							new Float:chainDistance3;
							chainDistance3 = GetVectorDistance(clientOrigin,rocketjumpfix1);
							new Float:chainDistance4;
							chainDistance4 = GetVectorDistance(clientOrigin,rocketjumpfix2);
							new Float:chainDistance6;
							chainDistance6 = GetVectorDistance(clientOrigin,rocketjumpfix3);
							new Float:chainDistance8;
							chainDistance8 = GetVectorDistance(clientOrigin,rocketjumpfix4);
							new Float:chainDistance10;
							chainDistance10 = GetVectorDistance(clientOrigin,rocketjumpfix5);
							if(IsWeaponSlotActive(client, 0) && GetHealth(client) > 100.0)
							{
								if(chainDistance1 < 100.0)
								{
									new Float:newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = -90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance2 < 100.0)
								{
									new Float:newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = 37.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance5 < 100.0)
								{
									new Float:newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = -90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance7 < 100.0)
								{
									new Float:newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = 0.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance9 < 100.0)
								{
									new Float:newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = 179.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance3 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										new Float:newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = -90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance4 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										new Float:newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 37.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance6 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										new Float:newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = -90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance8 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										new Float:newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 0.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance10 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										new Float:newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = -179.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
							}
						}
					}
					if(StrContains(currentMap, "koth_harvest_final" , false) != -1 || StrContains(currentMap, "koth_harvestalpine" , false) != -1 )
					{
						new Float:clientOrigin[3];
						GetClientAbsOrigin(client, clientOrigin);
						if(team == 2)
						{
							new Float:rocketjump1[3] = {-586.0, -1566.0, 68.0};
							new Float:rocketjump2[3] = {6.0, -318.0, 84.0};
							new Float:rocketjump3[3] = {438.0, 495.0, 69.0};
							new Float:rocketjump4[3] = {0.0, -1651.0, 68.0};
							new Float:rocketjumpfix1[3] = {-571.0, -1427.0, 281.0};
							new Float:rocketjumpfix2[3] = {-2.0, -222.0, 292.0};
							new Float:rocketjumpfix3[3] = {425.0, 617.0, 280.0};
							new Float:rocketjumpfix4[3] = {216.0, -1531.0, 68.0};
							new Float:chainDistance1;
							chainDistance1 = GetVectorDistance(clientOrigin,rocketjump1);
							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin,rocketjump2);
							new Float:chainDistance5;
							chainDistance5 = GetVectorDistance(clientOrigin,rocketjump3);
							new Float:chainDistance7;
							chainDistance7 = GetVectorDistance(clientOrigin,rocketjump4);
							new Float:chainDistance3;
							chainDistance3 = GetVectorDistance(clientOrigin,rocketjumpfix1);
							new Float:chainDistance4;
							chainDistance4 = GetVectorDistance(clientOrigin,rocketjumpfix2);
							new Float:chainDistance6;
							chainDistance6 = GetVectorDistance(clientOrigin,rocketjumpfix3);
							new Float:chainDistance8;
							chainDistance8 = GetVectorDistance(clientOrigin,rocketjumpfix4);
							if(IsWeaponSlotActive(client, 0) && GetHealth(client) > 100.0)
							{
								if(chainDistance1 < 100.0)
								{
									new Float:newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = 90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance2 < 100.0)
								{
									new Float:newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = 90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance5 < 100.0)
								{
									new Float:newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = 90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance7 < 75.0)
								{
									new Float:newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 40.0;
									newDirection[1] = -135.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance3 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										new Float:newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance4 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										new Float:newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance6 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										new Float:newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
										vel = moveForward(vel,300.0);
									}
								}
								if(chainDistance8 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										new Float:newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 35.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
							}
						}
						if(team == 3)
						{
							new Float:rocketjump1[3] = {578.0, 1561.0, 68.0};
							new Float:rocketjump2[3] = {73.0, 345.0, 79.0};
							new Float:rocketjump3[3] = {-495.0, -537.0, 75.0};
							new Float:rocketjump4[3] = {1382.0, -159.0, 62.0};
							new Float:rocketjump5[3] = {661.0, -96.0, 70.0};
							new Float:rocketjumpfix1[3] = {597.0, 1429.0, 280.0};
							new Float:rocketjumpfix2[3] = {54.0, 225.0, 291.0};
							new Float:rocketjumpfix3[3] = {-461.0, -623.0, 282.0};
							new Float:rocketjumpfix4[3] = {1049.0, -183.0, 67.0};
							new Float:chainDistance1;
							chainDistance1 = GetVectorDistance(clientOrigin,rocketjump1);
							new Float:chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin,rocketjump2);
							new Float:chainDistance5;
							chainDistance5 = GetVectorDistance(clientOrigin,rocketjump3);
							new Float:chainDistance7;
							chainDistance7 = GetVectorDistance(clientOrigin,rocketjump4);
							new Float:chainDistance8;
							chainDistance8 = GetVectorDistance(clientOrigin,rocketjump5);
							new Float:chainDistance3;
							chainDistance3 = GetVectorDistance(clientOrigin,rocketjumpfix1);
							new Float:chainDistance4;
							chainDistance4 = GetVectorDistance(clientOrigin,rocketjumpfix2);
							new Float:chainDistance6;
							chainDistance6 = GetVectorDistance(clientOrigin,rocketjumpfix3);
							new Float:chainDistance9;
							chainDistance9 = GetVectorDistance(clientOrigin,rocketjumpfix4);
							if(IsWeaponSlotActive(client, 0) && GetHealth(client) > 100.0)
							{
								if(chainDistance1 < 100.0)
								{
									new Float:newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = -90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance2 < 100.0)
								{
									new Float:newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = -90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance5 < 100.0)
								{
									new Float:newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 89.0;
									newDirection[1] = -90.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance7 < 60.0)
								{
									new Float:newDirection[3];
									GetClientEyeAngles(client, newDirection);
									newDirection[0] = 50.0;
									newDirection[1] = 0.0;
									newDirection[2] = 0.0;
									TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									buttons |= IN_JUMP;
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
									vel = moveForward(vel,300.0);
								}
								if(chainDistance8 < 75.0)
								{
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										new Float:newDirection[3];
										GetClientEyeAngles(client, newDirection);
										newDirection[0] = 89.0;
										newDirection[1] = 160.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
										buttons |= IN_JUMP;
										buttons |= IN_DUCK;
										buttons |= IN_ATTACK;
										vel = moveForward(vel,300.0);
									}
								}
								if(chainDistance3 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										new Float:newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = -90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance4 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										new Float:newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = -90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance6 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										new Float:newDirection[3];
										newDirection[0] = 89.0;
										newDirection[1] = -90.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
									}
								}
								if(chainDistance9 < 300.0)
								{
									vel = moveForward(vel,300.0);
									if(GetEntityFlags(client) & FL_ONGROUND)
									{
										// NOPE
									}
									else
									{
										new Float:newDirection[3];
										newDirection[0] = 0.0;
										newDirection[1] = 177.0;
										newDirection[2] = 0.0;
										TeleportEntity(client, NULL_VECTOR, newDirection, NULL_VECTOR);
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

stock bool:IsWeaponSlotActive(iClient, iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

stock GetHealth(client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

bool:IsValidClient( client )
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) )
        return false;

    return true;
}
