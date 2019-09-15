local boards = {}
local queue = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local gameClickEvent = Instance.new("RemoteEvent", ReplicatedStorage)
gameClickEvent.Name = "GameClickEvent"

--[[Drops pieces in gameboard
	]]
function dropParts(pieces)
	for i,v in pairs(pieces) do
		local originalPos = v.CFrame
		v.Anchored = false
		v.Size = Vector3.new(.9, 2, 2)
		v.CFrame = originalPos
		game.Debris:AddItem(v, 5)
	end
end
--[[The end of a game resulting in no winner
	Argument: board = board played on
	]]
function tieGame(board)
	print("The board is full, tie game.")
	local players={}
	for i,v in pairs(boards[board])do
		if i ~= "InUse" and i~= "Matrix" then
			table.insert(players, i)
		end
	end
	print("# of players is :",#players)
	local gameBoard = workspace.Boards:FindFirstChild(board)
	local gameParts = gameBoard.Pieces:getChildren()
	wait(2)
	dropParts(gameParts)
	wait(3)
	gameBoard.BaseBoardParts.Bottom.CanCollide = true
	cleanBoard(board)
	table.insert(queue, game.Players:FindFirstChild(players[1]))
	table.insert(queue, game.Players:FindFirstChild(players[2]))
	startQueue()
end
--[[The end of a game resulting in a winner
	Arguments:
	board = board played on
	winner = name of player who won game
	]]
function Winner(board, winner)
	print("Four in a row! Winner winner, chicken dinner!!")
	print(winner,"has won the game!")
	local loser = boards[board][winner]["Partner"]
	local gameBoard = workspace.Boards:FindFirstChild(board)
	local gameParts = gameBoard.Pieces:getChildren()
	gameBoard.BaseBoardParts.Bottom.CanCollide = false
	wait(2)
	dropParts(gameParts)
	wait(3)
	gameBoard.BaseBoardParts.Bottom.CanCollide = true
	cleanBoard(board)
	table.insert(queue, game.Players:FindFirstChild(winner))
	table.insert(queue, game.Players:FindFirstChild(loser))
	startQueue()
end
--[[This function is responsible for continuing down
	a path one more unit and checking for matches.
	]]
function continueLine(board, x, y, dirx, diry)
	local matrix = boards[board]["Matrix"]
	if not(x+2*dirx<=0 or x+2*dirx>=8)then -- matrix bounds check
		--print("Within x-bounds")
		if not(y+2*diry<=0 or y+2*diry>=7) then -- matrix bounds check
			--print("Within y-bounds")
			if matrix[x+2*dirx][y+2*diry] then -- does this exist in the matrix?
				--print("Exists in matrix")
				local test = matrix[x+2*dirx][y+2*diry]
				if test == matrix[x][y] then -- is the value of the same piece color?
					--print("true")
					--print("The value here is:",matrix[x+2*dirx][y+2*diry])
					return true
				else
					--print("false")
					--print("The value here is:",matrix[x+2*dirx][y+2*diry])
					return false
				end
			end
		end
	end
end
--[[calculate 4-in-a-row
	Arguments:
	board = board played on
	x = x coordinate of placed piece
	y = y coordinate of placed piece
	input = 1 or 2, the player number of placer
	]]
function calculateMove(board, x, y, input)
	print("---START OF NEW MOVE---")
	print("matrix(",x,", ",y,")")
	local matrix = boards[board]["Matrix"]
	
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
								--print("matrix(",x+q,", ",y+w,")")
								--[[Test points assuming it is an end point of a 4-in-a-row condition.
								If this is not true, check for the fourth match on opposite side.
								If that is not true either, we are not interested in this condition.]]--
								local thirdMatch = continueLine(board,x,y,q,w)
								--print("matrix(",x+2*q,", ",y+2*w,")")
								if thirdMatch then --if we have a third match...
									--print("Three in a row...")
									local fourthMatch = continueLine(board,x+q,y+w,q,w)
									if fourthMatch then
										return true -- WINNER
									else --not a fourth, so look for the last one on opposite side!
										--print("Trying for special condition")--This runs currently
										local fourthMatch = continueLine(board, x+q, y+w, -q, -w)
										--print("matrix(",x-q,", ",y-w,")")
										if fourthMatch then -- Opposite side exists and matches!
										--print("Special Condition")--Currently does not fire, find out why
										return true -- WINNER
										end
									end
								else --print("Only two in a row, ignore this condition")
								end
							end
						end
					end
				end
			end			
		end
	end
end
--[[This function cleans all parts from the board given
	]]
function cleanBoard(board)
	boards[board]={}
	boards[board]["InUse"] = false
	makeMatrix(board)
	local parts = workspace.Boards:FindFirstChild(board).Pieces:GetChildren()
	for i,v in pairs(parts)do
		if v then
			v:Destroy()
			--print("Destroyed a piece")
		end
	end
end
--[[This function switches to the next player's turn
	given the player who just went, and the board they
	are using
	]]
function changeTurn(player, board)
	if boards[board][player] then
		for i,v in pairs(boards[board])do
			if i ~= "InUse" and i ~= "Matrix" and i ~= player then--i = next player
				boards[board][player]["Turn"] = false
				boards[board][i]["Turn"] = true
			end
		end
	end
end
--[[This function places a game piece in the board selected
	it references a player's chosen game color and drops a 
	piece in the column of the board at given height
	]]
function placePiece(player, columnNumber, board, height)--player, column, board
	local gp = game.ServerStorage.GamePiece:Clone()
	gp.Color = boards[board][player]["Color"]
	local gameBoard = workspace.Boards:FindFirstChild(board)
	local column = gameBoard.BaseBoardParts.Detectors:FindFirstChild(tostring(columnNumber))--Have to convert for Names
	gp.CFrame = column.CFrame*CFrame.new(Vector3.new(0, 7, 0))
	gp.Parent = gameBoard.Pieces
	local tween = game:GetService("TweenService")
	local tweenInfo = TweenInfo.new(1,Enum.EasingStyle.Bounce,Enum.EasingDirection.Out, 0, false, .5)
	local result = {}
	result.CFrame = column.CFrame*CFrame.new(Vector3.new(0, -7+(2*height), 0))
	local tweeny = tween:Create(gp,tweenInfo, result)
	tweeny:Play()
	local winner = calculateMove(board, columnNumber, height, boards[board][player]["PlayerNumber"])--Calculate 4-in-a-row
	if winner then
		Winner(board, player)
	end
end
--[[Function checks matrix of board argument
	to see if all values are nonzero, aka full
	if it is, return true, else return false.
	]]
function checkMatrix(board)
	local boardFilled = true
	for x=1,7 do
		for y = 1,6 do
			if boards[board]["Matrix"][x][y] == 0 then
				boardFilled = false
				return boardFilled
			end
		end
	end
	return boardFilled
end
--[[This checks the matrix of board in the column selected to see
	if it is available for a piece to be dropped there.
	]]
function checkStack(board, column)--Board Name, Column Number
	
	local valid = false
	
	for y = 1,6 do
		if boards[board]["Matrix"][column][y] == 0 then--Not last in column and valid
			valid = true
			return true, y
		end
	end
	return valid
end
--[[Function decides on the server side if a player can click on a board or not
	by accessing the table of boards and checking if they are a player of that board
	]]
local function onGameClickEventFired(player, columnNumber, boardName)
	local column = tonumber(columnNumber)--Get rid of a lot of bugs off the bat.
	--print(player, "wants to drop a piece on column", columnNumber,"of the board called",boardName)
	for i,v in pairs(boards) do
		if i == boardName then--This board is in boards
			--print("The board exists in the table")
			for j,k in pairs(boards[i])do--Cycle through the board's index to find playerName
				--print("J = ",j)
				if player.Name == j then--This player is playing this board!
					--print("This is a valid move!")
					if boards[i][player.Name]["Turn"]==true then
						local valid, y = checkStack(boardName, column)--Can we place a piece, how high?
						if valid then
							print(y)
							--boards[i]["Matrix"][column][y] = boards[i][player.Name]["PlayerNumber"]
							placePiece(player.Name, column, i, y)
							if y == 6 then
								local check = checkMatrix(boardName)
								if check then
									tieGame(boardName)
								end
							end
							changeTurn(player.Name, boardName)
						end
					--print("It is player's turn and dropping a piece is possible")
					return
					else --print("It is not your turn!")
					end
				end
			end
		end
	end
end
 
gameClickEvent.OnServerEvent:Connect(onGameClickEventFired)
--[[This function is called at the beginning of the server and spawns 4 boards.
	it also generates a matrix for each board and puts it in the boards table
	inside the index of the board's name.
]]
function spawnBoards()
	for i=1,4 do
		local board = game.ServerStorage.Connect4Board:Clone()
		board:SetPrimaryPartCFrame(CFrame.new(Vector3.new(0,6.374,0))
		*CFrame.Angles(0,math.rad(90)*i,0)
		*CFrame.new(Vector3.new(-35,0 , 0)))
		board.Name = board.Name..i
		board.Parent = game.Workspace.Boards
		boards[board.Name] = {}
		boards[board.Name]["InUse"] = false
		makeMatrix(board.Name)
	end
end
--[[Creates a 7x6 matrix of 0's.
	]]
function makeMatrix(board)
	boards[board]["Matrix"]={}
	for x = 1,7 do
		boards[board]["Matrix"][x]={}
		for y = 1,6 do
			table.insert(boards[board]["Matrix"][x],0)
		end
	end
	--Verify matrix:
	local m = boards[board]["Matrix"]
	--print(m[1][6],m[2][6],m[3][6],m[3][6],m[5][6],m[6][6], m[7][6])
end
--[[Starts a game with arguements p1 and p2 which are players
	searches for an open board (not InUse) and claims it
	Teleports players to board and sets up table values
	]]
function startGame(p1, p2)
	if p1 ~= p2 then
		--print("#boards =",#boards)
		for i,v in pairs(boards) do
			if v.InUse == false then -- if we found a board to use, then insert the players in the board's table
				--print(boards[i])
				v.InUse = true
				--print(i)
				boards[i][p1.Name] = {	["Wins"] = 0,--Boards[Board1][Player1] = {[Player1's Stats Here]}
										["Color"] = Color3.new(1,0,0),--Red}--In the future allow for player choices
										["PlayerNumber"] = 1,
										["Turn"] = false,
										["Partner"] = p2.Name
										}
				boards[i][p2.Name] = {	["Wins"] = 0,
										["Color"] = Color3.new(1,1,0),--Yellow}--In the future allow for player choices
										["PlayerNumber"] = 2,
										["Turn"] = false,
										["Partner"] = p1.Name
										}
				for x,y in pairs(boards[i])do
				--print(x)
				end
				local board = workspace.Boards:FindFirstChild(tostring(i))
				repeat wait() until p1.Character
				--trapCharacter(player1.Character)
				p1.Character.HumanoidRootPart.CFrame = board.BaseBoardParts.Bottom.CFrame * CFrame.new(5,2,0)
				repeat wait() until p2.Character
				--trapCharacter(player2.Character)
				p2.Character.HumanoidRootPart.CFrame = board.BaseBoardParts.Bottom.CFrame * CFrame.new(-5,2,0)
			    print(p1,"and",p2,"have started a game on",i)
				local turn = math.random(1,2)
				if turn == 1 then
					boards[i][p1.Name]["Turn"] = true
				elseif turn == 2 then
					boards[i][p2.Name]["Turn"] = true
				else print("Error, turn is broken on generate!")
				end
				break
			end
			--print(boards[v.Name])
		end
	else print("Error: can't play against self")
	end
end
--[[This function checks the queue table for players
	If there is enough to start a game, start one
	If there is more than enough, start one, then requeue
	]]
function startQueue()
	if #queue == 2 then-- Enough to queue one game
		startGame(queue[1],queue[2])--Start a game with both players
		print(queue[1], "and", queue[2])
		queue = {}
		print("=2")
	elseif #queue > 2 then-- An extra player(s) will remain
		startGame(queue[1],queue[2])
		table.remove(queue,2)
		table.remove(queue,1)
		print(">2")
		startQueue()
	end
end
--[[Adds player to queue when they join the game
	starts queue after that
	]]
game.Players.PlayerAdded:Connect(function(p)--p = player
	table.insert(queue, p)
	startQueue()
end)

--[[This function does the following actions, given a player as argument1:
	-Remove player and partner from board
	-Call cleanup board function
	-Remove Connections for clickers
	-Sets board.InUse to false
	-places partner back in queue
	-starts queue
	]]
game.Players.PlayerRemoving:Connect(function(p)
	
	for i,v in pairs(queue)do--If player leaving exists in queue, remove from queue
		if v == p then
			table.remove(queue,i)
		end
	end
	
	for board,v in pairs(boards)do
		for i,z in pairs(boards[board])do
			if boards[board][p.Name] then -- if player exists
			local player2 = boards[board][p.Name]["Partner"]
			local partner = game.Players:FindFirstChild(player2)
			partner:LoadCharacter()--Respawn partner
			table.insert(queue, partner)
			cleanBoard(board)
			startQueue()
			return
			end
		end
	end
end)

spawnBoards()
