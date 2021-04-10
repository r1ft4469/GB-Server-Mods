local teamelimination = {
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
	ExtractionPoint = nil,
	ExtractionPointIndex = nil,
	TeamExfil = false,
	RedCaptureCheck = false,
	BlueCaptureCheck = false,
	CaptureTime = 60,
}

function teamelimination:PostRun()
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

	self.RedCaptureCheck = false
	self.BlueCaptureCheck = false


	gamemode.AddStringTable("teamelimination")
	gamemode.AddGameRule("UseReadyRoom")
	gamemode.AddGameRule("UseRounds")
	gamemode.AddPlayerTeam(self.BlueTeamId, self.BlueTeamTag, self.BlueTeamLoadoutName);
	gamemode.AddPlayerTeam(self.RedTeamId, self.RedTeamTag, self.RedTeamLoadoutName);
	gamemode.AddGameObjective(1, "CaptureAndHoldObj", 1)
	gamemode.AddGameObjective(2, "CaptureAndHoldObj", 1)
	gamemode.AddGameSetting("roundtime", 1, 30, 1, 5);
	gamemode.SetRoundStage("WaitingForReady")
end

function teamelimination:PlayerInsertionPointChanged(PlayerState, InsertionPoint)
	if InsertionPoint == nil then
		timer.Set(self, "CheckReadyDownTimer", 0.1, false);
	else
		timer.Set(self, "CheckReadyUpTimer", 0.25, false);
	end
end

function teamelimination:PlayerWantsToEnterPlayChanged(PlayerState, WantsToEnterPlay)
	if not WantsToEnterPlay then
		timer.Set(self, "CheckReadyDownTimer", 0.1, false);
	elseif gamemode.GetRoundStage() == "PreRoundWait" and gamemode.PrepLatecomer(PlayerState) then
		gamemode.EnterPlayArea(PlayerState)
	end
end

function teamelimination:CheckReadyUpTimer()
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

function teamelimination:OnGameTriggerBeginOverlap(GameTrigger, Character)
	if gamemode.GetRoundStage() == "InProgress" or gamemode.GetRoundStage() == "Uncontested" or gamemode.GetRoundStage() == "Contested" or gamemode.GetRoundStage() == "RedCapturing" or gamemode.GetRoundStage() == "BlueCapturing" then
		local Overlaps = actor.GetOverlaps(self.ExtractionPoints[self.ExtractionPointIndex], 'GroundBranch.GBCharacter')
		local LivingPlayers = gamemode.GetPlayerList("Lives", 255, true, 1, false)
		for i = 1, #LivingPlayers do
			local LivingCharacter = player.GetCharacter(LivingPlayers[i])
			for j = 1, #Overlaps do
				if Overlaps[j] == LivingCharacter then
					if actor.GetTeamId(LivingCharacter) == self.BlueTeamId then
						self.BlueCaptureCheck = true
					elseif actor.GetTeamId(LivingCharacter) == self.RedTeamId then
						self.RedCaptureCheck = true
					end
				end
			end
		end
		if self.BlueCaptureCheck or self.RedCaptureCheck then
			if not self.RedCaptureCheck == self.BlueCaptureCheck then
				if self.RedCaptureCheck then
					gamemode.SetRoundStage("RedCapturing")
					timer.Set(self, "CheckCaptureTimer", self.CaptureTime, false)
				elseif self.BlueCaptureCheck then
					gamemode.SetRoundStage("BlueCapturing")
					timer.Set(self, "CheckCaptureTimer", self.CaptureTime, false)
				end
			else
				timer.Clear(self, "CheckCaptureTimer")
				gamemode.SetRoundStage("Contested")
				self.RedCaptureCheck = false
				self.BlueCaptureCheck = false
			end
		else
			timer.Clear(self, "CheckCaptureTimer")
			gamemode.SetRoundStage("Uncontested")
			self.RedCaptureCheck = false
			self.BlueCaptureCheck = false
		end
	end
end

