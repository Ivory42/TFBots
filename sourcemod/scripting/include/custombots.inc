#if defined _custombots_included
 #endinput
#endif
#define _custombots_included

#include <objectmanager>
#include <tf2_stocks>

enum ENavType
{
	CBNavType_SniperPos = 0,
	CBNavType_RocketJump,
	CBNavType_Engineer,
	CBNavType_FallBackPos
};

enum EParamType
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
	CBParam_ClassPriority
}

enum struct FBotWeapon
{
	char Classname[128];
	int DefIndex;
	int Killstreak;
	int Sheen;
	int KSEffect;
	int Effect;
	bool Australium;
}

enum struct FBotCosmetic
{
	int DefIndex;
	bool Unusual;
	int Effect;
	int Paint1;
	int Paint2;
}

enum struct FBotData
{
	int Index;
	char Name[64];

	float Inaccuracy;			// How inaccurate our aim is
	float AimDelay;				// Delay between correcting our aim
	float AimFOV;				// We find aggro targets in this FOV
	float AggroDelay;			// Delay between finding aggro targets
	float AttackRange;			// We do not fire at targets outside this range
	float HealthThreshold;		// When our health drops below this ratio, we try to flee
	float PathFindRad;

	int Proficiency;

	bool PreferJump;
	bool PreferMelee;

	// Sniper variables
	float SniperAimTime;
	float PressureDistance;
	int SniperConfidence;

	// Soldier variables
	float HeightThreshold;
	float BlastJumpChance;
	float BlastJumpProf;
	int SoldierConfidence;
	bool AimGround;

	TFClassType Class; 			// Our main class
	TFClassType Offclass;		// Our off class
	TFClassType PriorityClass; 	// Prioritize enemies of this class type

	FBotWeapon Primary;
	FBotWeapon Secondary;
	FBotWeapon Melee;

	FBotCosmetic Cosmetic1;
	FBotCosmetic Cosmetic2;
	FBotCosmetic Cosmetic3;
}

