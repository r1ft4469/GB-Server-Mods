local kingofthehill = {
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
	ExtractionPoints = {},
	ExtractionPointMarkers = {},
	ExtractionPointIndex = nil,
	TeamExfil = false,
}

function kingofthehill:PostRun()
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
		self.ExtractionPointMarkers[i] = gamemode.AddObjectiveMarker(Location, 1, "ExtractionPoint", false)
		self.ExtractionPointMarkers[i] = gamemode.AddObjectiveMarker(Location, 2, "ExtractionPoint", false)
	end

	gamemode.AddStringTable("kingofthehill")
	gamemode.AddGameRule("UseReadyRoom")
	gamemode.AddGameRule("UseRounds")
	gamemode.AddPlayerTeam(self.BlueTeamId, self.BlueTeamTag, self.BlueTeamLoadoutName);
	gamemode.AddPlayerTeam(self.RedTeamId, self.RedTeamTag, self.RedTeamLoadoutName);
	gamemode.AddGameObjective(1, "CaptureAndHoldObj", 1)
	gamemode.AddGameObjective(2, "CaptureAndHoldObj", 1)
	gamemode.AddGameSetting("roundtime", 5, 30, 5, 10);
	gamemode.SetRoundStage("WaitingForReady")
end

function kingofthehill:PlayerInsertionPointChanged(PlayerState, InsertionPoint)
	if InsertionPoint == nil then
		timer.Set(self, "CheckReadyDownTimer", 0.1, false);
	else
		timer.Set(self, "CheckReadyUpTimer", 0.25, false);
	end
end

function kingofthehill:PlayerWantsToEnterPlayChanged(PlayerState, WantsToEnterPlay)
	if not WantsToEnterPlay then
		timer.Set(self, "CheckReadyDownTimer", 0.1, false);
	elseif gamemode.GetRoundStage() == "PreRoundWait" and gamemode.PrepLatecomer(PlayerState) then
		gamemode.EnterPlayArea(PlayerState)
	end
end

function kingofthehill:CheckReadyUpTimer()
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

function kingofthehill:OnGameTriggerBeginOverlap(GameTrigger, Character)
	if self.ExtractionPoints ~= nil then
		if self.ExtractionPointIndex ~= nil then
			local Overlaps = actor.GetOverlaps(self.ExtractionPoints[self.ExtractionPointIndex], 'GroundBranch.GBCharacter')
			local LivingPlayers = gamemode.GetPlayerList("Lives", 255, true, 0, false)

			for i = 1, #LivingPlayers do
				local LivingCharacter = player.GetCharacter(LivingPlayers[i])
				for j = 1, #Overlaps do
					if Overlaps[j] == LivingCharacter then
						timer.Set(self, "CaptureTime", 1.0, true)
					end
				end
			end
		end
	end
end

function kingofthehill:CaptureTime()
	if gamemode.GetRoundStage() == "InProgress" or gamemode.GetRoundStage() == "RedCapturing" or gamemode.GetRoundStage() == "BlueCapturing" then
		if self.ExtractionPoints ~= nil then
			if self.ExtractionPointIndex ~= nil then
				local Overlaps = actor.GetOverlaps(self.ExtractionPoints[self.ExtractionPointIndex], 'GroundBranch.GBCharacter')
				local bExfiltratedBlue = false
				local bExfiltratedRed = false

				local LivingPlayersBlue = gamemode.GetPlayerList("Lives", 1, true, 1, false)
				for i = 1, #LivingPlayersBlue do
					local LivingCharacterBlue = player.GetCharacter(LivingPlayersBlue[i])
					bExfiltratedBlue = false
					for j = 1, #Overlaps do
						if Overlaps[j] == LivingCharacterBlue then
							bExfiltratedBlue = true
							break
						end
					end
				end
		
				local LivingPlayersRed = gamemode.GetPlayerList("Lives", 2, true, 1, false)
				for i = 1, #LivingPlayersRed do
					local LivingCharacterRed = player.GetCharacter(LivingPlayersRed[i])
					bExfiltratedRed = false
					for j = 1, #Overlaps do
						if Overlaps[j] == LivingCharacterRed then
							bExfiltratedRed = true
							break
						end
					end
				end

				if not bExfiltratedBlue == bExfiltratedRed then
					if bExfiltratedRed then
						gamemode.SetRoundStage("RedCapturing")
						timer.Set(self, "CheckCaptureTimer", 30.0, false)
					elseif bExfiltratedBlue then
						gamemode.SetRoundStage("BlueCapturing")
						timer.Set(self, "CheckCaptureTimer", 30.0, false)
					end
				else
					gamemode.SetRoundStage("InProgress")
					timer.Clear(self, "CaptureTime")
					timer.Clear(self, "CheckCaptureTimer")
				end
			end
			timer.Clear(self, "CaptureTime")
		end
	end
