local teamdeathmatch = {
	PlayerStarts = {},
	RecentlyUsedPlayerStarts = {},
	MaxRecentlyUsedPlayerStarts = 0,
	TooCloseSq = 1000000,
	BlueTeamId = 1,
	BlueTeamTag = "Blue",
	BlueTeamLoadoutName = "Blue",
	RedTeamId = 2,
	RedTeamTag = "Red",
	RedTeamLoadoutName = "Red",
	RoundResult = "",
	InsertionPoints = {},
	bFixedInsertionPoints = false,
	NumInsertionPointGroups = 0,
	PrevGroupIndex = 0,
	TooCloseSq = 100000,
}

function teamdeathmatch:PostRun()
	self.PlayerStarts = gameplaystatics.GetAllActorsOfClass('GroundBranch.GBPlayerStart')
	self.MaxRecentlyUsedPlayerStarts = #self.PlayerStarts / 2
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

	gamemode.AddStringTable("teamdeathmatch")
	gamemode.AddGameRule("UseReadyRoom")
	gamemode.AddGameRule("UseRounds")
	gamemode.AddPlayerTeam(self.BlueTeamId, self.BlueTeamTag, self.BlueTeamLoadoutName);
	gamemode.AddPlayerTeam(self.RedTeamId, self.RedTeamTag, self.RedTeamLoadoutName);
	gamemode.AddGameObjective(1, "EliminateRed", 1)
	gamemode.AddGameObjective(2, "EliminateBlue", 1)
	gamemode.AddGameSetting("roundtime", 5, 30, 5, 10);
	gamemode.SetRoundStage("WaitingForReady")
end

function teamdeathmatch:PlayerInsertionPointChanged(PlayerState, InsertionPoint)
	if InsertionPoint == nil then
		timer.Set(self, "CheckReadyDownTimer", 0.1, false);
	else
		timer.Set(self, "CheckReadyUpTimer", 0.25, false);
	end
end

function teamdeathmatch:PlayerWantsToEnterPlayChanged(PlayerState, WantsToEnterPlay)
	if not WantsToEnterPlay then
		timer.Set(self, "CheckReadyDownTimer", 0.1, false);
	elseif Request == "join"  then
		gamemode.EnterPlayArea(PlayerState);
	end
end

function teamdeathmatch:CheckReadyUpTimer()
	if gamemode.GetRoundStage() == "WaitingForReady" or gamemode.GetRoundStage() == "ReadyCountdown" then
		local ReadyPlayerTeamCounts = gamemode.GetReadyPlayerTeamCounts(false)
		local BlueReady = ReadyPlayerTeamCounts[self.BlueTeamId]
		local RedReady = ReadyPlayerTeamCounts[self.RedTeamId]
		if BlueReady > 0 and RedReady > 0 then
			if BlueReady + RedReady >= gamemode.GetPlayerCount(true) then
				gamemode.SetRoundStage("PreRoundWait")
			else
				gamemode.SetRoundStage("ReadyCountdown")
			end
		end
	end
end

function teamdeathmatch:CheckReadyDownTimer()
	if gamemode.GetRoundStage() == "ReadyCountdown" then
		local ReadyPlayerTeamCounts = gamemode.GetReadyPlayerTeamCounts(false)
		local BlueReady = ReadyPlayerTeamCounts[self.BlueTeamId]
		local RedReady = ReadyPlayerTeamCounts[self.RedTeamId]
		if BlueReady < 1 or RedReady < 1 then
			gamemode.SetRoundStage("WaitingForReady")
		end
	end
end

function teamdeathmatch:OnRoundStageSet(RoundStage)
	if RoundStage == "WaitingForReady" then
		self:SetupRound()
		if not self.bFixedInsertionPoints then
			if self.NumInsertionPointGroups > 1 then
				self:RandomiseInsertionPointGroups()
			else
				self:RandomiseInsertionPoints(self.InsertionPoints)
			end
		end
	end
end

function teamdeathmatch:SetupRound()
	gamemode.AddGameRule("UseRounds")
end

function teamdeathmatch:OnCharacterDied(Character, CharacterController, KillerController)
	if gamemode.GetRoundStage() == "PreRoundWait" or gamemode.GetRoundStage() == "InProgress" then
		if CharacterController ~= nil then
			player.SetLives(CharacterController, player.GetLives(CharacterController) - 1)
			timer.Set(self, "CheckEndRoundTimer", 0.1, false)
			gamemode.EnterReadyRoom(CharacterController)
		end
	end
end

function teamdeathmatch:PlayerGameModeRequest(PlayerState, Request)
	if PlayerState ~= nil then
		if Request == "join"  then
			local char = player.GetCharacter(PlayerState)
			if player.GetLives(char) <= 0 then
				player.SetLives(char, player.GetLives(char) + 1)
			end
			gamemode.EnterPlayArea(PlayerState)
		end
	end
