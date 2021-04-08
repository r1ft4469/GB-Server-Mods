Ground Branch Server Mods
=============================

- [Installing Modes and Maps](#installing-modes-and-maps)
- [Enforcing Clothing Colors On Server](#enforcing-clothing-colors-on-server)
- [Enforcing Gear Sets On Server](#enforcing-gear-sets-on-server)
- [Ground Branch Server Lua Commands](#ground-branch-server-lua-commands)

----------------------------------

# Installing Modes and Maps

Extract **Release Files** to Ground Branch Server Dir :

`Steam\steamapps\common\Ground Branch`

**NOTE:**
**Must Be Installed Locally to Change Server to Map and Mode!! (Only Admins Need)**

**If Not Using Release Files Maps May Not Work at All.**

# Enforcing Clothing Colors On Server

Files for Clothing Enforcement for Red and Blue are in :

`GroundBranch\ServerConfig`

These Files Enforce
* Red Shirts and Tan Rigs
* Blue Shirts and Black Rigs

# Enforcing Gear Sets On Server

**Must set Custom TeamLoadoutName in the lua to Enforce (Client Takes Priority)**

**These Files are Compleatly Default**

Files for Gear Sets for Red and Blue are in :

`GroundBranch\Content\GroundBranch\DefaultLoadouts`

Get Filter Names from Kit Files in :

`%USERPROFILE%\Documents\GroundBranch\Loadouts`

(Would Be Great if someone could compile a list of items)

# Ground Branch Server Lua Commands
- [Actor](#Actor)
- [AI](#AI)
- [GameMode](#GameMode)
- [GameplayStatics](#GameplayStatics)
- [Interface](#Interface)
- [Math](#Math)
- [Player](#Player)
- [StaticsLibrary](#StaticsLibrary)
- [Timer](#Timer)
- [Vector](#Vector)

### Actor
```
ToString(Actor);
SetTeamId(Actor, TeamId);
SetHidden(Actor, Hidden);
SetEnableCollision(Actor, Enabled);
SetActive(Actor, NewActive);
RemoveTag(Actor, Tag); 
IsOverlapping(Actor, OtherActor); 
IsActive(Actor); 
HasTag(Actor, Tag);
GetTeamId(Actor);
GetTags(Actor);
GetTag(Actor, Index); 
GetOverlaps(Actor, Class);
GetLocation(Actor);
AddTag(Actor, Tag);
```

### AI
```
GetControllers(Class, Tag, TeamId, SquadId); 
CreateOverDuration(Duration, Count, OrderedSpawnPoints, AIControllerTag); 
Create(SpawnPoint, AIControllerTag, FreezeTime);
CleanUp(AIControllerTag);
```

### GameMode
```
SetTeamAttitude(Team, OtherTeam, Attitude);
SetRoundStageTime(RoundStageTime); 
SetRoundStage(RoundStageName); 
SendEveryoneToReadyRoom();
SendEveryoneToPlayArea(); 
RemoveGameRule(RuleName); 
PrepLatecomer(Target); 
MakeEveryoneSpectate(); 
HasGameRule(RuleName); 
HasGameOption(OptionName); 
GetScript();
GetRoundStageTime();
GetRoundStage();
GetReadyPlayerTeamCounts(ExcludeBots);
GetPlayerList(SortType, TeamId, MustWantToEnterPlay, MinLives, MustBeHuman);
GetPlayerCount(ExcludeBots); 
GetInsertionPointName(InsertionPoint);
GetGameOption(OptionName); 
GetBestLateComerInsertionPoint(Target); 
EnterReadyRoom(Target); 
EnterPlayArea(Target);
ClearRoundStageTime();
ClearGameStats(); 
ClearGameObjectives(); 
BroadcastGameMessage(GameMessageId, Duration);
AddStringTable(StringTableId);
AddPlayerTeam(Team, Name, ProfileName);
AddObjectiveMarker(Location, TeamId, Name, Active);
AddGameStat(GameStat);
AddGameSetting(Name, MinValue, MaxValue, IterateValue, DefaultValue); 
AddGameRule(RuleName);
AddGameObjective(TeamId, Name, Type);
```

### GameplayStatics
```
GetAllActorsWithTag(Tag); 
GetAllActorsOfClassWithTag(Class, Tag); 
GetAllActorsOfClass(Class); 
DebugPrint(Message);
```

### Interface
```
GetLuaTable();
```

### Math
```
GetRandomRange(Min, Max); 
GetRandom(Max);
```

### Player 
```
ShowWorldPrompt(Player, Location, Tag, Duration);
ShowGameMessage(Player, Message, Duration);
SetLives(Player, NewLives);
SetInsertionPoint(Player, NewInsertionPoint);
SetAllowedToRestart(Player, Allowed);
IsAlive(Player);
HasItemWithTag(Player, Tag);
GetPlayerState(Player);
GetLives(Player); 
GetInventory(Player);
GetInsertionPoint(Player);
GetCharacter(Player);
FreezePlayer(Player, Duration);
```

### StaticsLibrary
```
LuaValueToScript(LuaValue); 
LuaValueToPlayerState(LuaValue); 
LuaValueToCharacter(LuaValue); 
ActorsToLuaTable(WorldContextObject, LuaStateClass, Actors);
```

### Timer
```
SetTimer(InTable, InKey, InRate, InLoop);
ClearTimer(InTable, InKey);
ClearAll();
```


### Vector
```
VectorSubtract(A, B);
VectorStr(LuaVector);
VectorSizeSquared2D(A);
VectorSizeSquared(A); 
VectorSize2D(A);
VectorSize(A);
VectorNew(Self, X, Y, Z);
VectorMultiply(A, B);
VectorEquals(A, B);
VectorDivide(A, B);
VectorAdd(A, B);
BuildVector(Vector);
```


