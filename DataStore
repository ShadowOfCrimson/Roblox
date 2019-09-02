local level = game:GetService("DataStoreService"):GetDataStore("Levels")
local xp = game:GetService("DataStoreService"):GetDataStore("XP")
local axp = game:GetService("DataStoreService"):GetDataStore("AXP")

function savadata(dataname, playerid, value)
	game:GetService("DataStoreService"):GetDataStore(dataname):SetAsync(playerid, value)
end

game.Players.PlayerAdded:Connect(function(player)
	local leader = Instance.new("Folder")
	leader.Name = "leaderstats"
	leader.Parent = player
	local levelz = Instance.new("IntValue")
	levelz.Value = level:GetAsync(tostring(player.userId)) or 1
	levelz.Name = "Level"
	levelz.Parent = player:WaitForChild("leaderstats")
	local xpn = Instance.new("IntValue")
	xpn.Value = axp:GetAsync(tostring(player.userId)) or 700
	xpn.Name = "XPNeeded"
	xpn.Parent = player
	
	xpz.Changed:Connect(function()
		if player:WaitForChild("XP").Value >= player:WaitForChild("XpNeeded").Value then
	levelz.Value = levelz.Value + 1
	xpn.Value = xpn.Value + 700
	savadata("Levels", player.userId, levelz.Value)
	savadata("XP", player.userId, xpz.Value)
	savadata("AXP", player.userId, xpn.Value)
		else
			savadata("Levels", player.userId, levelz.Value)
			savadata("XP", player.userId, xpz.Value)
			savadata("AXP", player.userId, xpn.Value)
		end
			
		end)
	
	game.Players.PlayerRemoving:connect(function(player)
		savadata("Levels", player.userId, levelz.Value)
		savadata("XP", player.userId, xpz.Value)
		savadata("AXP", player.userId, xpn.Value)
	end)
	end)
