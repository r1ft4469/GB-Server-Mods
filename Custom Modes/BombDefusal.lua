local bombdefual = {
	Char_Start = 65,
	BlueTeamId = 1,
	BlueTeamTag = "Blue",
	BlueTeamLoadoutName = "Blue",
	RedTeamId = 2,
	RedTeamTag = "Red",
	RedTeamLoadoutName = "Red",
	RoundResult = "",
	InsertionPoints = {},
	bFixedInsertionPoints = true,
	NumInsertionPointGroups = 0,
	PrevGroupIndex = 0,
	Bomb_Count = 2,
	MaxBomb_Count = 10,
	AllBombs = {},
	BombTag = "BombIntel",
	DefuseTime = 10,
	MinDefuseTime = 10,
	MaxDefuseTime = 60,
	DefenderSetupTime = 60,
	MinDefenderSetupTime = 10,
	MaxDefenderSetupTime = 120,
	Def_Bomb_timer = 480,
	Bomb_timer = 0,
	BombMarkers = {},
	EnabledMarkers = {},
	Unfree = true,
	GlobalMsgTime = 1,
	Rdynum = 0,
}
function bombdefual:PostRun()
	self.AllBombs = gameplaystatics.GetAllActorsOfClass('/Game/GroundBranch/Props/Electronics/MilitaryLaptop/BP_Laptop_Usable.BP_Laptop_Usable_C')
	local AllInsertionPoints = gameplaystatics.GetAllActorsOfClass('GroundBranch.GBInsertionPoint')
	if #AllInsertionPoints > 2 then
		local GroupedInsertionPoints = {}
		
		for i, InsertionPoint in ipairs(AllInsertionPoints) do
			if #actor.GetTags(InsertionPoint) > 1 then
				local Group = actor.GetTag(InsertionPoint, 1)
				if GroupedInsertionPoints[Group] == nil then
					GroupedInsertionPoints[Group] = {}
					self.NumInsertionPointGroups = self.NumInsertionPointGroups + 1
				end
				table.insert(GroupedInsertionPoints[Group], InsertionPoint)
			end
		end

		if self.NumInsertionPointGroups > 1 then
			self.InsertionPoints = GroupedInsertionPoints
		else
			self.InsertionPoints = AllInsertionPoints
		end
	else
		self.InsertionPoints = AllInsertionPoints
		for i, InsertionPoint in ipairs(self.InsertionPoints) do
			if actor.GetTeamId(InsertionPoint) ~= 255 then
				-- Disables insertion point randomisation.
				self.bFixedInsertionPoints = true
				break
			end
		end
	end

	gamemode.AddStringTable("BombDefusal")
	gamemode.AddGameRule("UseReadyRoom")
	gamemode.AddGameRule("UseRounds")
	gamemode.AddPlayerTeam(self.BlueTeamId, self.BlueTeamTag, self.BlueTeamLoadoutName);
	gamemode.AddPlayerTeam(self.RedTeamId, self.RedTeamTag, self.RedTeamLoadoutName);
	gamemode.AddGameObjective(2, "BombsExploded", 1)
	gamemode.AddGameObjective(2, "EliminateBlue", 2)
	gamemode.AddGameObjective(1, "DefuseAllBombs", 1)
	gamemode.AddGameSetting("roundtime", 3, 30, 1, 8);
	-- gamemode.AddGameSetting("defusetime", 10, 60, 10, 10);
	-- gamemode.AddGameSetting("bombcount", 1, self.MaxBomb_Count, 1, 2); 
	--gamemode.AddGameSetting("defendersetuptime", self.MinDefenderSetupTime,self.MaxDefenderSetupTime, 10, 60); 
	gamemode.SetRoundStage("waitingforready")
	gamemode.AddGameRule("useteamrestrictions=1")
	gamemode.AddGameRule("SpectateFreeCam")
	gamemode.AddGameRule("SpectateEnemies")
end

function bombdefual:OnProcessCommand(Command, Params)
	-- Command = string.lower(Command)
	-- if Command == "defusetime" then
	-- 	if Params ~= nil then
	-- 		self.DefuseTime = math.max(tonumber(Params), self.MinDefuseTime)
	-- 		self.DefuseTime = math.min(self.DefuseTime, self.MaxDefuseTime)
	-- 	end
	-- elseif Command == "bombcount" then
	-- 	if Params ~= nil then
	-- 		self.Bomb_Count = math.max(tonumber(Params), 1)
	-- 		self.Bomb_Count = math.min(self.Bomb_Count, self.MaxBomb_Count)
	-- 		timer.Set(self, "OnRestartObjectives", 0.02, false)
	-- 	end
	-- end
	-- elseif Command == "defendersetuptime" then
	-- 	if Params ~= nil then
	-- 		self.DefenderSetupTime = math.max(tonumber(Params), self.MinDefenderSetupTime)
	-- 		self.DefenderSetupTime = math.min(self.DefenderSetupTime, self.MaxDefenderSetupTime)
	-- 	end
	-- end

end

