#if defined _custombots_included
 #endinput
#endif
#define _custombots_included
#define MAXBOTS 56
#define MAXRJPOS	30
#define MAXSNIPEPOS	24
#define MAXFALLBACK 8
#define MAXENGIEPOS 24

enum CBNavType
{
	CBNavType_SniperPos = 0,
	CBNavType_RocketJump,
	CBNavType_Engineer,
	CBNavType_FallBackPos
};

enum CBParamType
{
	CBParam_Aggro = 0,
	CBParam_AimDelay,
	CBParam_Range,
	CBParam_FOV,
	CBParam_Class,
	CBParam_OffClass,
	CBParam_Inaccuracy,
	CBParam_PreferJump,
	CBParam_SniperAimTime,
	CBParam_SoldierAimGround,
	CBParam_SoldierGroundHeight,
	CBParam_HPRatio,
	CBParam_ClassPriority,
	CBParam_AA
}


/****************************************************************

	NATIVES
	
****************************************************************/


/**
 * Spawn a bot by index
 *
 * @param1 bot - Bot index
 * @param2 teamnum - Team number to spawn on
 */

native void CB_SpawnBotByIndex(int bot, int teamnum);

/**
 * Retrieve the bot index of a custom bot
 *
 * @param1 bot - Client index of the bot
 *
 * @return config index of the bot, 0 if not a preset bot
 */

native int CB_GetBotIndex(int bot);

/**
 * Hook a bot's logic if it is not already assigned an index
 *
 * @param1 bot - Client Index of the bot
 */

native void CB_HookBot(int bot);

/**
 * Set a hooked bot's parameter value as a float
 *
 * @param1 bot - Client Index (MUST BE A FAKECLIENT)
 * @param2 value - Value
 * @param2 param - Bot Parameter to set
 */

native void CB_SetBotParameterFloat(int bot, float value, CBParamType param);

/**
 * Set a hooked bot's parameter value as an integer
 *
 * @param1 bot - Client Index (MUST BE A FAKECLIENT)
 * @param2 value - Value
 * @param2 param - Bot Parameter to set
 */

native void CB_SetBotParameterInt(int bot, int value, CBParamType param);

/**
 * Set a hooked bot's parameter value as a bool
 *
 * @param1 bot - Client Index (MUST BE A FAKECLIENT)
 * @param2 value - Value
 * @param2 param - Bot Parameter to set
 */

native void CB_SetBotParameterBool(int bot, bool value, CBParamType param);

/**
 * Check if client is a custom bot
 *
 * @param1 bot - Client Index
 *
 * @return true if client is a custom bot
 */
 
native bool CB_IsCustomBot(int bot);

/**
 * Returns main class of custom bot
 *
 * @param1 bot - Client Index
 *
 * @return class ID of main class
 */

native int CB_GetBotClass(int bot);

/**
 * Returns offclass of custom bot
 *
 * @param1 bot - Client Index
 *
 * @return class ID of offclass
 */

native int CB_GetBotOffClass(int bot);



/****************************************************************

	FORWARDS
	
****************************************************************/

/**
 * Forward called when a hooked bot resupplies and is given its loadout
 *
 * @param1 bot - Client Index (MUST BE A FAKECLIENT)
 * @param2 index - Bot Index
 * @param2 hooked - Is this bot manually hooked
 */

//forward void CB_OnBotResupply(int bot, int index, bool hooked);

/**
 * Forward called when a hooked bot attacks with any weapon
 *
 * @param1 bot - Client Index (MUST BE A FAKECLIENT)
 * @param2 index - Bot Index
 * @param2 hooked - Is this bot manually hooked
 * @param3 weapon - Weapon Definition Index
 * @param4 crit - Is this a critical attack
 */

//forward Action CB_OnBotAttack(int bot, int index, bool hooked, int weapon, bool crit);

/**
 * Forward called when a hooked bot dies
 *
 * @param1 bot - Client Index (MUST BE A FAKECLIENT)
 * @param2 index - Bot Index
 * @param2 hooked - Is this bot manually hooked
 * @param3 attacker - Index of attacker
 * @param4 crit - Crit type of kill
 */

//forward void CB_OnBotDeath(int bot, int index, bool hooked, int attacker, int crit);

/**
 * Forward called when a hooked bot jumps
 *
 * @param1 bot - Client Index (MUST BE A FAKECLIENT)
 * @param2 index - Bot Index
 * @param2 hooked - Is this bot manually hooked
 */

//forward void CB_OnBotJump(int bot, int index, bool hooked);

/**
 * Forward called when a hooked bot blast jumps
 *
 * @param1 bot - Client Index (MUST BE A FAKECLIENT)
 * @param2 index - Bot Index
 * @param2 hooked - Is this bot manually hooked
 * @param3 weapon - Weapon Definition index being used
 */

//forward void CB_OnBotBlastJump(int bot, int index, bool hooked, int weapon);

/**
 * Forward called when a hooked bot takes damage
 *
 * @param1 bot - Client Index (MUST BE A FAKECLIENT)
 * @param2 index - Bot Index
 * @param2 hooked - Is this bot manually hooked
 * @param3 damage - Damage dealt to bot
 * @param4 crit - Was this damage critical
 * @param5 attacker - Index of attacker
 * @param6 inflictor - Index of inflictor
 *
 * @return - damage will be set to return value
 */

//forward Action CB_OnBotTakeDamage(int bot, int index, bool hooked, float damage, bool crit, int attacker, int inflictor);
