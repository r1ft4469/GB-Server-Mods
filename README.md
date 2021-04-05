# Ground Branch Server Lua Commands

##GroundBranch.GBLuaActorPackage
```
struct FLuaValue ToString(struct FLuaValue Actor);
struct FLuaValue SetTeamId(struct FLuaValue Actor, struct FLuaValue TeamId);
void SetHidden(struct FLuaValue Actor, struct FLuaValue Hidden);
void SetEnableCollision(struct FLuaValue Actor, struct FLuaValue Enabled);
void SetActive(struct FLuaValue Actor, struct FLuaValue NewActive);
void RemoveTag(struct FLuaValue Actor, struct FLuaValue Tag); 
struct FLuaValue IsOverlapping(struct FLuaValue Actor, struct FLuaValue OtherActor); 
struct FLuaValue IsActive(struct FLuaValue Actor); 
struct FLuaValue HasTag(struct FLuaValue Actor, struct FLuaValue Tag);
struct FLuaValue GetTeamId(struct FLuaValue Actor);
struct FLuaValue GetTags(struct FLuaValue Actor);
struct FLuaValue GetTag(struct FLuaValue Actor, struct FLuaValue Index); 
struct FLuaValue GetOverlaps(struct FLuaValue Actor, struct FLuaValue Class);
struct FLuaValue GetLocation(struct FLuaValue Actor);
void AddTag(struct FLuaValue Actor, struct FLuaValue Tag);
```

##GroundBranch.GBLuaAIPackage
```
struct FLuaValue GetControllers(struct FLuaValue Class, struct FLuaValue Tag, struct FLuaValue TeamId, struct FLuaValue SquadId); 
void CreateOverDuration(struct FLuaValue Duration, struct FLuaValue Count, struct FLuaValue OrderedSpawnPoints, struct FLuaValue AIControllerTag); 
void Create(struct FLuaValue SpawnPoint, struct FLuaValue AIControllerTag, struct FLuaValue FreezeTime);
void CleanUp(struct FLuaValue AIControllerTag);
```

##GroundBranch.GBLuaGameModePackage
```
void SetTeamAttitude(struct FLuaValue Team, struct FLuaValue OtherTeam, struct FLuaValue Attitude);
void SetRoundStageTime(struct FLuaValue RoundStageTime); 
void SetRoundStage(struct FLuaValue RoundStageName); 
void SendEveryoneToReadyRoom();
void SendEveryoneToPlayArea(); 
void RemoveGameRule(struct FLuaValue RuleName); 
struct FLuaValue PrepLatecomer(struct FLuaValue Target); 
void MakeEveryoneSpectate(); 
struct FLuaValue HasGameRule(struct FLuaValue RuleName); 
struct FLuaValue HasGameOption(struct FLuaValue OptionName); 
struct FLuaValue GetScript();
struct FLuaValue GetRoundStageTime();
struct FLuaValue GetRoundStage();
struct FLuaValue GetReadyPlayerTeamCounts(struct FLuaValue ExcludeBots);
struct FLuaValue GetPlayerList(struct FLuaValue SortType, struct FLuaValue TeamId, struct FLuaValue MustWantToEnterPlay, struct FLuaValue MinLives, struct FLuaValue MustBeHuman);
struct FLuaValue GetPlayerCount(struct FLuaValue ExcludeBots); 
struct FLuaValue GetInsertionPointName(struct FLuaValue InsertionPoint);
struct FLuaValue GetGameOption(struct FLuaValue OptionName); 
struct FLuaValue GetBestLateComerInsertionPoint(struct FLuaValue Target); 
void EnterReadyRoom(struct FLuaValue Target); 
void EnterPlayArea(struct FLuaValue Target);
void ClearRoundStageTime();
void ClearGameStats(); 
void ClearGameObjectives(); 
void BroadcastGameMessage(struct FLuaValue GameMessageId, struct FLuaValue Duration);
void AddStringTable(struct FLuaValue StringTableId);
void AddPlayerTeam(struct FLuaValue Team, struct FLuaValue Name, struct FLuaValue ProfileName);
struct FLuaValue AddObjectiveMarker(struct FLuaValue Location, struct FLuaValue TeamId, struct FLuaValue Name, struct FLuaValue Active);
void AddGameStat(struct FLuaValue GameStat);
void AddGameSetting(struct FLuaValue Name, struct FLuaValue MinValue, struct FLuaValue MaxValue, struct FLuaValue IterateValue, struct FLuaValue DefaultValue); 
void AddGameRule(struct FLuaValue RuleName);
void AddGameObjective(struct FLuaValue TeamId, struct FLuaValue Name, struct FLuaValue Type);
```

