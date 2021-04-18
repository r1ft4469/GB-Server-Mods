local uplink = {
	BlueTeamId = 1,
	BlueTeamTag = "Blue",
	BlueTeamLoadoutName = "Blue",
	RedTeamId = 2,
	RedTeamTag = "Red",
	RedTeamLoadoutName = "Red",
	RoundResult = "",
	DefenderInsertionPoints = {},
	DefenderIndex = 0,
	AttackerInsertionPoints = {},
	HostageTag = "Hostage",
	HostageLoadoutName = "Hostage",
	HostageIndex = 0,
	HostageTeamId = 3,
	HostageStarts = {},
	HostageOrigTeamId = 0,
	bFixedInsertionPoints = false,
	DefenderSetupTime = 30,
	MinDefenderSetupTime = 10,
	MaxDefenderSetupTime = 120,
	CaptureTime = 10,
	MinCaptureTime = 1,
	MaxCaptureTime = 60,
	DefendingTeamId = 2,
	AttackingTeamId = 1,
	SpawnProtectionVolumes = {},
	ExtractionPoints = {},
	ExtractionPointMarkersBlue = {},
	ExtractionPointMarkersRed = {},
	ExtractionPoint = nil,
	ExtractionPointIndex = nil,
	AutoSwap = true,
	AutoSwapCount = 0,
}

function uplink:PostRun()
	self.HostageStarts = gameplaystatics.GetAllActorsOfClassWithTag('GroundBranch.GBPlayerStart', self.HostageTag)
	self.SpawnProtectionVolumes = gameplaystatics.GetAllActorsOfClass('GroundBranch.GBSpawnProtectionVolume')
	
	local AllInsertionPoints = gameplaystatics.GetAllActorsOfClass('GroundBranch.GBInsertionPoint')
	local DefenderInsertionPointNames = {}

	for i, InsertionPoint in ipairs(AllInsertionPoints) do
		if actor.HasTag(InsertionPoint, "Defenders") then
			table.insert(self.DefenderInsertionPoints, InsertionPoint)
			table.insert(DefenderInsertionPointNames, gamemode.GetInsertionPointName(InsertionPoint))
		elseif actor.HasTag(InsertionPoint, "Attackers") then
			table.insert(self.AttackerInsertionPoints, InsertionPoint)
		end
	end

	self.ExtractionPoints = gameplaystatics.GetAllActorsOfClass('/Game/GroundBranch/Props/GameMode/BP_ExtractionPoint.BP_ExtractionPoint_C')
	for i = 1, #self.ExtractionPoints do
		local Location = actor.GetLocation(self.ExtractionPoints[i])
		self.ExtractionPointMarkersRed[i] = gamemode.AddObjectiveMarker(Location, 2, "ExtractionPoint", false)
		self.ExtractionPointMarkersBlue[i] = gamemode.AddObjectiveMarker(Location, 1, "ExtractionPoint", false)
	end
	
	if gamemode.HasGameOption("defendersetuptime") then
		self.DefenderSetupTime = math.max(tonumber(gamemode.GetGameOption("defendersetuptime")), self.MinDefenderSetupTime)
		self.DefenderSetupTime = math.min(self.DefenderSetupTime, self.MaxDefenderSetupTime)
	end

	if gamemode.HasGameOption("capturetime") then
		self.CaptureTime = math.max(tonumber(gamemode.GetGameOption("capturetime")), self.MinCaptureTime)
		self.CaptureTime = math.min(self.CaptureTime, self.MaxCaptureTime)
	end

	if gamemode.HasGameOption("autoswap") then
		self.AutoSwap = (tonumber(gamemode.GetGameOption("autoswap")) == 1)
	end

	-- SetupRound() will swap these the first time.
	-- To ensure that we get the right teams intially, set them to the opposite here.
	if self.AutoSwap then
		DefendingTeamId = 1
		AttackingTeamId = 2
	end
	
	gamemode.AddStringTable("Uplink")
	gamemode.AddGameRule("UseReadyRoom")
	gamemode.AddGameRule("UseRounds")
	gamemode.AddPlayerTeam(self.BlueTeamId, self.BlueTeamTag, self.BlueTeamLoadoutName);
	gamemode.AddPlayerTeam(3, self.HostageTag, self.HostageLoadoutName);
	gamemode.AddGameSetting("roundtime", 5, 30, 5, 10);
	gamemode.AddGameSetting("defendersetuptime", self.MinDefenderSetupTime, self.MaxDefenderSetupTime, 10, self.DefenderSetupTime);

	gamemode.SetRoundStage("WaitingForReady")