function bombdefual:PlayerEnteredPlayArea(PlayerState)
	okee = player.GetInventory(PlayerState)
	print(okee)
	for i=1, #okee do
		print(" DDDD")
		print(PlayerState, i)
	end
	FreezeTime = self.DefenderSetupTime + gamemode.GetRoundStageTime()-1
	if actor.GetTeamId(PlayerState) == 1 then
		player.FreezePlayer(PlayerState, FreezeTime)
		player.ShowGameMessage(PlayerState, "Wait for RED setup...", FreezeTime)
	elseif actor.GetTeamId(PlayerState) == 2 then
		local charStart = self.Char_Start
		print(#self.EnabledMarkers)
		for i = 1, #self.EnabledMarkers do
			player.ShowWorldPrompt(PlayerState, actor.GetLocation(self.EnabledMarkers[i]), "Bomb"..string.char(charStart), FreezeTime)
			charStart = charStart + 1
		end
		player.ShowGameMessage(PlayerState, "SETUP STAGE", FreezeTime)
	end
	if self.Unfree == true then
		timer.Set(self, "Unfreeze", FreezeTime, false);
		self.Unfree = false
	end
end
function bombdefual:GetMinSec()
	local time_full = gamemode.GetRoundStageTime()
	local time_minutes  = math.floor(time_full / 60)
	str_min = ""
	str_sec = ""
	if time_minutes < 10 then
		str_min = "0"..tostring(time_minutes)
	else
		str_min = tostring(time_minutes)
	end

    local time_seconds  = math.floor(time_full - time_minutes*60)
	if time_seconds < 10 then
		str_sec = "0"..tostring(time_seconds)
	else
		str_sec = tostring(time_seconds)
	end
	return str_min..":"..str_sec
end
function bombdefual:Unfreeze()
	local BluePlayers = gamemode.GetPlayerList("Lives", self.BlueTeamId, true, 1, false)
	local RedPlayers = gamemode.GetPlayerList("Lives", self.RedTeamId, true, 1, false)
	txt = self.GetMinSec()
	for i = 1, #BluePlayers do
		txt2 = tostring(self.Bomb_Count)
		player.ShowGameMessage(BluePlayers[i], "Find And Defuse All Bombs! There are "..txt2.." Bombs. They will explode in "..txt, 5)	
	end
	for i = 1, #RedPlayers do
		player.ShowGameMessage(RedPlayers[i], "Protect all bombs for "..txt.." or kill all enemies!", 5)	
	end
end
function bombdefual:PlayerInsertionPointChanged(PlayerState, InsertionPoint)
	if InsertionPoint == nil then
		timer.Set(self, "CheckReadyDownTimer", 0.1, false);
	else
		timer.Set(self, "CheckReadyUpTimer", 0.25, false);
	end
end

function bombdefual:PlayerWantsToEnterPlayChanged(PlayerState, WantsToEnterPlay)
	if not WantsToEnterPlay then
		timer.Set(self, "CheckReadyDownTimer", 0.1, false);
	elseif gamemode.GetRoundStage() == "PreRoundWait" and gamemode.PrepLatecomer(PlayerState) then
		gamemode.EnterPlayArea(PlayerState)
	end
end

function bombdefual:CheckReadyUpTimer()
	if gamemode.GetRoundStage() == "WaitingForReady" or gamemode.GetRoundStage() == "ReadyCountdown" then
		local ReadyPlayerTeamCounts = gamemode.GetReadyPlayerTeamCounts(false)
		local BlueReady = ReadyPlayerTeamCounts[self.BlueTeamId]
		local RedReady = ReadyPlayerTeamCounts[self.RedTeamId]
		gamemode.BroadcastGameMessage("B ["..BlueReady.."]                 |                 ["..RedReady.."] R", self.GlobalMsgTime)
		if BlueReady > self.Rdynum or RedReady > self.Rdynum then
			if BlueReady + RedReady >= gamemode.GetPlayerCount(true) then
				gamemode.SetRoundStage("PreRoundWait")
			else
				gamemode.SetRoundStage("ReadyCountdown")
			end
		end
	end
end

function bombdefual:CheckReadyDownTimer()
	if gamemode.GetRoundStage() == "ReadyCountdown" then
		local ReadyPlayerTeamCounts = gamemode.GetReadyPlayerTeamCounts(false)
		local BlueReady = ReadyPlayerTeamCounts[self.BlueTeamId]
		local RedReady = ReadyPlayerTeamCounts[self.RedTeamId]
		if BlueReady < 1 or RedReady < 1 then
			gamemode.BroadcastGameMessage("GAME CANCELED, RESTARTING BOMB LOCATIONS...", self.GlobalMsgTime)
			gamemode.SetRoundStage("WaitingForReady")
		end
	end
end

function bombdefual:OnRoundStageSet(RoundStage)
	if RoundStage == "WaitingForReady" then
		if not self.bFixedInsertionPoints then
			if self.NumInsertionPointGroups > 1 then
				self:RandomiseInsertionPointGroups()
			else
				self:RandomiseInsertionPoints(self.InsertionPoints)
			end
		end
		timer.Set(self, "OnRestartObjectives", 0.1, false)
	end
	if RoundStage == "PostRoundWait" then
		local ok = gameplaystatics.GetAllActorsWithTag(gamemode.GetScript().BombTag)
        if  gamemode.GetRoundStageTime() <= 0 and #ok > 0 then
			gamemode.AddGameStat("Result=Team2")
			gamemode.AddGameStat("Summary=Bombs Exploded")
			gamemode.AddGameStat("CompleteObjectives=BombsExploded")
		end
        else if ok == nil or #ok < 1 then
			gamemode.AddGameStat("Result=Team1")
			gamemode.AddGameStat("Summary=BlueFor Defused All Bombs")
			gamemode.AddGameStat("CompleteObjectives=DefuseAllBombs")
        end
    end
		
end

function bombdefual:OnRestartObjectives()
	self.Unfree = true
	self.EnabledMarkers = {}
	math.randomseed(os.time())
	self.Bomb_timer = self.Def_Bomb_timer + self.DefenderSetupTime
	for i = 1, #self.AllBombs do
		actor.RemoveTag(self.AllBombs[i], self.BombTag)
		actor.SetActive(self.AllBombs[i], false)
	end
	for i = 1, self.Bomb_Count do
		Item = nil
		check = true
		while check == true do
			Item = self.AllBombs[math.random(#self.AllBombs)];
			check = false
			if actor.HasTag(Item, self.BombTag) then
				check = true
			end
		end
		actor.AddTag(Item, self.BombTag)
		actor.SetActive(Item, true)
		self.EnabledMarkers[i] = Item
	end

end

function bombdefual:OnCharacterDied(Character, CharacterController, KillerController)
	if gamemode.GetRoundStage() == "PreRoundWait" or gamemode.GetRoundStage() == "InProgress" then
		if CharacterController ~= nil then
			player.SetLives(CharacterController, player.GetLives(CharacterController) - 1)
			timer.Set(self, "CheckEndRoundTimer", 1.0, false);
		end
	end
end

function bombdefual:CheckEndRoundTimer()
	local BluePlayers = gamemode.GetPlayerList("Lives", self.BlueTeamId, true, 1, false)
	local ok = gameplaystatics.GetAllActorsWithTag(gamemode.GetScript().BombTag)
	if #BluePlayers == 0 and #ok > 0 then
		gamemode.AddGameStat("Result=Team2")
		gamemode.AddGameStat("Summary=BlueEliminated")
		gamemode.AddGameStat("CompleteObjectives=EliminateBlue")
		gamemode.SetRoundStage("PostRoundWait")
	end
end

function bombdefual:RandomiseInsertionPointGroups()
	local NewGroupIndex = self.PrevGroupIndex

	while (NewGroupIndex == self.PrevGroupIndex) do
		NewGroupIndex = umath.random(self.NumInsertionPointGroups)
	end

	self.PrevGroupIndex = NewGroupIndex
	
	local GroupIndex = 0
	
	for Key, Value in pairs(self.InsertionPoints) do
		GroupIndex = GroupIndex + 1
		if GroupIndex == NewGroupIndex then
			self:RandomiseInsertionPoints(Value)
		else
			for i = #Value, 1, -1 do
				actor.SetActive(Value[i], false)
				actor.SetTeamId(Value[i], 255)
			end
		end
	end
end

function bombdefual:RandomiseInsertionPoints(TargetInsertionPoints)
	local ShuffledInsertionPoints = {}

	if #TargetInsertionPoints < 2 then
		print("Error: #TargetInsertionPoints < 2")
		return
	end

	local BlueIndex = umath.random(#TargetInsertionPoints)
	local RedIndex = BlueIndex + umath.random(#TargetInsertionPoints - 1)
	if RedIndex > #TargetInsertionPoints then
		RedIndex = RedIndex - #TargetInsertionPoints
	end

	for i, InsertionPoint in ipairs(TargetInsertionPoints) do
		if i == BlueIndex then
			actor.SetActive(InsertionPoint, true)
			actor.SetTeamId(InsertionPoint, self.BlueTeamId)
		elseif i == RedIndex then
			actor.SetActive(InsertionPoint, true)
			actor.SetTeamId(InsertionPoint, self.RedTeamId)
		else
			actor.SetActive(InsertionPoint, false)
			actor.SetTeamId(InsertionPoint, 255)
		end
	end
end

function bombdefual:ShouldCheckForTeamKills()
	if gamemode.GetRoundStage() == "InProgress" then
		return true
	end
	return false
end

function bombdefual:PlayerCanEnterPlayArea(PlayerState)
	if player.GetInsertionPoint(PlayerState) ~= nil then
		return true
	end
	return false
end

function bombdefual:LogOut(Exiting)
	if gamemode.GetRoundStage() == "PreRoundWait" or gamemode.GetRoundStage() == "InProgress" then
		timer.Set(self, "CheckEndRoundTimer", 1.0, false)
	end
	
end

return bombdefual