##GroundBranch.GBLuaGameplayStaticsPackage
```
struct FLuaValue GetAllActorsWithTag(struct FLuaValue Tag); 
struct FLuaValue GetAllActorsOfClassWithTag(struct FLuaValue Class, struct FLuaValue Tag); 
struct FLuaValue GetAllActorsOfClass(struct FLuaValue Class); 
void DebugPrint(struct FLuaValue Message);
```

##GroundBranch.GBLuaInterface
```
struct FLuaValue GetLuaTable();
```

##GroundBranch.GBLuaMathPackage
```
struct FLuaValue GetRandomRange(struct FLuaValue Min, struct FLuaValue Max); 
struct FLuaValue GetRandom(struct FLuaValue Max);
```

##GroundBranch.GBLuaPlayerPackage
```
void ShowWorldPrompt(struct FLuaValue Player, struct FLuaValue Location, struct FLuaValue Tag, struct FLuaValue Duration);
void ShowGameMessage(struct FLuaValue Player, struct FLuaValue Message, struct FLuaValue Duration);
void SetLives(struct FLuaValue Player, struct FLuaValue NewLives);
void SetInsertionPoint(struct FLuaValue Player, struct FLuaValue NewInsertionPoint);
void SetAllowedToRestart(struct FLuaValue Player, struct FLuaValue Allowed);
struct FLuaValue IsAlive(struct FLuaValue Player);
struct FLuaValue HasItemWithTag(struct FLuaValue Player, struct FLuaValue Tag);
struct FLuaValue GetPlayerState(struct FLuaValue Player);
struct FLuaValue GetLives(struct FLuaValue Player); 
struct FLuaValue GetInventory(struct FLuaValue Player);
struct FLuaValue GetInsertionPoint(struct FLuaValue Player);
struct FLuaValue GetCharacter(struct FLuaValue Player);
void FreezePlayer(struct FLuaValue Player, struct FLuaValue Duration);
```

##GroundBranch.GBLuaStaticsLibrary
```
struct FLuaValue LuaValueToScript(struct FLuaValue LuaValue); 
struct AGBPlayerState* LuaValueToPlayerState(struct FLuaValue LuaValue); 
struct AGBCharacter* LuaValueToCharacter(struct FLuaValue LuaValue); 
struct FLuaValue ActorsToLuaTable(struct UObject* WorldContextObject, struct ULuaState* LuaStateClass, struct TArray<struct AActor*> Actors);
```

##GroundBranch.GBLuaTimerPackage
```
void SetTimer(struct FLuaValue InTable, struct FLuaValue InKey, struct FLuaValue InRate, struct FLuaValue InLoop);
void ClearTimer(struct FLuaValue InTable, struct FLuaValue InKey);
void ClearAll();
```


##GroundBranch.GBLuaVectorPackage
```
struct FLuaValue VectorSubtract(struct FLuaValue A, struct FLuaValue B);
struct FLuaValue VectorStr(struct FLuaValue LuaVector);
struct FLuaValue VectorSizeSquared2D(struct FLuaValue A);
struct FLuaValue VectorSizeSquared(struct FLuaValue A); 
struct FLuaValue VectorSize2D(struct FLuaValue A);
struct FLuaValue VectorSize(struct FLuaValue A);
struct FLuaValue VectorNew(struct FLuaValue SelfPackage, struct FLuaValue X, struct FLuaValue Y, struct FLuaValue Z);
struct FLuaValue VectorMultiply(struct FLuaValue A, struct FLuaValue B);
struct FLuaValue VectorEquals(struct FLuaValue A, struct FLuaValue B);
struct FLuaValue VectorDivide(struct FLuaValue A, struct FLuaValue B);
struct FLuaValue VectorAdd(struct FLuaValue A, struct FLuaValue B);
struct FLuaValue BuildVector(struct FVector Vector);
```


