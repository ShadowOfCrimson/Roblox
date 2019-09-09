local players = {}
local playing = {}
local boards = {}
local gameInstances = {}
local PhysicsService = game:GetService("PhysicsService")
local connections = {}
local detectors = {}

--[[Game Loading Boards]]--
--I use this to refresh the game board with the latest version from ServerStorage
--This part runs as soon as the server starts so boards are always loaded from storage

for i=1,4 do
	board = game.ServerStorage.Connect4Board:Clone()
	board:SetPrimaryPartCFrame(CFrame.new(Vector3.new(0,6.374,0))
	*CFrame.Angles(0,math.rad(90)*i,0)
	*CFrame.new(Vector3.new(-35,0 , 0)))
	board.Name = board.Name..i
	board.Parent = game.Workspace.Boards
end

--Create a table of detectors in order from 1-7
function findDetectors(b)
	detectors[b.Name] = {}
	for i=1,7 do
		detectors[b.Name][i] = b.BaseBoardParts.Detectors:FindFirstChild(tostring(i))
	end
	return detectors
end

--Loops through table and finds value, then removes it.
	
function RemoveFromTable(InputTable, Value)
	for i,v in pairs(InputTable) do
		if v == Value then
			table.remove(InputTable, i)
		end
	end
end

--Disconnects listening events from board given

function disconnectBoard(boardName)
	for x = 1,7 do --Disconnect listening events because players cannot place more pieces after game is over!
		if boardName then
			for i,v in pairs(connections)do
				print(v)
			end
			--[[print(connections[boardName][x])
			if connections[boardName][x]then
			local c = connections[boardName][x]
			c:Disconnect()
			end]]
		end
	end
end

--[[GameScript Starts Here!]]--

--The end function for a tie game

function TieGame(p1, p2, board)
	print("The board is full, restart game.")
	local gameParts = board.Pieces:getChildren()
	board.BaseBoardParts.Bottom.CanCollide = false
	wait(2)
	for i,v in pairs(gameParts) do
		local originalPos = v.CFrame
		v.Anchored = false
		v.Size = Vector3.new(.9, 2, 2)
		v.CFrame = originalPos
		game.Debris:AddItem(v, 5)
	end
	wait(3)
	board.BaseBoardParts.Bottom.CanCollide = true
	RemoveFromTable(playing, p1)
	RemoveFromTable(playing, p2)
	table.insert(players, p1)
	table.insert(players, p2)
	disconnectBoard(board.Name)
	board.InUse.Value = false
	startQueue()
end

--The end function for a won game

function Winner(winner, loser, board)
	print("Four in a row! Winner winner, chicken dinner!!")
	print(winner,"has won the game!")
	disconnectBoard(board.Name)
	local gameParts = board.Pieces:getChildren()
	board.BaseBoardParts.Bottom.CanCollide = false
	wait(2)
	for i,v in pairs(gameParts) do
		local originalPos = v.CFrame
		v.Anchored = false
		v.Size = Vector3.new(.9, 2, 2)
		v.CFrame = originalPos
		game.Debris:AddItem(v, 5)
	end
	wait(3)
	board.BaseBoardParts.Bottom.CanCollide = true
	RemoveFromTable(playing, winner)
	RemoveFromTable(playing, loser)
	table.insert(players, winner)
	table.insert(players, loser)
	board.InUse.Value = false
	startQueue()
end

--function cleans the parts from a board physically, they are not linked in any way currently to the matrix

function cleanBoard(b)
	local parts = workspace.Boards:FindFirstChild(b).Pieces:GetChildren()
	for i,v in pairs(parts)do
		if v then
			v:Destroy()
			print("Destroyed a piece")
		end
	end
end

--This function takes a matrix and checks all internal values are non zero

function checkBoard(matrix)
	local full = true
	for x = 1,#matrix do
		for y = 1,#matrix[x] do
			if matrix[x][y] == 0 then
				full = false
			end
		end
	end
	return full
end

--Troubleshooting function responsible for printing the table given
	
function printTable(input)
	for i=1,#input do
		print(input[i])
	end
end

--Troubleshooting function responsible for printing off grid data

function gridPrint(matrix)
	--for y=1,6 do
		local y=1
		for x=1,7 do
			print("(",x,", ",y,") =",matrix[x][y])
		end
	--end
end

--This function is responsible for continuing down a path one more unit and checking for matches.

