local bomb = {
	CurrentTime = 0,
	TerCheck = false,
}
function bomb:ServerUseTimer(User, DeltaTime)
	DefuseTime = gamemode.GetScript().DefuseTime
	local Result = {}
	if actor.GetTeamId(User) == 2 then
		Time_Now = gamemode.GetScript().GetMinSec()
		Result.Message = "TIMER["..Time_Now.."]"
		Result.Equip = false
		if self.TerCheck == false then
			Result.Percentage = (self.CurrentTime+0.001) / DefuseTime
			self.TerCheck = true
		else
			Result.Percentage = (self.CurrentTime+0.0011) / DefuseTime
			self.TerCheck = false
		end
		return Result
	end
	if gamemode.GetRoundStage() == "InProgress" then
		self.CurrentTime = self.CurrentTime + DeltaTime
		self.CurrentTime = math.max(self.CurrentTime, 0)
		self.CurrentTime = math.min(self.CurrentTime, DefuseTime)
		Time_Now = gamemode.GetScript().GetMinSec()
		Result.Message = "Defusing Bomb"
		Result.Equip = false
		Result.Percentage = self.CurrentTime / DefuseTime
		if Result.Percentage == 1.0 then
			actor.RemoveTag(self.Object, gamemode.GetScript().BombTag)
			Result.Equip = true
			Result.Message = "BombWasDefused!"
			ok = gameplaystatics.GetAllActorsWithTag(gamemode.GetScript().BombTag)
			if #ok < 1 then
				gamemode.AddGameStat("Result=Team1")
				gamemode.AddGameStat("Summary=AllDefused")
				gamemode.AddGameStat("CompleteObjectives=DefuseAllBombs")
				gamemode.SetRoundStage("PostRoundWait")
			end
		end
	end
	return Result
end

function bomb:OnReset()
	self.CurrentTime = 0
end

return bomb