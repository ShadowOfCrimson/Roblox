local part = script.Parent

part.Touched:Connect(function(p)
	local h = p.Parent:FindFirstChild("Humanoid")
  	if h then -- is a human
		while h do
			repeat h.Jump = true
				wait()
			until h.Health == 0
		end
	end
end)