end

function kingofthehill:CheckCaptureTimer()
	if gamemode.GetRoundStage() == "InProgress" or gamemode.GetRoundStage() == "RedCapturing" or gamemode.GetRoundStage() == "BlueCapturing" then
		if self.ExtractionPoints ~= nil then
			if self.ExtractionPointIndex ~= nil then
				local Overlaps = actor.GetOverlaps(self.ExtractionPoints[self.ExtractionPointIndex], 'GroundBranch.GBCharacter')
				local bExfiltratedBlue = false
				local bExfiltratedRed = false

				local LivingPlayersBlue = gamemode.GetPlayerList("Lives", 1, true, 1, false)
				for i = 1, #LivingPlayersBlue do
					local LivingCharacterBlue = player.GetCharacter(LivingPlayersBlue[i])
					bExfiltratedBlue = false
					for j = 1, #Overlaps do
						if Overlaps[j] == LivingCharacterBlue then
							bExfiltratedBlue = true
							break
						end
					end
				end
		
				local LivingPlayersRed = gamemode.GetPlayerList("Lives", 2, true, 1, false)
				for i = 1, #LivingPlayersRed do
					local LivingCharacterRed = player.GetCharacter(LivingPlayersRed[i])
					bExfiltratedRed = false
					for j = 1, #Overlaps do
						if Overlaps[j] == LivingCharacterRed then
							bExfiltratedRed = true
							break
						end
					end
				end

				if not bExfiltratedBlue == bExfiltratedRed then
					if bExfiltratedRed then
						timer.Clear(self, "CheckCaptureTimer")
						gamemode.AddGameStat("Result=Team2")
						gamemode.AddGameStat("Summary=CapturedObj")
						gamemode.AddGameStat("CompleteObjectives=CaptureAndHoldObj")
						gamemode.SetRoundStage("PostRoundWait")
					elseif bExfiltratedBlue then
						timer.Clear(self, "CheckCaptureTimer")
						gamemode.AddGameStat("Result=Team1")
						gamemode.AddGameStat("Summary=CapturedObj")
						gamemode.AddGameStat("CompleteObjectives=CaptureAndHoldObj")
						gamemode.SetRoundStage("PostRoundWait")
					end
				else
					timer.Clear(self, "CaptureTime")
					gamemode.SetRoundStage("InProgress")
				end	
				timer.Clear(self, "CheckCaptureTimer")
			end
		end
	end
end

function kingofthehill:CheckReadyDownTimer()
	if gamemode.GetRoundStage() == "ReadyCountdown" then
		local ReadyPlayerTeamCounts = gamemode.GetReadyPlayerTeamCounts(false)
		local BlueReady = ReadyPlayerTeamCounts[self.BlueTeamId]
		local RedReady = ReadyPlayerTeamCounts[self.RedTeamId]
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
			actor.SetActive(self.ExtractionPointMarkers[i], bActive)
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
	if gamemode.GetRoundStage() == "PreRoundWait" or gamemode.GetRoundStage() == "InProgress" then
		if CharacterController ~= nil then
			player.SetLives(CharacterController, player.GetLives(CharacterController) - 1)
			timer.Set(self, "CheckEndRoundTimer", 1.0, false);
		end
	end
end

function kingofthehill:CheckEndRoundTimer()
	local BluePlayers = gamemode.GetPlayerList("Lives", self.BlueTeamId, true, 1, false)
	local RedPlayers = gamemode.GetPlayerList("Lives", self.RedTeamId, true, 1, false)
	
	if #BluePlayers > 0 and #RedPlayers == 0 then
		timer.Clear(self, "CheckCaptureTimer")
		gamemode.AddGameStat("Result=Team1")
		gamemode.AddGameStat("Summary=RedEliminated")
		gamemode.AddGameStat("CompleteObjectives=EliminateBlue")
		gamemode.SetRoundStage("PostRoundWait")
	elseif #BluePlayers == 0 and #RedPlayers > 0 then
		timer.Clear(self, "CheckCaptureTimer")
		gamemode.AddGameStat("Result=Team2")
		gamemode.AddGameStat("Summary=BlueEliminated")
		gamemode.AddGameStat("CompleteObjectives=EliminateRed")
		gamemode.SetRoundStage("PostRoundWait")
	elseif #BluePlayers == 0 and #RedPlayers == 0 then
		timer.Clear(self, "CheckCaptureTimer")
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

function kingofthehill:ShouldCheckForTeamKills()
	if gamemode.GetRoundStage() == "InProgress" then
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
	if gamemode.GetRoundStage() == "PreRoundWait" or gamemode.GetRoundStage() == "InProgress" then
		timer.Set(self, "CheckEndRoundTimer", 1.0, false);
	end
end

return kingofthehill