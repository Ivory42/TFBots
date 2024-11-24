# Custom TF2 Bot Logic

## REQUIRES TF2Items and TF2Attributes!

## 10/2022: Complete rewrite from the ground up is planned. This plugin is old and VERY hard to follow as it currently stands.
## 11/2024: This plugin currently has high chances of causing frequent errors and server stutters. These issues will be fixed with the rewrite.

TFBots aren't very interesting or engaging to fight, so I decided to revamp them and make them behave more like players.
This is by no means perfect but the bots are able to behave a lot more like players than normally.

## ConVars and Commands

- `tf_bot_allow_join` - Allows custom bots to randomly join and disconnect from the server
  
- `sm_spawnbot <index>` - Manually spawns a bot with the given config index
- `sm_naveditor` - Opens the navigation editor
- `sm_reloadnodes` - Reloads all current navigation nodes

#### Features

 - Bots will constantly try to avoid obstacles obstructing their path if possible
 - Bots stutter step while in combat
 - In-depth Navigation editor to allow map-specific configuration (more info below)
 - Proper support for playing 5CP
    - Bots will decide if it's better to attack or defend their current point based on how many teammates are alive and how many enemies are alive
    - Bots are much less likely to get stuck at the wrong point
 
 - Configurable, individual bots
    - Define your own bots in `configs/botindexes.txt` (example bot provided!)
    - Define custom logic in sub-plugins to extend specific bot behaviors.
    - Up to 56 individual bots supported.
        - Can add as many presets as you want, but any indexes above 56 must be spawned manually or through other plugins
        
    - Scouts can be configured to prefer to jump while in combat
    - Soldiers can be configured to rocket jump towards targets and attempt to bomb them
    - Soldiers can be configured to shoot the ground position of an airborn player instead of shooting where the target currently is
    - Soldiers will attempt to market garden if they are given a Market Gardener
    - Soldiers will pull out their melee and flee if they drop below a health threshold and have the escape plan equipped
    - Soldiers know how to use The Rocket Jumper properly
    - Demomen will hold off on charging until they see an enemy if a shield is equipped
    - Demomen with a shield will not cancel their charge by swinging mindlessly
    - Pyros with flareguns will attempt flare combos with airblast
    - Pyros with the Powerjack will hold it out while not in combat
    - Medics will pop Kritz if their heal target is in combat
    - Medics will attempt to heal players with their crossbow
    - Snipers will stutter step after taking shots
    - Snipers can be configured to have different steady rates, so some can shoot quicker than others
    
## Navigation Editor

Included in this plugin is a way to give bots (mostly soldiers) more customization depending on the current map. The navigation editor menu can be opened with `sm_naveditor`.

With this editor, nodes can be placed around the map which will cause custom bots to perform certain actions when they get close. There are currently three node types:
- Rocket Jump Node
- Sniper Node
- Fallback Node

#### Rocket Jump Nodes
Rocket Jump nodes can be used to tell soldier bots where a good position to rocket jump is. These nodes are highly configurable.
 - Set optional view angles to force the bot to use (useful for setting up rollouts or for making them jump into specific positions)
 - Configurable radius
 - Configure whether the node can only be used while a bot is already blast jumping (predefined pogos!)
 - Set whether a node should be used by a specific team or not
 
#### Sniper Nodes
Sniper nodes are rather self explanatory. These are just `func_tfbot_hint` entities setup for snipers to use as sniping positions
 - They can be configured to be used by one team or both teams
 
#### Fallback Nodes
Fallback nodes are primarily used for 5CP maps, and thus cannot be accessed on any other map types. These nodes will act as large areas where bots will retreat to when they decide their team strength is not sufficient
 - Configurable radius
 - Configurable team association

## Developers
There are multiple native functions and forwards that can be used to modify bots with their own plugins.

Check `scripting/include/custombots.inc` for a more detailed explanation of each function.

Requries Sourcemod 1.11+ to compile

#### Natives
- `CB_SpawnBotByIndex` - Spawns a custom bot with the given index on a specific team
- `CB_GetBotIndex` - Retrieves a bot's predefined index. (This will return 0 if the bot is not using a preset)
- `CB_HookBot` - Hooks a pre-existing non-custom TFBot and allows it to accept behavior parameters
- `CB_SetBotParameterFloat` - Sets a float parameter on a hooked TFBot
- `CB_SetBotParameterInt` - Sets an integer parameter on a hooked TFBot
- `CB_SetBotParameterBool` - Sets a bool parameter on a hooked TFBot
- `CB_IsCustomBot` - Returns true if the client is a hooked TFBot
- `CB_GetBotClass` - Returns the bot's preferred class index
- `CB_GetBotOffClass` - Returns the bot's secondary class index

#### Forwards
- `CB_OnBotResupply` - Called when a hooked bot is resupplied
- `CB_OnBotDeath` - Called when a hooked bot is killed
- `CB_OnBotBlastJump` - Called when a hooked bot attempts to blast jump
- `CB_OnBotAdded` - Called when a bot joins with a predefined logic plugin - used for determining parameters in sub-plugins

## KNOWN ISSUES
- Sniper bots don't always respect their steady rate parameters
- Sniper bots will sometimes shoot targets they should not be able to see
- If a spy bot is present, may cause significant stutters from disguise errors. (Wont fix until rewrite)

## FUTURE PLANS

- Give rocket jump nodes difficulty ratings so soldier bots can have different rocket jump skill values
- Allow Demoman bots to sticky jump
- Give scouts a bit of a better system for jumping (allow them to detect incoming projectiles and properly dodge in time)
- Allow bots to prioritize specific classes
- Allow medics to prioritize heal targets
