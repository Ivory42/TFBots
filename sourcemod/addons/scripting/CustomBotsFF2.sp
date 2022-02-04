/*
	Module for Custom Bots to properly play Freak Fortress 2
	FF2 includes NOT provided with this repository
*/

#include <sdktools>
#include <tf2>
#include <custombots>
#include <freak_fortress_2>

public Plugin MyInfo =
{
	name = "[Custom Bots] FF2 Module",
	author = "IvoryPal"
};

bool IsBoss[MAXPLAYERS+1];

ConVar g_allBots;

public void OnPluginStart()
{
	HookEvent("arena_round_start", RoundBegin);
	g_allBots = CreateConVar("tfbot_ff2_all_bots", "0", "Will this plugin hook the logic of any bot, or only apply changes to custom bots", _, true, 0.0, true, 1.0);
}

public void OnClientPostAdminCheck(int client)
{
	if (IsFakeClient(client) && g_allBots.BoolValue)
	{
		/*
			Hook the bot and set parameters
			range set to -1.0 to ignore range settings
			class set to 0 to keep the bot's class
		*/
		CB_HookBot(client);
		CB_SetParamFloat(client, -1.0, CBParam_Range);
		CB_SetParamInt(client, 0, CBParam_Class);
	}
}

/*
	If our bot is a boss, override their combat range preference so they try to stay within melee range
*/
Action RoundBegin(Event event, const char[] name, bool dBroad)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IaValidBot(i))
		{
			if (FF2_GetBossIndex(i) > 0)
			{
				CB_OverrideParameter(i, 0.0, CBParam_Range);
				IsBoss[i] = true;
			}
			else IsBoss[i] = false;
		}
	}
}