methodmap ACustomBot < AClient
{
	property bool HookedBot
	{
		public get() { return this.GetObjectProp("TFBot.IsHookedBot"); }
		public set(bool value) { this.SetObjectProp("TFBot.IsHookedBot", value); }
	}

	property int JumpDelayCount
	{
		public get() { return this.GetObjectProp("TFBot.JumpDelayCount"); }
		public set(int value) { this.SetObjectProp("TFBot.JumpDelayCount", value); }
	}

	property int Obstructions
	{
		public get() { return this.GetObjectProp("TFBot.CurrentObstructions"); }
		public set(int value) { this.SetObjectProp("TFBot.CurrentObstructions", value); }
	}

	property int DamageTaken
	{
		public get() { return this.GetObjectProp("TFBot.DamageTaken"); }
		public set(int value) { this.SetObjectProp("TFBot.DamageTaken", value); }
	}

	property bool ShouldCrouch
	{
		public get() { return this.GetObjectProp("TFBot.ShouldBeCrouching"); }
		public set(bool value) { this.SetObjectProp("TFBot.ShouldBeCrouching", value); }
	}

	property bool Jump
	{
		public get() { return this.GetObjectProp("TFBot.ShouldJump"); }
		public set(bool value) { this.SetObjectProp("TFBot.ShouldJump", value); }
	}

	property bool NavJump
	{
		public get() { return this.GetObjectProp("TFBot.ShouldBeCrouching"); }
		public set(bool value) { this.SetObjectProp("TFBot.ShouldBeCrouching", value); }
	}

	property bool Fleeing
	{
		public get() { return this.GetObjectProp("TFBot.BotIsFleeing"); }
		public set(bool value) { this.SetObjectProp("TFBot.BotIsFleeing", value); }
	}

	property bool Attacking
	{
		public get() { return this.GetObjectProp("TFBot.BotIsAttacking"); }
		public set(bool value) { this.SetObjectProp("TFBot.BotIsAttacking", value); }
	}

	property bool InCaptureArea
	{
		public get() { return this.GetObjectProp("TFBot.InCaptureArea"); }
		public set(bool value) { this.SetObjectProp("TFBot.InCaptureArea", value); }
	}

	property bool ScoutSingleJump
	{
		public get() { return this.GetObjectProp("TFBot.ScoutUseSingleJump"); }
		public set(bool value) { this.SetObjectProp("TFBot.ScoutUseSingleJump", value); }
	}

	property float NextAggroTime
	{
		public get() { return this.GetObjectPropFloat("TFBot.AggroTime"); }
		public set(float value) { this.SetObjectPropFloat("TFBot.AggroTime", value); }
	}

	property float NextDoubleJumpTime
	{
		public get() { return this.GetObjectPropFloat("TFBot.DoubleJumpTimer"); }
		public set(float value) { this.SetObjectPropFloat("TFBot.DoubleJumpTimer", value); }
	}

	property float NextJumpTime
	{
		public get() { return this.GetObjectPropFloat("TFBot.SingleJumpTimer"); }
		public set(float value) { this.SetObjectPropFloat("TFBot.SingleJumpTimer", value); }
	}

	property float KeepPrimaryDelay
	{
		public get() { return this.GetObjectPropFloat("TFBot.KeepPrimaryDelay"); }
		public set(float value) { this.SetObjectPropFloat("TFBot.KeepPrimaryDelay", value); }
	}

	property float AmmoPreserveDelay
	{
		public get() { return this.GetObjectPropFloat("TFBot.AmmoPreservationDelay"); }
		public set(float value) { this.SetObjectPropFloat("TFBot.AmmoPreservationDelay". value); }
	}

	property float KeepAmmoDuration
	{
		public get() { return this.GetObjectPropFloat("TFBot.KeepAmmoDuration"); }
		public set(float value) { this.SetObjectPropFloat("TFBot.KeepAmmoDuration", value); }
	}

	property float DamageDelay
	{
		public get() { return this.GetObjectPropFloat("TFBot.DamageDelay"); }
		public set(float value) { this.SetObjectPropFloat("TFBot.DamageDelay", value); }
	}

	property float StepDelay
	{
		public get() { return this.GetObjectPropFloat("TFBot.StutterStepDelay"); }
		public set(float value) { this.SetObjectPropFloat("TFBot.StutterStepDelay", value); }
	}

	property float StrafeSpeed
	{
		public get() { return this.GetObjectPropFloat("TFBot.StrafeSpeed"); }
		public set(float value) { this.SetObjectPropFloat("TFBot.StrafeSpeed", value); }
	}

	property float CallMedicDelay
	{
		public get() { return this.GetObjectPropFloat("TFBot.CallMedicDelay"); }
		public set(float value) { this.SetObjectPropFloat("TFBot.CallMedicDelay", value); }
	}

	property float CrouchDelay
	{
		public get() { return this.GetObjectPropFloat("TFBot.CrouchDelay"); }
		public set(float value) { this.SetObjectPropFloat("TFBot.CrouchDelay", value); }
	}

	property float CrouchTime
	{
		public get() { return this.GetObjectPropFloat("TFBot.CrouchTime"); }
		public set(float value) { this.SetObjectPropFloat("TFBot.CrouchTime", value); }
	}

	property float NextAimTime
	{
		public get() { return this.GetObjectPropFloat("TFBot.NextAutoAimTime"); }
		public set(float value) { this.SetObjectPropFloat("TFBot.NextAutoAimTime", value); }
	}

	public float GetAttackRange() { return this.GetBotData().AttackRange; }
	public float GetAggroDelay() { return this.GetBotData().AggroDelay; }
	public float GetAimFOV() { return this.GetBotData().AimFOV; }
	public float GetInaccuracy() { return this.GetBotData().Inaccuracy; }
	public float GetAimDelay() { return this.GetBotData().AimDelay; }

	public TFClassType GetBotClass() { return this.GetBotData().Class; }
	public TFClassType GetOffclass() { return this.GetBotData().Offclass; }

	public void SetCurrentTarget(FObject target) { this.SetObjectPropEnt("TFBot.CurrentAggroTarget", target); }
	public FObject GetCurrentTarget() { return this.GetObjectPropEnt("TFBot.CurrentAggroTarget"); }

	public void SetShield(FObject shield) { this.SetObjectPropEnt("TFBot.CurrentShieldReference", shield); }
	public FObject GetShield() { return this.GetObjectPropEnt("TFBot.CurrentShieldReference"); }

	public void SetBotData(FBotData data) { this.SetArray("TFBot.BotDataParams", data, sizeof FBotData); }
	public FBotData GetBotData()
	{
		FBotData data;
		this.GetArray("TFBot.BotDataParams", data, sizeof FBotData);

		return data;
	}

	public void SetPreservedAmmo(int ammo, int slot)
	{
		int ammoset[2];
		this.GetArray("TFBot.PreservedAmmoArray", ammoset, 2);
		ammoset[slot] = ammo;

		this.SetArray("TFBot.PreservedAmmoArray", ammoset);
	}
	public int GetPreservedAmmo(int slot)
	{
		int ammoset[2];
		this.GetArray("TFBot.PreservedAmmoArray", ammoset, 2);

		return ammoset[slot];
	}

	public void SetPreservedClip(int ammo, int slot)
	{
		int ammoset[2];
		this.GetArray("TFBot.PreservedClipArray", ammoset, 2);
		ammoset[slot] = ammo;

		this.SetArray("TFBot.PreservedAmmoArray", ammoset);
	}
	public int GetPreservedClip(int slot)
	{
		int ammoset[2];
		this.GetArray("TFBot.PreservedClipArray", ammoset, 2);

		return ammoset[slot];
	}
}

