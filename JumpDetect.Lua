local part = script.Parent

part.Touched:Connect(function(p)
	local h = p.Parent:FindFirstChild("Humanoid)
  	if h then -- is a human
    	h.StateChanged:Connect(function(oldState,newState) --enum 3 is jumping
   		if newState.HumanoidStateType == 3 then -- jumped!
	        h:TakeDamage(9001) -- IT'S OVAR 9000!!!
      	end
    end)
end)
