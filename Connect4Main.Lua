local players = {}
local playing = {}
local boards = {}
local PhysicsService = game:GetService("PhysicsService")


--[[GameScript Starts Here!]]--

--Drops a game piece from top of column to ending position with TweeningService
--game piece will be of correct player color, update board matrix/table

function dropPiece(startPos,endPos,color)
	local gp = game.ServerStorage.GamePiece:Clone()
	gp.Color = color
	gp.CFrame = CFrame.new(startPos)*CFrame.Angles(0,math.rad(90),0)
	gp.Parent = workspace
	local tween = game:GetService("TweenService")
	local tweenInfo = TweenInfo.new(1,Enum.EasingStyle.Bounce,Enum.EasingDirection.Out, 0, false, .5)
	local result = {}
	result.Position = endPos
	local tweeny = tween:Create(gp,tweenInfo, result)
	tweeny:Play()
end

function continueLine(matrix,x,y,dirx,diry)
	if not(x+2*dirx<=0 or x+2*dirx>=8)then -- matrix bounds check
		if not(y+2*diry<=0 or y+2*diry>=7) then -- matrix bounds check
			if matrix[x+2*dirx][y+2*diry] then -- does this exist in the matrix?
				local test = matrix[x+2*dirx][y+2*diry]
				if test == matrix[x][y] then -- is the value of the same piece color?
					return true
					else print("Close, but no cigar!")
				end
			end
		end
	end
end

--calculate 4-in-a-row

function calculate(matrix,x,y)
	print("---START OF NEW MOVE--- <-------STARTING HERE BOYYYYYY")
	--print(matrix[x][y])--This works :D
	local input = matrix[x][y]
	local matches = {}
	
	for q=-1,1 do --x offset
		for w=-1,1 do --y offset
			if not(q==0 and w==0) then --8 positions around center
				--print("it's a point around test point")
				if not(x+q==0 or x+q==8)then--check to make sure it's within matrix size for +- q
					--print("test is within x-coords")
					if not(y+w==0 or y+w==7)then--check to make sure it's within matrix size for +- w
						--print("test is within y-coords")
						if matrix[x+q][y+w] then --if the matrix input plus their offsets exists then
							--print("It exists in the matrix")
							local test = matrix[x+q][y+w]
							if test == input then -- two in a row
								print("a piece touching test is a match")
								table.insert(matches,test)
								--[[Everything after this point is testing the points opposite of test to check for 3 in a row]]--
								if q==0 or w==0 then -- Horizontal or Vertical
									
									--[[HORIZONTAL CHECKING]]-- 100% complete, horizontal works :D
									if w==0 then --Horizontal; can't check for q==0 upwards, but can go down
										print("checking Horizontally")
										if not(x-q==0 or x-q==8) then --Opposite piece Within bounds
											print("piece is within bounds")
											if matrix[x-q][y]then -- Does the piece opposite the matching piece exist?
												local testV = matrix[x-q][y] -- It does exist!
												if testV == input then -- Three in a row!
													print("Three in a row! Horizontally!")--Can be left to right or right to left
													print("Third is at",x-q,",",y)
													local fourthMatch = continueLine(matrix,x,y,-q,0)--continue calculating towards row left or right
													if fourthMatch then
														print("Fourth is at",x-2*q,",",y)
														print("Four in a row! Winner winner, chicken dinner!!")
													end
												else -- only two in a row
													print("Checking along 2 in a row path")
													local thirdMatch = continueLine(matrix,x,y,q,w) --Check along the path
													if thirdMatch then
														print("Three in a row --Horizontally in a line")
														local fourthMatch = continueLine(matrix,x+q,y+w,q,w)
														if fourthMatch then
															print("Four in a row! Winner winner, chicken dinner!!")
														end
													end
												end
											end
										else -- piece opp doesn't exist, but go down the row the other way
										print("Checking along 2 in a row path")
											local thirdMatch = continueLine(matrix,x,y,q,w) --Check along the path
											if thirdMatch then
												print("Three in a row --Horizontally in a line")
												local fourthMatch = continueLine(matrix,x+q,y+w,q,w)
												if fourthMatch then
													print("Four in a row! Winner winner, chicken dinner!!")
												end
											end
										end
										
									--[[VERTICAL CHECKING]]-- 100% complete, vertical works :D
									elseif q==0 and w==-1 then --check down
										if matrix[x][y+w] then --if it exists
											local testDown = matrix[x][y+w]
											if testDown == input then --the piece below matches!
												print("Piece below is a match!")
												local thirdMatch = continueLine(matrix,x,y,0,w)
												if thirdMatch then
													print("Three vertically stacked matches...")
													local fourthMatch = continueLine(matrix,x,y+w,0,w)
													if fourthMatch then
														print("Four in a row! Winner winner, chicken dinner!!")
													end
												end
											end
										end
									end
									
								--[[DIAGONAL CHECKING]]-- 100% complete, diagonal works :D
								elseif math.abs(q)==1 and math.abs(w)==1 then --Diagonally!
									print("Checking diagonally!")--we have two in a row, need to find third...
									local thirdMatch = continueLine(matrix,x,y,q,w)
									if thirdMatch then --if we have a third match...
										local fourthMatch = continueLine(matrix,x+q,y+w,q,w)
										if fourthMatch then
											print("Four in a row! Winner winner, chicken dinner!!")
										else --not a fourth, so look for the last one on opposite side!
											local fourthMatch = continueLine(matrix, x, y, -q, -w)
											if fourthMatch then -- Opposite side exists and matches!
											print("Four in a row! Winner winner, chicken dinner!!")
											end
										end
									else print("Only two in a row, ignore this condition")
									end
									
								else--This will never occur because it will always be either orthogonal or diagonal
									print("ERROR MATH IS WRONG")
								end
							end
						end
					end
				end
			end			
		end
	end
	
	for i,v in pairs(matches) do
		--print(v,"is match",i)--print number of matching pieces around test item
	end