function teamelimination:OnGameTriggerEndOverlap(GameTrigger, Character)
	if gamemode.GetRoundStage() == "InProgress" or gamemode.GetRoundStage() == "Uncontested" or gamemode.GetRoundStage() == "Contested" or gamemode.GetRoundStage() == "RedCapturing" or gamemode.GetRoundStage() == "BlueCapturing" then
		self.RedCaptureCheck = false
		self.BlueCaptureCheck = false
		local Overlaps = actor.GetOverlaps(self.ExtractionPoints[self.ExtractionPointIndex], 'GroundBranch.GBCharacter')
		local LivingPlayers = gamemode.GetPlayerList("Lives", 255, true, 1, false)
		for i = 1, #LivingPlayers do
			local LivingCharacter = player.GetCharacter(LivingPlayers[i])
			for j = 1, #Overlaps do
				if Overlaps[j] == LivingCharacter then
					if actor.GetTeamId(LivingCharacter) == self.BlueTeamId then
						self.BlueCaptureCheck = true
					elseif actor.GetTeamId(LivingCharacter) == self.RedTeamId then
						self.RedCaptureCheck = true
					end
				end
			end
		end
		if self.BlueCaptureCheck or self.RedCaptureCheck then
			if not self.RedCaptureCheck == self.BlueCaptureCheck then
				if self.RedCaptureCheck then
					gamemode.SetRoundStage("RedCapturing")
					timer.Set(self, "CheckCaptureTimer", self.CaptureTime, false)
				elseif self.BlueCaptureCheck then
					gamemode.SetRoundStage("BlueCapturing")
					timer.Set(self, "CheckCaptureTimer", self.CaptureTime, false)
				end
			else
				timer.Clear(self, "CheckCaptureTimer")
				gamemode.SetRoundStage("Contested")
			end
		else
			gamemode.SetRoundStage("Uncontested")
			timer.Clear(self, "CheckCaptureTimer")
		end
	end
end

function teamelimination:CheckCaptureTimer()
	if not self.RedCaptureCheck == self.BlueCaptureCheck then
		if self.RedCaptureCheck then
			timer.Clear(self, "CheckCaptureTimer")
			gamemode.AddGameStat("Result=Team2")
			gamemode.AddGameStat("Summary=CapturedObj")
			gamemode.AddGameStat("CompleteObjectives=CaptureAndHoldObj")
			gamemode.SetRoundStage("PostRoundWait")
		elseif self.BlueCaptureCheck then
			timer.Clear(self, "CheckCaptureTimer")
			gamemode.AddGameStat("Result=Team1")
			gamemode.AddGameStat("Summary=CapturedObj")
			gamemode.AddGameStat("CompleteObjectives=CaptureAndHoldObj")
			gamemode.SetRoundStage("PostRoundWait")
		end
	else
		if self.RedCaptureCheck or self.BlueCaptureCheck then
			gamemode.SetRoundStage("Contested")
		else
			gamemode.SetRoundStage("Uncontested")
		end
		self.RedCaptureCheck = false
		self.BlueCaptureCheck = false
	end
	timer.Clear(self, "CheckCaptureTimer")
end

function teamelimination:CheckReadyDownTimer()
	if gamemode.GetRoundStage() == "ReadyCountdown" then
		local ReadyPlayerTeamCounts = gamemode.GetReadyPlayerTeamCounts(false)
		local BlueReady = ReadyPlayerTeamCounts[self.BlueTeamId]
		local RedReady = ReadyPlayerTeamCounts[self.RedTeamId]
		if BlueReady < 1 or RedReady < 1 then
			gamemode.SetRoundStage("WaitingForReady")
		end
	end
end