methodmap ASoldier < ACustomBot
{
	property float BlastJumpForwardDelay
	{
		public get() { return this.GetObjectPropFloat("SoldierBot.RJForwardDelay"); }
		public set(float value) { this.SetObjectPropFloat("SoldierBot.RJForwardDelay", value); }
	}

	property float BlastJumpForwardTime
	{
		public get() { return this.GetObjectPropFloat("SoldierBot.RJForwardTime"); }
		public set(float value) { this.SetObjectPropFloat("SoldierBot.RJForwardTime", value); }
	}

	property float BlastJumpCooldown
	{
		public get() { return this.GetObjectPropFloat("SoldierBot.RJCooldown"); }
		public set(float value) { this.SetObjectPropFloat("SoldierBot.RJCooldown", value); }
	}

	property float BlastJumpDelay
	{
		public get() { return this.GetObjectPropFloat("SoldierBot.RJDelayTime"); }
		public set(float value) { this.SetObjectPropFloat("SoldierBot.RJDelayTime", value); }
	}

	property bool NavJump
	{
		public get() { return this.GetObjectProp("SoldierBot.IsUsingNavJump"); }
		public set(bool value) { this.SetObjectProp("SoldierBot.IsUsingNavJump", value); }
	}

	public void SetPreservedAngles(FRotator value) { this.SetObjectPropRotator("SoldierBot.PreservedAngles", value); }
	public FRotator GetPreservedAngles() { return this.GetObjectPropRotator("SoldierBot.PreservedAngles"); }
}

/****************************************************************

	NATIVES
	
****************************************************************/

methodmap FBotStatics
{
	/**
	 * Temporarily override a parameter for the given bot
	 * This will be reset to the config value upon the bot respawning
	 *
	 * @param bot		Handle wrapping the bot
	 * @param value		Value to set
	 * @param param		Parameter to override
	 *
	 */
	public native void OverrideParameter(ACustomBot bot, any value, EParamType param);

	/**
	 * Spawn a bot by name
	 *
	 * @param name	Name of the bot
	 * @param team	Team to spawn on
	 *
	 * @return ACustomBot handle wrapping this bot
	 */
	public native ACustomBot SpawnBotByName(const char[] name, TFTeam team);

	/**
	 * Returns a handle wrapping this client if the client is a bot
	 * 
	 * @param clientId	Client index
	 * 
	 * @return ACustomBot handle if the client is a bot. If the client is not a bot, returns null.
	 */
	public static ACustomBot GetPlayerAsBot(int clientId)
	{
		if (IsFakeClient(clientId))
		{
			ACustomBot bot = view_as<ACustomBot>(FEntityStatics.GetClientFromIndex(clientId));
			return bot;
		}
		else
		{
			return null;
		}
	}
}



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

native void CB_SetBotParameterFloat(int bot, float value, EParamType param);

/**
 * Set a hooked bot's parameter value as an integer
 *
 * @param1 bot - Client Index (MUST BE A FAKECLIENT)
 * @param2 value - Value
 * @param2 param - Bot Parameter to set
 */

native void CB_SetBotParameterInt(int bot, int value, EParamType param);

/**
 * Set a hooked bot's parameter value as a bool
 *
 * @param1 bot - Client Index (MUST BE A FAKECLIENT)
 * @param2 value - Value
 * @param2 param - Bot Parameter to set
 */

native void CB_SetBotParameterBool(int bot, bool value, EParamType param);

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
 * @param3 hooked - Is this bot manually hooked
 */

forward void CB_OnBotResupply(int bot, int index, bool hooked);

/**
 * Forward called when a hooked bot dies
 *
 * @param1 bot - Client Index (MUST BE A FAKECLIENT)
 * @param2 index - Bot Index
 * @param3 hooked - Is this bot manually hooked
 * @param4 attacker - Index of attacker
 * @param5 crit - Crit type of kill
 */

forward void CB_OnBotDeath(int bot, int index, bool hooked, int attacker, int crit);

/**
 * Forward called when a hooked bot blast jumps
 *
 * @param1 bot - Client Index (MUST BE A FAKECLIENT)
 * @param2 index - Bot Index
 * @param3 hooked - Is this bot manually hooked
 * @param4 weapon - Weapon Definition index being used
 */

forward void CB_OnBotBlastJump(int bot, int index, bool hooked, int weapon);

/**
 * Forward called when a hooked bot joins the game
 *
 * @param1 bot - Client Index (MUST BE A FAKECLIENT)
 * @param2 index - Bot Index
 * @param3 plugin - plugin associated with the bot (INVALID_PLUGIN if no plugin specified)
 */

forward void CB_OnBotAdded(int bot, int index, const char[] plugin);
