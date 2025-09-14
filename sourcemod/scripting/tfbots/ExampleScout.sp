/*********************

Very simple example plugin for custom bot behavior.
Bots using this plugin use the "Thanks!" voice command after every kill and have a very high crit chance.

*********************/

#pragma semicolon 1

#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <custombots>

public Plugin myinfo = {
	name = "[Custom Bots] Example Scout",
	author = "IvoryPal",
	version = "1.0",
}

bool IsBot[MAXPLAYERS+1];

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
}

public void OnClientDisconnect(int client)
{
	IsBot[client] = false; //uninitialize when the bot leaves
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dbroad)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (IsBot[attacker] && CB_IsCustomBot(attacker))
	{
		FakeClientCommand(attacker, "voicemenu 0 1"); //thanks paly
	}
	return Plugin_Continue;
}

public void CB_OnBotAdded(int bot, int index, const char[] plugin)
{
	if (CB_IsCustomBot(bot))
	{
		if (StrEqual(plugin, "example_bot"))
		{
			IsBot[bot] = true;
		}
	}
}

public Action TF2_CalcIsAttackCritical(int bot, int weapon, char[] weaponname, bool& result)
{
	if (IsBot[bot] && CB_IsCustomBot(bot) && TF2_GetPlayerClass(bot) == TFClass_Scout)
	{
		int critchance = GetRandomInt(1, 3); //give a higher crit chance because lime scouts are annoying :)
		if (critchance == 1)
		{
			result = true;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}