end

--Starts listeners for mouseclicks on active boards
--also sets up the matrix for storing board data
--when a click is heard, dropPiece is called as well as calculate. 

function initiateClickers(b,p1,p2) --Here b = the board players are using to play
	
	local detectors = {}
	local dropped = {0,0,0,0,0,0,0}
	local gridData = {--gridData[x][y] stores a matrix of the x and y coords.
		[1]={0,0,0,0,0,0},
		[2]={0,0,0,0,0,0},
		[3]={0,0,0,0,0,0},
		[4]={0,0,0,0,0,0},
		[5]={0,0,0,0,0,0},
		[6]={0,0,0,0,0,0},
		[7]={0,0,0,0,0,0}
		}
	
	for i=1,7 do
		detectors[i] = b.Detectors:FindFirstChild(tostring(i))
	end
	
	--[[This is the 1st click detector,
		if player 1 clicks it, a red piece is dropped,
		if player 2 clicks, a yellow one is dropped instead]]
	for x=1,7 do
		detectors[x].ClickDetector.MouseClick:Connect(function(player)
			print(player,"has clicked 1")
			local counter = dropped[x]
				if player == p1 and counter ~= 12 then
					--print("player 1")
					dropPiece(detectors[x].Position+Vector3.new(0, 7, 0), detectors[x].Position+Vector3.new(0, -5+counter, 0),Color3.new(1,0,0))--red
					dropped[x] = counter+2
					gridData[x][1+counter/2]=1
					calculate(gridData,x,(1+counter/2))
				elseif player == p2 and counter ~= 12 then
					--print("player 2")
					dropPiece(detectors[x].Position+Vector3.new(0, 7, 0), detectors[x].Position+Vector3.new(0, -5+counter, 0),Color3.new(1,1,0))--yellow
					dropped[x] = counter+2
					gridData[x][1+counter/2]=2
					calculate(gridData,x,(1+counter/2))
				else print("This player isn't playing!")
			end
		end)
	end
end

--[[Lobby Functions Below]]--

--finds players in table that match with playing and removes them from players

function startGame(p1,p2)
	print(p1,"and",p2,"are starting a game of Connect 4!")
	table.insert(playing,p1)
	table.insert(playing,p2)
	local newPlayers = {}
        for i1,v1 in pairs(players) do
            local IsPlaying = false
            for i2,v2 in pairs(playing) do
                if v1 == v2 then
                    IsPlaying = true--player is playing
                    break--don't continue to search for more, we found it.
                end
            end
            if not IsPlaying then--all players who are NOT playing
                table.insert(newPlayers, v1)
            end
        end
	players = newPlayers
	print(#players,"After starting a game")
	--teleportPlayers(p1,p2)
	local board = nil
	boards = workspace.Boards:GetChildren()
	for i,v in pairs(boards) do
		if v.InUse.Value == false then
			board = v
			board.InUse.Value = true
			break
		end
	end
	repeat wait() until p1.Character
	--trapCharacter(player1.Character)
	p1.Character.HumanoidRootPart.CFrame = board.Bottom.CFrame * CFrame.new(5,2,0)
	repeat wait() until p2.Character
	--trapCharacter(player2.Character)
	p2.Character.HumanoidRootPart.CFrame = board.Bottom.CFrame * CFrame.new(-5,2,0)
	initiateClickers(board,p1,p2)
end

--If there are two players ready to play, queue them into a game

function startQueue()
	wait()
	if #game.Players:GetChildren()>#playing then
		print("Can queue 1 game")
		startGame(players[1],players[2])
	end
end
--not using atm
function trapCharacter(char)
	for i,v in pairs(char:GetChildren()) do
		if v:IsA("Part")then
			PhysicsService:SetPartCollisionGroup(v, "Characters")
			print("Added",v.Parent.Name,"'s",v,"to CollisionGroup Characters")
		end
	end
end

--When a player spawns, their character loads, add the parts that collide to collision groups
--not using atm
function characterLoaded(char)
	for i,v in pairs(char:GetChildren()) do
		if v:IsA("Part")then
			--PhysicsService:SetPartCollisionGroup(v, "NotInGame")
			print("Added",v,"to CollisionGroup NotInGame")
		end
	end
end

--when a player joins, check to see if there is enough to queue, if so, send to queue system.

game.Players.PlayerAdded:Connect(function(player)
	--player.CharacterAdded:Connect(characterLoaded)
	table.insert(players,player)
	if #players <= 1 then
		print("Need more players")
	elseif #players >= 2 then
		startQueue()
	end
end)

--remove player from all tables when they leave

game.Players.ChildRemoved:Connect(function(player)
	for i,v in pairs(players) do
		if v == player then
			table.remove(players,i)
		end
	end
	for i,v in pairs(playing) do
		if v == player then
			table.remove(playing,i)
		end
	end
end)
