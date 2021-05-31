local kingofthehill = {
	UseReadyRoom = true,
	UseRounds = true,
	StringTables = { "KingOfTheHill" },
	PlayerTeams = {
		Blue = {
			TeamId = 1,
			Loadout = "Blue",
		},
		Red = {
			TeamId = 2,
			Loadout = "Red",
		},
	},
	Settings = {
		RoundTime = {
			Min = 5,
			Max = 30,
			Value = 10,
		},
		AutoSwap = {
			Min = 0,
			Max = 1,
			Value = 1,
		},
		CaptureTime = {
			Min = 10,
			Max = 3600,
			Value = 60,
		},
	},
	ShowAutoSwapMessage = false,
	ExtractionPoints = {},
	ExtractionPointMarkersBlue = {},
	ExtractionPointMarkersRed = {},
	ExtractionPoint = nil,
	ExtractionPointIndex = nil,
}

function kingofthehill:PreInit()
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

	self.ExtractionPoints = gameplaystatics.GetAllActorsOfClass('/Game/GroundBranch/Props/GameMode/BP_ExtractionPoint.BP_ExtractionPoint_C')
	for i = 1, #self.ExtractionPoints do
		local Location = actor.GetLocation(self.ExtractionPoints[i])
		self.ExtractionPointMarkersRed[i] = gamemode.AddObjectiveMarker(Location, 2, "ExtractionPoint", false)
		self.ExtractionPointMarkersBlue[i] = gamemode.AddObjectiveMarker(Location, 1, "ExtractionPoint", false)
	end
end

function kingofthehill:PostInit()
    gamemode.AddGameObjective(self.PlayerTeams.Blue.TeamId, "CaptureAndHoldExtraction", 1)
	gamemode.AddGameObjective(self.PlayerTeams.Red.TeamId, "CaptureAndHoldExtraction", 1)
end

function kingofthehill:PlayerInsertionPointChanged(PlayerState, InsertionPoint)
	if InsertionPoint == nil then
		timer.Set("CheckReadyDown", self, self.CheckReadyDownTimer, 0.1, false);
	else
		timer.Set("CheckReadyUp", self, self.CheckReadyUpTimer, 0.25, false);
	end
end

function kingofthehill:PlayerReadyStatusChanged(PlayerState, ReadyStatus)
	if ReadyStatus ~= "DeclaredReady" then
		timer.Set("CheckReadyDown", self, self.CheckReadyDownTimer, 0.1, false)
	end
	
	if ReadyStatus == "WaitingToReadyUp" 
	and gamemode.GetRoundStage() == "PreRoundWait" 
	and gamemode.PrepLatecomer(PlayerState) then
		gamemode.EnterPlayArea(PlayerState)
	end
end

function kingofthehill:CheckReadyUpTimer()
	if gamemode.GetRoundStage() == "WaitingForReady" or gamemode.GetRoundStage() == "ReadyCountdown" then
		local ReadyPlayerTeamCounts = gamemode.GetReadyPlayerTeamCounts(true)
		local BlueReady = ReadyPlayerTeamCounts[self.PlayerTeams.Blue.TeamId]
		local RedReady = ReadyPlayerTeamCounts[self.PlayerTeams.Red.TeamId]
		if BlueReady > 0 and RedReady > 0 then
			if BlueReady + RedReady >= gamemode.GetPlayerCount(true) then
				gamemode.SetRoundStage("PreRoundWait")
			else
				gamemode.SetRoundStage("ReadyCountdown")
			end
		end
	end
end

function kingofthehill:CheckReadyDownTimer()
	if gamemode.GetRoundStage() == "ReadyCountdown" then
		local ReadyPlayerTeamCounts = gamemode.GetReadyPlayerTeamCounts(true)
		local BlueReady = ReadyPlayerTeamCounts[self.PlayerTeams.Blue.TeamId]
		local RedReady = ReadyPlayerTeamCounts[self.PlayerTeams.Red.TeamId]
		if BlueReady < 1 or RedReady < 1 then
			gamemode.SetRoundStage("WaitingForReady")
		end
	end
end