end

function uplink:PlayerInsertionPointChanged(PlayerState, InsertionPoint)
	if InsertionPoint == nil then
		timer.Set(self, "CheckReadyDownTimer", 0.1, false);
	else
		timer.Set(self, "CheckReadyUpTimer", 0.25, false);
	end
end

function uplink:GetSpawnInfo(PlayerState)
	local HostageCandidates = gamemode.GetPlayerList("", 3, true, 0, false)
	if PlayerState == player.GetPlayerState(HostageCandidates[self.HostageIndex]) then
		local HostageStartIndex = umath.random(#self.HostageStarts)
		return self.HostageStarts[HostageStartIndex]
	end
end

function uplink:PlayerWantsToEnterPlayChanged(PlayerState, WantsToEnterPlay)
	if not WantsToEnterPlay then
		timer.Set(self, "CheckReadyDownTimer", 0.1, false);
	elseif gamemode.GetRoundStage() == "PreRoundWait" then
		if actor.GetTeamId(PlayerState) == self.DefendingTeamId then
			if self.DefenderIndex ~= 0 then
				player.SetInsertionPoint(PlayerState, self.DefenderInsertionPoints[self.DefenderIndex])
				gamemode.EnterPlayArea(PlayerState)
			end
		elseif gamemode.PrepLatecomer(PlayerState) then
			gamemode.EnterPlayArea(PlayerState)
		end
	end
end

function uplink:CheckReadyUpTimer()
	if gamemode.GetRoundStage() == "WaitingForReady" or gamemode.GetRoundStage() == "ReadyCountdown" then
		local ReadyPlayerTeamCounts = gamemode.GetReadyPlayerTeamCounts(false)
		local DefendersReady = ReadyPlayerTeamCounts[self.DefendingTeamId]
		local AttackersReady = ReadyPlayerTeamCounts[self.AttackingTeamId]
		if DefendersReady > 0 and AttackersReady > 0 then
			if DefendersReady + AttackersReady >= gamemode.GetPlayerCount(true) then
				gamemode.SetRoundStage("PreRoundWait")
			else
				gamemode.SetRoundStage("ReadyCountdown")
			end
		end
	end
end

function uplink:CheckReadyDownTimer()
	if gamemode.GetRoundStage() == "ReadyCountdown" then
		local ReadyPlayerTeamCounts = gamemode.GetReadyPlayerTeamCounts(true)
		local BlueReady = ReadyPlayerTeamCounts[self.DefendingTeamId]
		local RedReady = ReadyPlayerTeamCounts[self.AttackingTeamId]
		if BlueReady < 1 or RedReady < 1 then
			gamemode.SetRoundStage("WaitingForReady")
		end
	end
end

function uplink:OnRoundStageSet(RoundStage)
	if RoundStage == "WaitingForReady" then
		self:SetupRound()
	elseif RoundStage == "PreRoundWait" then
		local HostageCandidates = gamemode.GetPlayerList("", self.AttackingTeamId, true, 0, false)
		self.HostageIndex = umath.random(#HostageCandidates)
		actor.AddTag(HostageCandidates[self.HostageIndex], self.HostageTag)
		self.HostageOrigTeamId = actor.GetTeamId(HostageCandidates[self.HostageIndex])
		actor.SetTeamId(HostageCandidates[self.HostageIndex], self.HostageTeamId)
	elseif RoundStage == "BlueDefenderSetup" or RoundStage == "RedDefenderSetup" then
		gamemode.SetRoundStageTime(self.DefenderSetupTime)
		local HostageCandidates = gamemode.GetPlayerList("", self.HostageTeamId, true, 0, false)
		local DefendingTeam = gamemode.GetPlayerList("", self.DefendingTeamId, false, 0, false)
		local HostageCharacter = player.GetCharacter(HostageCandidates[self.HostageIndex])
		local HostageLocation = actor.GetLocation(HostageCharacter)
		for i = 1, #HostageCandidates do
			if i == self.HostageIndex then
				player.ShowGameMessage(HostageCandidates[self.HostageIndex], "You're the hostage this round.", self.DefenderSetupTime - 2)
			end
		end
		for i = 1, #DefendingTeam do
			player.ShowWorldPrompt(DefendingTeam[i], HostageLocation, "Hostage", self.DefenderSetupTime - 2)
		end
	elseif RoundStage == "InProgress" then
		timer.Set(self, "DisableSpawnProtection", 5.0, false);
	end
end

function uplink:OnGameTriggerBeginOverlap(GameTrigger, Character)
	timer.Set(self, "CheckExfilTimer", 1.0, true)
end

function uplink:CheckExfilTimer()
	if gamemode.GetRoundStage() == "InProgress" or gamemode.GetRoundStage() == "BlueDefenderSetup" or gamemode.GetRoundStage() == "RedDefenderSetup" then
	
		local Overlaps = actor.GetOverlaps(self.ExtractionPoints[self.ExtractionPointIndex], 'GroundBranch.GBCharacter')
		local LivingPlayers = gamemode.GetPlayerList("Lives", self.HostageTeamId, true, 0, false)
		
		local bExfiltrated = false
		local bLivingOverlap = false
		local bHostageSecure = false
		local PlayerWithLapTop = nil
		local HostageTeamId = 0

		for i = 1, #LivingPlayers do
			local LivingCharacter = player.GetCharacter(LivingPlayers[i])
		
			bExfiltrated = false

			for j = 1, #Overlaps do
				if Overlaps[j] == LivingCharacter then
					bLivingOverlap = true
					bExfiltrated = true
					if actor.HasTag(LivingPlayers[i], self.HostageTag) then
						bHostageSecure = true
					end
					break
				end
			end

			if bExfiltrated == false then
				break
			end
		end
	
		if bHostageSecure then
			if bExfiltrated then
				timer.Clear(self, "CheckExfilTimer")
				local HostageExtracted = gamemode.GetPlayerList("", self.AttackingTeamId, false, 0, false)
				actor.RemoveTag(HostageExtracted[self.HostageIndex], self.HostageTag)
				actor.SetTeamId(HostageExtracted[self.HostageIndex], self.AttackingTeamId)
				if self.HostageOrigTeamId == self.BlueTeamId then
					gamemode.AddGameStat("Result=Team1")
					gamemode.AddGameStat("Summary=BlueExtracted")
					gamemode.AddGameStat("CompleteObjectives=DefendObjective")
					gamemode.SetRoundStage("PostRoundWait")
				elseif self.HostageOrigTeamId == self.RedTeamId then
					gamemode.AddGameStat("Result=Team2")
					gamemode.AddGameStat("Summary=RedExtracted")
					gamemode.AddGameStat("CompleteObjectives=DefendObjective")
					gamemode.SetRoundStage("PostRoundWait")
				end
			end
		end

	end
end

function uplink:OnCharacterDied(Character, CharacterController, KillerController)
	if gamemode.GetRoundStage() == "PreRoundWait" 
	or gamemode.GetRoundStage() == "InProgress"
	or gamemode.GetRoundStage() == "BlueDefenderSetup"
	or gamemode.GetRoundStage() == "RedDefenderSetup" then
		if CharacterController ~= nil then
			player.SetLives(CharacterController, player.GetLives(CharacterController) - 1)
			timer.Set(self, "CheckEndRoundTimer", 1.0, false);
		end
	end
end

function uplink:CheckEndRoundTimer()
	local BluePlayers = gamemode.GetPlayerList("Lives", self.BlueTeamId, true, 1, false)
	local RedPlayers = gamemode.GetPlayerList("Lives", self.RedTeamId, true, 1, false)
	local HostageLives = "0"
	local HostagePlayers = gamemode.GetPlayerList("Lives", self.HostageTeamId, true, 1, false)
	for i = 1, #HostagePlayers do
		if actor.HasTag(HostagePlayers[i], self.HostageTag) then
			HostageLives = "1"
			break
		end
	end
	if HostageLives == "0" then
		local DeadHostage = gamemode.GetPlayerList("", self.AttackingTeamId, false, 0, false)
		actor.RemoveTag(DeadHostage[self.HostageIndex], self.HostageTag)
		actor.SetTeamId(DeadHostage[self.HostageIndex], self.AttackingTeamId)
		gamemode.BroadcastGameMessage("The hostage has been eliminated.", 3.0)
		gamemode.AddGameStat("Result=None")
		gamemode.AddGameStat("Summary=BothEliminated")
		gamemode.SetRoundStage("PostRoundWait")
	elseif #BluePlayers > 0 and #RedPlayers == 0 then
		if self.DefendingTeamId == self.BlueTeamId then
			gamemode.AddGameStat("Result=Team1")
			gamemode.AddGameStat("Summary=RedEliminated")
			gamemode.AddGameStat("CompleteObjectives=DefendObjective")
			gamemode.SetRoundStage("PostRoundWait")
		end
	elseif #BluePlayers == 0 and #RedPlayers > 0 then
		if self.DefendingTeamId == self.RedTeamId then
			gamemode.AddGameStat("Result=Team2")
			gamemode.AddGameStat("Summary=BlueEliminated")
			gamemode.AddGameStat("CompleteObjectives=DefendObjective")
			gamemode.SetRoundStage("PostRoundWait")
		end
	elseif #BluePlayers == 0 and #RedPlayers == 0 then
		gamemode.AddGameStat("Result=None")
		gamemode.AddGameStat("Summary=BothEliminated")
		gamemode.SetRoundStage("PostRoundWait")
	end
end

function uplink:SetupRound()
	if self.AutoSwap then
		local PrevDefendingTeam = self.DefendingTeamId
		local PrevAttackingTeam = self.AttackingTeamId
		self.DefendingTeamId = PrevAttackingTeam
		self.AttackingTeamId = PrevDefendingTeam
		self.AutoSwapCount = self.AutoSwapCount + 1
		
		if self.AutoSwapCount > 1 then
			local BlueMessage = ""
			local RedMessage = ""
			
			if self.AttackingTeamId == self.BlueTeamId then
				BlueMessage = "SwapAttacking"
				RedMessage = "SwapDefending"
			else
				BlueMessage = "SwapDefending"
				RedMessage = "SwapAttacking"
			end
					
			local BluePlayers = gamemode.GetPlayerList("", self.BlueTeamId, false, 0, false)
			for i = 1, #BluePlayers do
				player.ShowGameMessage(BluePlayers[i], BlueMessage, 10.0)
			end
			
			local RedPlayers = gamemode.GetPlayerList("", self.RedTeamId, false, 0, false)
			for i = 1, #RedPlayers do
				player.ShowGameMessage(RedPlayers[i], BlueMessage, 10.0)
			end
		end
	end
	
	for i, SpawnProtectionVolume in ipairs(self.SpawnProtectionVolumes) do
		actor.SetTeamId(SpawnProtectionVolume, self.AttackingTeamId)
		actor.SetActive(SpawnProtectionVolume, true)
	end

	gamemode.ClearGameObjectives()

	gamemode.AddGameObjective(self.DefendingTeamId, "DefendObjective", 1)
	gamemode.AddGameObjective(self.AttackingTeamId, "CaptureObjective", 1)

	self.ExtractionPointIndex = umath.random(#self.ExtractionPoints)

	for i = 1, #self.ExtractionPoints do
		local bActive = (i == self.ExtractionPointIndex)
		actor.SetActive(self.ExtractionPoints[i], bActive)
		if self.AttackingTeamId == self.BlueTeamId then
			actor.SetActive(self.ExtractionPointMarkersBlue[i], bActive)
		elseif self.AttackingTeamId == self.RedTeamId then
			actor.SetActive(self.ExtractionPointMarkersRed[i], bActive)
		end
		self.ExtractionPoint = self.ExtractionPoints[i]
	end

	for i, InsertionPoint in ipairs(self.AttackerInsertionPoints) do
		actor.SetActive(InsertionPoint, true)
		actor.SetTeamId(InsertionPoint, self.AttackingTeamId)
	end

	if #self.DefenderInsertionPoints > 1 then
		local NewDefenderIndex = self.DefenderIndex

		while (NewDefenderIndex == self.DefenderIndex) do
			NewDefenderIndex = umath.random(#self.DefenderInsertionPoints)
		end
		
		self.DefenderIndex = NewDefenderIndex
	else
		self.DefenderIndex = 1
	end
	
	for i, InsertionPoint in ipairs(self.DefenderInsertionPoints) do
		actor.SetActive(InsertionPoint, i == self.DefenderIndex)
		actor.SetTeamId(InsertionPoint, self.DefendingTeamId)
	end

	local InsertionPointName = gamemode.GetInsertionPointName(self.DefenderInsertionPoints[self.DefenderIndex])
end

function uplink:ShouldCheckForTeamKills()
	if gamemode.GetRoundStage() == "InProgress" 
	or gamemode.GetRoundStage() == "BlueDefenderSetup"
	or gamemode.GetRoundStage() == "RedDefenderSetup" then
		return true
	end
	return false
end

function uplink:PlayerCanEnterPlayArea(PlayerState)
	if player.GetInsertionPoint(PlayerState) ~= nil then
		return true
	end
	return false
end

function uplink:OnRoundStageTimeElapsed(RoundStage)
	if RoundStage == "PreRoundWait" then
		if self.DefendingTeamId == self.BlueTeamId then
			gamemode.SetRoundStage("BlueDefenderSetup")
		else
			gamemode.SetRoundStage("RedDefenderSetup")
		end
		return true
	elseif RoundStage == "BlueDefenderSetup"
		or RoundStage == "RedDefenderSetup" then
		gamemode.SetRoundStage("InProgress")
		return true
	end
	return false
end

function uplink:OnProcessCommand(Command, Params)
	if Command == "defendersetuptime" then
		if Params ~= nil then
			self.DefenderSetupTime = math.max(tonumber(Params), self.MinDefenderSetupTime)
			self.DefenderSetupTime = math.min(self.DefenderSetupTime, self.MaxDefenderSetupTime)
		end
	elseif Command == "capturetime" then
		self.CaptureTime = math.max(tonumber(Params), self.MinCaptureTime)
		self.CaptureTime = math.min(self.CaptureTime, self.MaxCaptureTime)
	elseif Command == "autoswap" then
		if Params ~= nil then
			self.AutoSwap = (tonumber(Params) == 1)
		end
	end
end

function uplink:PlayerEnteredPlayArea(PlayerState)
	if actor.GetTeamId(PlayerState) == self.AttackingTeamId then
		if not actor.HasTag(PlayerState, self.HostageTag) then
			local FreezeTime = self.DefenderSetupTime + gamemode.GetRoundStageTime()
			player.FreezePlayer(PlayerState, FreezeTime)
		end
	end
end

function uplink:DisableSpawnProtection()
	if gamemode.GetRoundStage() == "InProgress" then
		for i, SpawnProtectionVolume in ipairs(self.SpawnProtectionVolumes) do
			actor.SetActive(SpawnProtectionVolume, false)
		end
	end
end

function uplink:LogOut(Exiting)
	if gamemode.GetRoundStage() == "PreRoundWait" or gamemode.GetRoundStage() == "InProgress" then
		timer.Set(self, "CheckEndRoundTimer", 1.0, false);
	end
end

return uplink