function continueLine(matrix,x,y,dirx,diry)
	if not(x+2*dirx<=0 or x+2*dirx>=8)then -- matrix bounds check
		print("Within x-bounds")
		if not(y+2*diry<=0 or y+2*diry>=7) then -- matrix bounds check
			print("Within y-bounds")
			if matrix[x+2*dirx][y+2*diry] then -- does this exist in the matrix?
				print("Exists in matrix")
				local test = matrix[x+2*dirx][y+2*diry]
				if test == matrix[x][y] then -- is the value of the same piece color?
					print("true")
					print("The value here is:",matrix[x+2*dirx][y+2*diry])
					return true
				else
					print("false")
					print("The value here is:",matrix[x+2*dirx][y+2*diry])
					gridPrint(matrix)
					return false
				end
			end
		end
	end
end

--calculate 4-in-a-row
--[[Arguments:
	matrix = matrix of board spaces
	x = x location given in matrix for new piece
	y = y location given in matrix for new piece
	p = player who placed piece
	l = potential loser!! >:D
	b = board, just so we can pass it to Winner() ;)
	]]
function calculate(matrix,x,y,p,l,b)
	print("---START OF NEW MOVE--- <-------STARTING HERE BOYYYYYY")
	print("matrix(",x,", ",y,")")
	local input = matrix[x][y]
	local matches = {}
	matches[x] = {}
	
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
								print("matrix(",x+q,", ",y+w,")")
								--print("a piece touching test is a match")
								table.insert(matches,test)
								--[[Test points assuming it is an end point of a 4-in-a-row condition.
								If this is not true, check for the fourth match on opposite side.
								If that is not true either, we are not interested in this condition.]]--
								local thirdMatch = continueLine(matrix,x,y,q,w)
								print("matrix(",x+2*q,", ",y+2*w,")")
								if thirdMatch then --if we have a third match...
									--print("Three in a row...")
									local fourthMatch = continueLine(matrix,x+q,y+w,q,w)
									if fourthMatch then
										Winner(p,l,b)
									else --not a fourth, so look for the last one on opposite side!
										print("Trying for special condition")--This runs currently
										local fourthMatch = continueLine(matrix, x+q, y+w, -q, -w)
										print("matrix(",x-q,", ",y-w,")")
										if fourthMatch then -- Opposite side exists and matches!
										Winner(p,l,b)
										print("Special Condition")--Currently does not fire, find out why
										end
									end
								else print("Only two in a row, ignore this condition")
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

--Drops a game piece from top of column to ending position with TweeningService
--game piece will be of correct player color, update board matrix/table

function dropPiece(board, startFrame,endFrame,color)
	local gp = game.ServerStorage.GamePiece:Clone()
	gp.Color = color
	gp.CFrame = startFrame
	gp.Parent = board.Pieces
	local tween = game:GetService("TweenService")
	local tweenInfo = TweenInfo.new(1,Enum.EasingStyle.Bounce,Enum.EasingDirection.Out, 0, false, .5)
	local result = {}
	result.CFrame = endFrame
	local tweeny = tween:Create(gp,tweenInfo, result)
	tweeny:Play()
end

--Starts listeners for mouseclicks on active boards
--also sets up the matrix for storing board data
--when a click is heard, dropPiece is called as well as calculate. 

