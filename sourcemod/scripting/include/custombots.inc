#if defined _custombots_included
 #endinput
#endif
#define _custombots_included

#include <objectmanager>

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

enum struct FBotData
{
	int Index;
	char Name[64];

	TFClassType Class;
	TFClassType Offclass;
}

methodmap ATFBot < AClient
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

	property float DoubleJumpTimer
	{
		public get() { return this.GetObjectPropFloat("TFBot.DoubleJumpTimer"); }
		public set(float value) { this.SetObjectPropFloat("TFBot.DoubleJumpTimer", value); }
	}

	property float JumpTimer
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

	public void SetShield(FObject shield) { this.SetObjectPropEnt("TFBot.CurrentShieldReference", shield); }
	public FObject GetShield() { return this.GetObjectPropEnt("TFBot.CurrentShieldReference"); }

	public void SetBotData(FBotData data) { this.SetArray("TFBot.BotDataParams", data, sizeof FBotData); }
	public FBotData GetBotData()
	{
		FBotData data;
		this.GetArray("TFBot.BotDataParams", data, sizeof FBotData);

		return data;
	}

	public void SetPreservedAmmo(int ammo, TFWeaponSlot slot)
	{
		int ammoset[2];
		this.GetArray("TFBot.PreservedAmmoArray", ammoset, 2);
		ammoset[slot] = ammo;

		this.SetArray("TFBot.PreservedAmmoArray", ammoset);
	}
	public int GetPreservedAmmo(TFWeaponSlot slot)
	{
		int ammoset[2];
		this.GetArray("TFBot.PreservedAmmoArray", ammoset, 2);

		return ammoset[slot];
	}

	public void SetPreservedClip(int ammo, TFWeaponSlot slot)
	{
		int ammoset[2];
		this.GetArray("TFBot.PreservedClipArray", ammoset, 2);
		ammoset[slot] = ammo;

		this.SetArray("TFBot.PreservedAmmoArray", ammoset);
	}
	public int GetPreservedClip(TFWeaponSlot slot)
	{
		int ammoset[2];
		this.GetArray("TFBot.PreservedClipArray", ammoset, 2);

		return ammoset[slot];
	}
}

methodmap ASoldier < ATFBot
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
	 * @param bot		Client index of the bot
	 * @param value		Value to set
	 * @param param		Parameter to override
	 *
	 */
	public native void OverrideParameter(ACBot bot, any value, EParamType param);

	/**
	 * Spawn a bot by name
	 *
	 * @param name	Name of the bot
	 * @param team	Team to spawn on
	 *
	 * @return ACBot handle wrapping this bot
	 */
	public native ACBot SpawnBotByName(const char[] name, TFTeam team);

	/**
	 * Returns a handle wrapping this client if the client is a bot
	 * 
	 * @param clientId	Client index
	 * 
	 * @return ATFBot handle if the client is a bot. If the client is not a bot, returns null.
	 */
	public static ATFBot GetPlayerAsBot(int clientId)
	{
		if (IsFakeClient(clientId))
		{
			ATFBot bot = view_as<ATFBot>(FEntityStatics.GetClientFromIndex(clientId));
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