function teamelimination:OnRoundStageSet(RoundStage)
	if RoundStage == "WaitingForReady" then
		timer.ClearAll()
		self.RedCaptureCheck = false
		self.BlueCaptureCheck = false
		self.ExtractionPointIndex = umath.random(#self.ExtractionPoints)

		for i = 1, #self.ExtractionPoints do
			local bActive = (i == self.ExtractionPointIndex)
			actor.SetActive(self.ExtractionPoints[i], bActive)
			actor.SetActive(self.ExtractionPointMarkers[i], bActive)
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

function teamelimination:OnCharacterDied(Character, CharacterController, KillerController)
	if gamemode.GetRoundStage() == "PreRoundWait" or gamemode.GetRoundStage() == "Uncontested" or gamemode.GetRoundStage() == "Contested" or gamemode.GetRoundStage() == "InProgress" or gamemode.GetRoundStage() == "RedCapturing" or gamemode.GetRoundStage() == "BlueCapturing" then
		if CharacterController ~= nil then
			player.SetLives(CharacterController, player.GetLives(CharacterController) - 1)
			timer.Set(self, "CheckEndRoundTimer", 1.0, false);
		end
	end
end

function teamelimination:CheckEndRoundTimer()
	local BluePlayers = gamemode.GetPlayerList("Lives", self.BlueTeamId, true, 1, false)
	local RedPlayers = gamemode.GetPlayerList("Lives", self.RedTeamId, true, 1, false)
	local Overlaps = actor.GetOverlaps(self.ExtractionPoints[self.ExtractionPointIndex], 'GroundBranch.GBCharacter')
	local LivingPlayers = gamemode.GetPlayerList("Lives", 255, true, 1, false)
	for i = 1, #LivingPlayers do
		local LivingCharacter = player.GetCharacter(LivingPlayers[i])
		for j = 1, #Overlaps do
			if Overlaps[j] == LivingCharacter then
				if actor.GetTeamId(LivingCharacter) == self.BlueTeamId then
					self.BlueCaptureCheck = true
				elseif actor.GetTeamId(LivingCharacter) == self.RedTeamId then
					self.RedCaptureCheck = true
				end
			end
		end
	end
	if self.BlueCaptureCheck or self.RedCaptureCheck then
		if not self.RedCaptureCheck == self.BlueCaptureCheck then
			if self.RedCaptureCheck then
				gamemode.SetRoundStage("RedCapturing")
				timer.Set(self, "CheckCaptureTimer", self.CaptureTime, false)
			elseif self.BlueCaptureCheck then
				gamemode.SetRoundStage("BlueCapturing")
				timer.Set(self, "CheckCaptureTimer", self.CaptureTime, false)
			end
		else
			timer.Clear(self, "CheckCaptureTimer")
			gamemode.SetRoundStage("Contested")
			self.RedCaptureCheck = false
			self.BlueCaptureCheck = false
		end
	else
		timer.Clear(self, "CheckCaptureTimer")
		gamemode.SetRoundStage("Uncontested")
		self.RedCaptureCheck = false
		self.BlueCaptureCheck = false
	end
	
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

function teamelimination:RandomiseInsertionPointGroups()
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

function teamelimination:RandomiseInsertionPoints(TargetInsertionPoints)
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

function teamelimination:ShouldCheckForTeamKills()
	if gamemode.GetRoundStage() == "Contested" or gamemode.GetRoundStage() == "Uncontested" or gamemode.GetRoundStage() == "InProgress" or gamemode.GetRoundStage() == "RedCapturing" or gamemode.GetRoundStage() == "BlueCapturing" then
		return true
	end
	return false
end

function teamelimination:PlayerCanEnterPlayArea(PlayerState)
	if player.GetInsertionPoint(PlayerState) ~= nil then
		return true
	end
	return false
end

function teamelimination:LogOut(Exiting)
	if gamemode.GetRoundStage() == "PreRoundWait" or gamemode.GetRoundStage() == "Uncontested" or gamemode.GetRoundStage() == "Contested" or gamemode.GetRoundStage() == "InProgress"or gamemode.GetRoundStage() == "RedCapturing" or gamemode.GetRoundStage() == "BlueCapturing" then
		timer.Set(self, "CheckEndRoundTimer", 1.0, false);
	end
end

return teamelimination