function kingofthehill:OnRoundStageSet(RoundStage)
	if RoundStage == "WaitingForReady" then
		timer.ClearAll()
		self.ExtractionPointIndex = umath.random(#self.ExtractionPoints)

		for i = 1, #self.ExtractionPoints do
			local bActive = (i == self.ExtractionPointIndex)
			actor.SetActive(self.ExtractionPoints[i], bActive)
			actor.SetActive(self.ExtractionPointMarkersBlue[i], bActive)
			actor.SetActive(self.ExtractionPointMarkersRed[i], bActive)
			self.ExtractionPoint = self.ExtractionPoints[i]
		end
		if not self.bFixedInsertionPoints then
			if self.NumInsertionPointGroups > 1 then
				self:RandomiseInsertionPointGroups()
			else
				self:RandomiseInsertionPoints(self.InsertionPoints)
			end
		end
	end
end

function kingofthehill:OnCharacterDied(Character, CharacterController, KillerController)
	if gamemode.GetRoundStage() == "PreRoundWait" or gamemode.GetRoundStage() == "Uncontested" or gamemode.GetRoundStage() == "Contested" or gamemode.GetRoundStage() == "InProgress" or gamemode.GetRoundStage() == "RedCapturing" or gamemode.GetRoundStage() == "BlueCapturing" then
		if CharacterController ~= nil then
			player.SetLives(CharacterController, player.GetLives(CharacterController) - 1)
			timer.Set("CheckEndRound", self, self.CheckEndRoundTimer, 1.0, false);
		end
	end
end

function kingofthehill:CheckEndRoundTimer()
	local Overlaps = actor.GetOverlaps(self.ExtractionPoints[self.ExtractionPointIndex], 'GroundBranch.GBCharacter')
	local BluePlayersWithLives = gamemode.GetPlayerListByLives(self.PlayerTeams.Blue.TeamId, 1, false)
	local RedPlayersWithLives = gamemode.GetPlayerListByLives(self.PlayerTeams.Red.TeamId, 1, false)
	local bBLivingOverlap = false
	local bRLivingOverlap = false
	for i = 1, #BluePlayersWithLives do
		local PlayerCharacter = player.GetCharacter(BluePlayersWithLives[i])
		if PlayerCharacter ~= nil then
			for j = 1, #Overlaps do
				if Overlaps[j] == PlayerCharacter then
					bBLivingOverlap = true
					break
				end
			end
		end
	end
	for i = 1, #RedPlayersWithLives do
		local PlayerCharacter = player.GetCharacter(RedPlayersWithLives[i])
		if PlayerCharacter ~= nil then
			for j = 1, #Overlaps do
				if Overlaps[j] == PlayerCharacter then
					bRLivingOverlap = true
					break
				end
			end
		end
	end
	if bBLivingOverlap or bRLivingOverlap then
		if not bRLivingOverlap == bBLivingOverlap then
			if bRLivingOverlap then
				gamemode.SetRoundStage("RedCapturing")
				timer.Set("CheckCaptureTimer", self, self.CheckCaptureTimer, self.Settings.CaptureTime.Value, false)
			elseif bBLivingOverlap then
				gamemode.SetRoundStage("BlueCapturing")
				timer.Set("CheckCaptureTimer", self, self.CheckCaptureTimer, self.Settings.CaptureTime.Value, false)
			end
		else
			timer.Clear(self, "CheckCaptureTimer")
			gamemode.SetRoundStage("Contested")
		end
	else
		timer.Clear(self, "CheckCaptureTimer")
		gamemode.SetRoundStage("Uncontested")
	end
	if #BluePlayersWithLives > 0 and #RedPlayersWithLives == 0 then
		gamemode.AddGameStat("Result=Team1")
		gamemode.AddGameStat("Summary=RedEliminated")
		gamemode.AddGameStat("CompleteObjectives=EliminateBlue")
		gamemode.SetRoundStage("PostRoundWait")
	elseif #BluePlayersWithLives == 0 and #RedPlayersWithLives > 0 then
		gamemode.AddGameStat("Result=Team2")
		gamemode.AddGameStat("Summary=BlueEliminated")
		gamemode.AddGameStat("CompleteObjectives=EliminateRed")
		gamemode.SetRoundStage("PostRoundWait")
	elseif #BluePlayersWithLives == 0 and #RedPlayersWithLives == 0 then
		gamemode.AddGameStat("Result=None")
		gamemode.AddGameStat("Summary=BothEliminated")
		gamemode.SetRoundStage("PostRoundWait")
	end
end

function kingofthehill:RandomiseInsertionPointGroups()
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

function kingofthehill:RandomiseInsertionPoints(TargetInsertionPoints)
	if #TargetInsertionPoints < 2 then
		print("Error: #TargetInsertionPoints < 2")
		return
	end

	local ShuffledInsertionPoints = {}

	local BlueIndex = umath.random(#TargetInsertionPoints)
	local RedIndex = BlueIndex + umath.random(#TargetInsertionPoints - 1)
	if RedIndex > #TargetInsertionPoints then
		RedIndex = RedIndex - #TargetInsertionPoints
	end

	for i, InsertionPoint in ipairs(TargetInsertionPoints) do
		if i == BlueIndex then
			actor.SetActive(InsertionPoint, true)
			actor.SetTeamId(InsertionPoint, self.PlayerTeams.Blue.TeamId)
		elseif i == RedIndex then
			actor.SetActive(InsertionPoint, true)
			actor.SetTeamId(InsertionPoint, self.PlayerTeams.Red.TeamId)
		else
			actor.SetActive(InsertionPoint, false)
			actor.SetTeamId(InsertionPoint, 255)
		end
	end
end

function kingofthehill:ShouldCheckForTeamKills()
	if gamemode.GetRoundStage() == "Contested" or gamemode.GetRoundStage() == "Uncontested" or gamemode.GetRoundStage() == "InProgress" or gamemode.GetRoundStage() == "RedCapturing" or gamemode.GetRoundStage() == "BlueCapturing" then
		return true
	end
	return false
end

function kingofthehill:PlayerCanEnterPlayArea(PlayerState)
	if player.GetInsertionPoint(PlayerState) ~= nil then
		return true
	end
	return false
end

function kingofthehill:LogOut(Exiting)
	if gamemode.GetRoundStage() == "PreRoundWait" or gamemode.GetRoundStage() == "Uncontested" or gamemode.GetRoundStage() == "Contested" or gamemode.GetRoundStage() == "InProgress"or gamemode.GetRoundStage() == "RedCapturing" or gamemode.GetRoundStage() == "BlueCapturing" then
		timer.Set("CheckEndRound", self, self.CheckEndRoundTimer, 1.0, false);
	end
end

function kingofthehill:OnGameTriggerBeginOverlap(GameTrigger, Character)
	if gamemode.GetRoundStage() == "InProgress" or gamemode.GetRoundStage() == "Uncontested" or gamemode.GetRoundStage() == "Contested" or gamemode.GetRoundStage() == "RedCapturing" or gamemode.GetRoundStage() == "BlueCapturing" then
		local Overlaps = actor.GetOverlaps(self.ExtractionPoints[self.ExtractionPointIndex], 'GroundBranch.GBCharacter')
		local BluePlayersWithLives = gamemode.GetPlayerListByLives(self.PlayerTeams.Blue.TeamId, 1, false)
		local RedPlayersWithLives = gamemode.GetPlayerListByLives(self.PlayerTeams.Red.TeamId, 1, false)
		local bBLivingOverlap = false
		local bRLivingOverlap = false
		for i = 1, #BluePlayersWithLives do
			local PlayerCharacter = player.GetCharacter(BluePlayersWithLives[i])
			if PlayerCharacter ~= nil then
				for j = 1, #Overlaps do
					if Overlaps[j] == PlayerCharacter then
						bBLivingOverlap = true
						break
					end
				end
			end
		end
		for i = 1, #RedPlayersWithLives do
			local PlayerCharacter = player.GetCharacter(RedPlayersWithLives[i])
			if PlayerCharacter ~= nil then
				for j = 1, #Overlaps do
					if Overlaps[j] == PlayerCharacter then
						bRLivingOverlap = true
						break
					end
				end
			end
		end
		if bBLivingOverlap or bRLivingOverlap then
			if not bRLivingOverlap == bBLivingOverlap then
				if bRLivingOverlap then
					gamemode.SetRoundStage("RedCapturing")
					timer.Set("CheckCaptureTimer", self, self.CheckCaptureTimer, self.Settings.CaptureTime.Value, false)
				elseif bBLivingOverlap then
					gamemode.SetRoundStage("BlueCapturing")
					timer.Set("CheckCaptureTimer", self, self.CheckCaptureTimer, self.Settings.CaptureTime.Value, false)
				end
			else
				timer.Clear(self, "CheckCaptureTimer")
				gamemode.SetRoundStage("Contested")
			end
		else
			timer.Clear(self, "CheckCaptureTimer")
			gamemode.SetRoundStage("Uncontested")
		end
	end
end

function kingofthehill:OnGameTriggerEndOverlap(GameTrigger, Character)
	if gamemode.GetRoundStage() == "InProgress" or gamemode.GetRoundStage() == "Uncontested" or gamemode.GetRoundStage() == "Contested" or gamemode.GetRoundStage() == "RedCapturing" or gamemode.GetRoundStage() == "BlueCapturing" then
		local Overlaps = actor.GetOverlaps(self.ExtractionPoints[self.ExtractionPointIndex], 'GroundBranch.GBCharacter')
		local BluePlayersWithLives = gamemode.GetPlayerListByLives(self.PlayerTeams.Blue.TeamId, 1, false)
		local RedPlayersWithLives = gamemode.GetPlayerListByLives(self.PlayerTeams.Red.TeamId, 1, false)
		local bBLivingOverlap = false
		local bRLivingOverlap = false
		for i = 1, #BluePlayersWithLives do
			local PlayerCharacter = player.GetCharacter(BluePlayersWithLives[i])
			if PlayerCharacter ~= nil then
				for j = 1, #Overlaps do
					if Overlaps[j] == PlayerCharacter then
						bBLivingOverlap = true
						break
					end
				end
			end
		end
		for i = 1, #RedPlayersWithLives do
			local PlayerCharacter = player.GetCharacter(RedPlayersWithLives[i])
			if PlayerCharacter ~= nil then
				for j = 1, #Overlaps do
					if Overlaps[j] == PlayerCharacter then
						bRLivingOverlap = true
						break
					end
				end
			end
		end
		if bBLivingOverlap or bRLivingOverlap then
			if not bRLivingOverlap == bBLivingOverlap then
				if bRLivingOverlap then
					gamemode.SetRoundStage("RedCapturing")
					timer.Set("CheckCaptureTimer", self, self.CheckCaptureTimer, self.Settings.CaptureTime.Value, false)
				elseif bBLivingOverlap then
					gamemode.SetRoundStage("BlueCapturing")
					timer.Set("CheckCaptureTimer", self, self.CheckCaptureTimer, self.Settings.CaptureTime.Value, false)
				end
			else
				timer.Clear(self, "CheckCaptureTimer")
				gamemode.SetRoundStage("Contested")
			end
		else
			timer.Clear(self, "CheckCaptureTimer")
			gamemode.SetRoundStage("Uncontested")
		end
	end
end

function kingofthehill:CheckCaptureTimer()
	local Overlaps = actor.GetOverlaps(self.ExtractionPoints[self.ExtractionPointIndex], 'GroundBranch.GBCharacter')
	local BluePlayersWithLives = gamemode.GetPlayerListByLives(self.PlayerTeams.Blue.TeamId, 1, false)
	local RedPlayersWithLives = gamemode.GetPlayerListByLives(self.PlayerTeams.Red.TeamId, 1, false)
	local bBLivingOverlap = false
	local bRLivingOverlap = false
	for i = 1, #BluePlayersWithLives do
		local PlayerCharacter = player.GetCharacter(BluePlayersWithLives[i])
		if PlayerCharacter ~= nil then
			for j = 1, #Overlaps do
				if Overlaps[j] == PlayerCharacter then
					bBLivingOverlap = true
					break
				end
			end
		end
	end
	for i = 1, #RedPlayersWithLives do
		local PlayerCharacter = player.GetCharacter(RedPlayersWithLives[i])
		if PlayerCharacter ~= nil then
			for j = 1, #Overlaps do
				if Overlaps[j] == PlayerCharacter then
					bRLivingOverlap = true
					break
				end
			end
		end
	end
	if not bRLivingOverlap == bBLivingOverlap then
		if bRLivingOverlap then
			timer.Clear(self, "CheckCaptureTimer")
			gamemode.AddGameStat("Result=Team2")
			gamemode.AddGameStat("Summary=CapturedObj")
			gamemode.AddGameStat("CompleteObjectives=CaptureAndHoldExtractionForSixtySeconds")
			gamemode.SetRoundStage("PostRoundWait")
		elseif bBLivingOverlap then
			timer.Clear(self, "CheckCaptureTimer")
			gamemode.AddGameStat("Result=Team1")
			gamemode.AddGameStat("Summary=CapturedObj")
			gamemode.AddGameStat("CompleteObjectives=CaptureAndHoldExtractionForSixtySeconds")
			gamemode.SetRoundStage("PostRoundWait")
		end
	else
		if bRLivingOverlap or bBLivingOverlap then
			gamemode.SetRoundStage("Contested")
		else
			gamemode.SetRoundStage("Uncontested")
		end
	end
	timer.Clear(self, "CheckCaptureTimer")
end

return kingofthehill