function initiateClickers(b,p1,p2) --Here b = the board players are using to play
	
	local clickedLast --This will hold the player who clicked last
	detectors = findDetectors(b)
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
	
	--[[This is the part where ClickDetectors listen for MouseClicks
		if player 1 clicks it, a red piece is dropped,
	if player 2 clicks, a yellow one is dropped instead]]
	connections[b.Name]={}
	for x=1,7 do
		connections[b.Name][x] = detectors[b.Name][x].ClickDetector.MouseClick:Connect(function(player)
			local counter = dropped[x]
				--Line below accounts for players trying to click more than once at a time
				if player == p1 and counter ~= 12 and clickedLast ~= p1 then--Twioe as much because of parts being 2x2 in size
					clickedLast = p1
					dropPiece(b,
						detectors[b.Name][x].CFrame*CFrame.new(Vector3.new(0, 7, 0)),
						detectors[b.Name][x].CFrame*CFrame.new(Vector3.new(0, -5+counter, 0)),
						Color3.new(1,0,0))--red
					dropped[x] = counter+2
					gridData[x][1+counter/2]=1
					wait(1)
					calculate(gridData,x,(1+counter/2),p1,p2,b)
					if counter == 10 then -- this filled the column, so check if board is full :)
						local boardFull = checkBoard(gridData)
						if boardFull then
						TieGame(p1, p2, b)
						end
					end
				elseif player == p2 and counter ~= 12 and clickedLast ~= p2 then--Twioe as much because of parts being 2x2 in size
					clickedLast = p2
					dropPiece(b,
						detectors[b.Name][x].CFrame*CFrame.new(Vector3.new(0, 7, 0)),
						detectors[b.Name][x].CFrame*CFrame.new(Vector3.new(0, -5+counter, 0)),
						Color3.new(1,1,0))--yellow
					dropped[x] = counter+2
					gridData[x][1+counter/2]=2
					wait(1)
					calculate(gridData,x,(1+counter/2),p2,p1,b)
					if counter == 10 then -- this filled the column, so check if board is full :)
						local boardFull = checkBoard(gridData)
						if boardFull then
						TieGame(p1, p2, b)
						end
					end
				else print(player,"isn't allowed to play a move!")
			end
		end) --print(connections[b.Name][x],"is at index",x)
	end
end


--[[Lobby Functions Below]]--

--finds players in table that match with playing and removes them from players

function startGame(p1,p2)
	if p1~=p2 then
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
		--print(#players,"After starting a game")
		local board = nil
		boards = workspace.Boards:GetChildren()
		for i,v in pairs(boards) do
			for n,a in pairs(gameInstances)do
				if not gameInstances[v] then
					print(v,"is boards, and instances is",a)
				else print("using board: ",v)
				end 
			end
			if v.InUse.Value == false then
				board = v--found a board, make this value the board
				board.InUse.Value = true--Hey! We're using this board here!
				repeat wait() until p1.Character
				--trapCharacter(player1.Character)
				p1.Character.HumanoidRootPart.CFrame = board.BaseBoardParts.Bottom.CFrame * CFrame.new(5,2,0)
				repeat wait() until p2.Character
				--trapCharacter(player2.Character)
				p2.Character.HumanoidRootPart.CFrame = board.BaseBoardParts.Bottom.CFrame * CFrame.new(-5,2,0)
				initiateClickers(board,p1,p2)
				gameInstances[board.Name] = {}
				table.insert(gameInstances[board.Name],1,p1)
				table.insert(gameInstances[board.Name],2,p2)
				break
			else
				print("We ran out of boards!")--If this breaks here, no boards are available!
			end
		end
	else
		print("Tried to queue player with self")
		printTable(players)
	end
end

--Check players to see if they are ready to play a game
function checkPlayers()
	local Ready = true
	for x = 1,2 do
		for i,v in pairs(playing) do
			if players[x] == v then
				print("Player",players[x],"is in a game")
				RemoveFromTable(players,v)
				Ready = false
			end
		end
	end
	if Ready then
		return true
	else print("Not ready for game")
		startQueue()
		return false
	end
end

--If there are two players ready to play, queue them into a game

function startQueue()
	if #game.Players:GetChildren()>#playing then
		if #players == 2 then
			local goodToGo = checkPlayers()
			if goodToGo then
				startGame(players[1],players[2])
			end
		elseif #players > 2 then --pick random 2 of set
		local randomNumber = math.random(2,#players)
			local goodToGo = checkPlayers()
			if goodToGo then
				startGame(players[1], players[randomNumber])
			end
		end
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
		--print("Need more players")
	elseif #players >= 2 then
		startQueue()
	end
end)

--remove player and partner from all tables when they leave

game.Players.ChildRemoved:Connect(function(player)
	RemoveFromTable(players, player)
	RemoveFromTable(playing, player)
	for i,v in pairs(gameInstances)do
		for n,t in pairs(gameInstances[i])do
			--print(gameInstances[i][n])
			if t == player then
				for x = 1,2 do -- place the player back into the game cycle, then requeue him, clean board
					if gameInstances[i][x] ~= player then
						RemoveFromTable(playing, gameInstances[i][x])
						table.insert(players, gameInstances[i][x])
						startQueue()
						cleanBoard(i)
						disconnectBoard(board.Name)
					end
				end
				gameInstances[i]={}
				print(gameInstances[i][n]) --This should be nil
				break
			end
		end
	end
end)