end

function teamdeathmatch:CheckEndRoundTimer()
	local BluePlayers = gamemode.GetPlayerList("", self.BlueTeamId, true, 1, false)
	local RedPlayers = gamemode.GetPlayerList("", self.RedTeamId, true, 1, false)
	gamemode.AddGameRule("UseRounds")
	if #BluePlayers > 0 and #RedPlayers == 0 then
		gamemode.AddGameStat("Result=Team1")
		gamemode.AddGameStat("Summary=RedEliminated")
		gamemode.AddGameStat("CompleteObjectives=EliminateBlue")
		gamemode.SetRoundStage("PostRoundWait")
	elseif #BluePlayers == 0 and #RedPlayers > 0 then
		gamemode.AddGameStat("Result=Team2")
		gamemode.AddGameStat("Summary=BlueEliminated")
		gamemode.AddGameStat("CompleteObjectives=EliminateRed")
		gamemode.SetRoundStage("PostRoundWait")
	elseif #BluePlayers == 0 and #RedPlayers == 0 then
		gamemode.AddGameStat("Result=None")
		gamemode.AddGameStat("Summary=BothEliminated")
		gamemode.SetRoundStage("PostRoundWait")
	end
	gamemode.RemoveGameRule("UseRounds")
end

function teamdeathmatch:RandomiseInsertionPointGroups()
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

function teamdeathmatch:RandomiseInsertionPoints(TargetInsertionPoints)
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
			actor.SetActive(InsertionPoint, true)
			actor.SetTeamId(InsertionPoint, 255)
		end
	end
end

function teamdeathmatch:ShouldCheckForTeamKills()
	if gamemode.GetRoundStage() == "InProgress" then
		return true
	end
	return false
end

function teamdeathmatch:PlayerCanEnterPlayArea(PlayerState)
	if gamemode.GetRoundStage() == "InProgress" then
		return true
	else
		if player.GetInsertionPoint(PlayerState) ~= nil then
			return true
		end
		return false
	end
end

function teamdeathmatch:WasRecentlyUsed(PlayerStart)
	for i = 1, #self.RecentlyUsedPlayerStarts do
		if self.RecentlyUsedPlayerStarts[i] == PlayerStart then
			return true
		end
	end
	return false
end

function teamdeathmatch:RateStart(PlayerStart, PlayerState)
	local StartLocation = actor.GetLocation(PlayerStart)
	local LivingPlayers = gamemode.GetPlayerList("Lives", 0, true, 0, false)
	local DistScalar = 5000
	local ClosestDistSq = DistScalar * DistScalar
	local ClosestPlayerTeam = nil

	for i = 1, #LivingPlayers do
		local PlayerCharacter = player.GetCharacter(LivingPlayers[i])
		local DistSq = vector.SizeSq(StartLocation - PlayerLocation)
		if DistSq < self.TooCloseSq then
			return -10.0
		end
		
		if DistSq < ClosestDistSq then
			ClosestDistSq = DistSq
			ClosestPlayerTeam = actor.GetTeamId(PlayerCharacter)
		end
	end

	local result = math.sqrt(ClosestDistSq) / DistScalar * umath.random(45.0, 55.0)

	
	if ClosestPlayerTeam == actor.GetTeamId(PlayerState) then
		result  =  result * 4
	end
	
	return math.sqrt(ClosestDistSq) / DistScalar * umath.random(45.0, 55.0)
end

function teamdeathmatch:GetSpawnInfo(PlayerState)
	if gamemode.GetRoundStage() == "InProgress" then
		if not self.bFixedInsertionPoints then
			local StartsToConsider = {}
			local BestStart = nil
			
			for i, PlayerStart in ipairs(self.PlayerStarts) do
				if not self:WasRecentlyUsed(PlayerStart) then
					table.insert(StartsToConsider, PlayerStart)
				end
			end
			
			local BestScore = 0
			
			for i = 1, #StartsToConsider do
				local Score = self:RateStart(StartsToConsider[i], PlayerState)
				if Score > BestScore then
					BestScore = Score
					BestStart = StartsToConsider[i]
				end
			end
			
			if BestStart == nil then
				BestStart = StartsToConsider[umath.random(#StartsToConsider)]
			end
			
			if BestStart ~= nil then
				table.insert(self.RecentlyUsedPlayerStarts, BestStart)
				if #self.RecentlyUsedPlayerStarts > self.MaxRecentlyUsedPlayerStarts then
					table.remove(self.RecentlyUsedPlayerStarts, 1)
				end
			end
			
			return BestStart
		end
	end
end

function teamdeathmatch:LogOut(Exiting)
	if gamemode.GetRoundStage() == "PreRoundWait" or gamemode.GetRoundStage() == "InProgress" then
		timer.Set(self, "CheckEndRoundTimer", 1.0, false);
	end
end

return teamdeathmatch
