local part = script.Parent

part.Touched:Connect(function(hitObject)
	local humanoid = hitObject.Parent:FindFirstChild("Humanoid")
  	if humanoid then -- Checks if the hitObject is a player
		while humanoid do
			-- Makes the player jump until his health reaches 0.
			repeat humanoid.Jump = true
				wait()
			until humanoid.Health == 0
		end
	end
end)