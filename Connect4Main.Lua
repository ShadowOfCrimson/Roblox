--[[Master Table of the game
	boards
		-Boardx
			-"InUse" = false
			-"GameOver" = false
			-"Matrix" = [x][y] --> 6 by 7 Matrix of GridData
			-"GamePieces"
				-[Part] = Vector2(x,y) --> Matrix coordinates associated with part
			-Player1
				-["Wins"] = 0,
				-["Color"] = playerChoice1 or Color3.new(1,0,0),--Red}--In the future allow for player choices
				-["PlayerNumber"] = 1,
				-["Turn"] = false,
				-["Partner"] = p2.Name
			-Player2
				-Same as player 1, but "PlayerNumber" = 2
				-Also "Color" defaults to Yellow
	]]
local boards = {}
--Table of Players [Datatype: Player]
local queue = {}

local friendColors = {["ShadowOfCrimson"] = Color3.new(58/255, 125/255, 21/255),
						["Wildstar54368"] = Color3.new(183/255, 110/255, 121/255),
						["VShadowOfLightV"] = Color3.new(152/255, 194/255, 219/255)}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
--Event for client mouseclick handling
local gameClickEvent = Instance.new("RemoteEvent")
gameClickEvent.Parent = ReplicatedStorage
gameClickEvent.Name = "GameClickEvent"
--Notifies client it is their turn
local notifyTurn = Instance.new("RemoteEvent")
notifyTurn.Parent = ReplicatedStorage
notifyTurn.Name = "NotifyTurnEvent"
--Changes gui color for client
local notifyColor = Instance.new("RemoteEvent")
notifyColor.Parent = ReplicatedStorage
notifyColor.Name = "NotifyColorEvent"
--Shows path to board for players
local pathShowEvent = Instance.new("RemoteEvent")
pathShowEvent.Parent = ReplicatedStorage
pathShowEvent.Name = "PathShowEvent"
--[[Highlights the winning pieces
	arguments:
	board = board the pieces exist in
	coords = Vector2 representations of matrix values of pieces
	]]
function highlightPieces(board,coords)
	local matrix = boards[board]["Matrix"]
	local gamePieces = boards[board]["GamePieces"]
	local gameBoard = workspace.Boards:FindFirstChild(board)
	for i, Coord in pairs(coords)do --matrix winning coordinates Vector2
		for part, MatrixCoord in pairs(gamePieces)do 
			if Coord == MatrixCoord then
				--part.BrickColor = BrickColor.new("Really black")
				part.Material = "Neon"
			end
		end
	end
end
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
		--if i ~= everything but players then
		if i ~= "InUse" and i~= "Matrix" and i~= "GamePieces" and i~="GameOver" then
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
	coords = winning coordinates (Vector2(x,y)) from matrix
	]]
function Winner(board, winner, coords)
	boards[board]["GameOver"] = true
	print("Four in a row! Winner winner, chicken dinner!!")
	print(winner,"has won the game!")
	local loser = boards[board][winner]["Partner"]
	local gameBoard = workspace.Boards:FindFirstChild(board)
	local gameParts = gameBoard.Pieces:getChildren()
	gameBoard.BaseBoardParts.Bottom.CanCollide = false
	wait(1.5)
	highlightPieces(board,coords)
	wait(3)
	dropParts(gameParts)
	wait(3)
	gameBoard.BaseBoardParts.Bottom.CanCollide = true
	cleanBoard(board)
	local winnerPlayer = game.Players:FindFirstChild(winner)
	local loserPlayer = game.Players:FindFirstChild(loser)
	winnerPlayer:LoadCharacter()
	loserPlayer:LoadCharacter()
	table.insert(queue, winnerPlayer)
	table.insert(queue, loserPlayer)
	startQueue()
end
--[[This function is responsible for continuing down
	a path one more unit and checking for matches.
	]]
function continueLine(board, x, y, dirx, diry)
	local matrix = boards[board]["Matrix"]
	if not(x+2*dirx<=0 or x+2*dirx>=8)then -- matrix bounds check
		if not(y+2*diry<=0 or y+2*diry>=7) then -- matrix bounds check
			if matrix[x+2*dirx][y+2*diry] then -- does this exist in the matrix?
				local test = matrix[x+2*dirx][y+2*diry]
				if test == matrix[x][y] then -- is the value of the same piece color?
					return true
				else
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
	--print("---START OF NEW MOVE---")
	--print("matrix(",x,", ",y,")")
	local matrix = boards[board]["Matrix"]
	--local winningCoordinates = {}--Set each match to another index of table
	--table.insert(winningCoordinates, Vector2.new(x,y))--Initial Test, most recent point placed
	for q=-1,1 do --x offset
		for w=-1,1 do --y offset
			if not(q==0 and w==0) then --8 positions around center
				if not(x+q==0 or x+q==8)then--check to make sure it's within matrix size for +- q
					if not(y+w==0 or y+w==7)then--check to make sure it's within matrix size for +- w
						if matrix[x+q][y+w] then --if the matrix input plus their offsets exists then
							local winningCoordinates = {}--Set each match to another index of table
							table.insert(winningCoordinates, Vector2.new(x,y))--Initial Test, most recent point placed
							local test = matrix[x+q][y+w]
							if test == input then -- two in a row
								table.insert(winningCoordinates, Vector2.new(x+q,y+w))
								--[[Test points assuming it is an end point of a 4-in-a-row condition.
								If this is not true, check for the fourth match on opposite side.
								If that is not true either, we are not interested in this condition.]]--
								local thirdMatch = continueLine(board,x,y,q,w)
								if thirdMatch then --if we have a third match...
									print("Three in a row...")
									table.insert(winningCoordinates, Vector2.new(x+2*q,y+2*w))
									local fourthMatch = continueLine(board,x+q,y+w,q,w)
									if fourthMatch then
										print("Four in a row...")
										table.insert(winningCoordinates, Vector2.new(x+3*q,y+3*w))
										return true, winningCoordinates -- WINNER
									else --not a fourth, so look for the last one on opposite side!
										local fourthMatch = continueLine(board, x+q, y+w, -q, -w)
										if fourthMatch then -- Opposite side exists and matches!
										print("Four in a row...")
										table.insert(winningCoordinates, Vector2.new(x-q,y-w))
										return true, winningCoordinates -- WINNER
										end
									end
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
	boards[board]["GamePieces"]={}
	boards[board]["GameOver"] = false
	local parts = workspace.Boards:FindFirstChild(board).Pieces:GetChildren()
	for i,v in pairs(parts)do
		if v then
			v:Destroy()
		end
	end
end
--[[This function switches to the next player's turn
	given the player who just went, and the board they
	are using
	]]
function changeTurn(player, board)--PlayerName, boardName
	if boards[board][player] then
		for i,v in pairs(boards[board])do
			--if i ~= everything but the opposite player...
			if i ~= "InUse" and i ~= "Matrix" and i ~= player and i ~= "GamePieces" and i~= "GameOver" then--i = next player
				boards[board][player]["Turn"] = false
				boards[board][i]["Turn"] = true
				local player1 = game.Players:FindFirstChild(player)
				local player2 = game.Players:FindFirstChild(i)
				print("Player1 = ",player1)
				print("Player2 = ",player2)
				notifyTurn:FireClient(player1, player2)
				notifyTurn:FireClient(player2, player2)
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
	print(result.CFrame.Position)
	local tweeny = tween:Create(gp,tweenInfo, result)
	tweeny:Play()
	boards[board]["GamePieces"][gp] = Vector2.new(columnNumber, height)
	local winner, coordinates = calculateMove(board, columnNumber, height, boards[board][player]["PlayerNumber"])--Calculate 4-in-a-row
	if winner then
		Winner(board, player, coordinates)
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
	if boards[boardName]["GameOver"] == false then --Check game isn't over
		local column = tonumber(columnNumber)--Get rid of a lot of bugs off the bat.
		for i,v in pairs(boards) do
			if i == boardName then--This board is in boards
				for j,k in pairs(boards[i])do--Cycle through the board's index to find playerName
					if player.Name == j then--This player is playing this board!
						if boards[i][player.Name]["Turn"]==true then
							local valid, y = checkStack(boardName, column)--Can we place a piece, how high?
							if valid then
								boards[i]["Matrix"][column][y] = boards[i][player.Name]["PlayerNumber"]
								placePiece(player.Name, column, i, y)
								if y == 6 then
									local check = checkMatrix(boardName)
									if check then
										tieGame(boardName)
									end
								end
								changeTurn(player.Name, boardName)
							end
						return
						else --It is not your turn!
						end
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
		*CFrame.new(Vector3.new(-35,0.001 , 0)))
		board.Name = board.Name..i
		board.Parent = game.Workspace.Boards
		boards[board.Name] = {}
		boards[board.Name]["InUse"] = false
		makeMatrix(board.Name)
		boards[board.Name]["GamePieces"]={}
		boards[board.Name]["GameOver"] = false
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
end
--[[Starts a game with arguements p1 and p2 which are players
	searches for an open board (not InUse) and claims it
	Teleports players to board and sets up table values
	]]
function startGame(p1, p2)
	if p1 ~= p2 then
		for i,v in pairs(boards) do
			if v.InUse == false then -- if we found a board to use, then insert the players in the board's table
				v.InUse = true
				local playerChoice1, playerChoice2 = nil
				for i,v in pairs(friendColors)do
					if p1.Name == i then
						playerChoice1 = friendColors[i]--Camo for me :D
					elseif p2.Name == i then
						playerChoice2 = friendColors[i]--Camo for me :D
					end
				end
				boards[i][p1.Name] = {	["Wins"] = 0,--Boards[Board1][Player1] = {[Player1's Stats Here]}
										["Color"] = playerChoice1 or Color3.new(1,0,0),--Red}--In the future allow for player choices
										["PlayerNumber"] = 1,
										["Turn"] = false,
										["Partner"] = p2.Name
										}
				boards[i][p2.Name] = {	["Wins"] = 0,
										["Color"] = playerChoice2 or Color3.new(1,1,0),--Yellow}--In the future allow for player choices
										["PlayerNumber"] = 2,
										["Turn"] = false,
										["Partner"] = p1.Name
										}
				local gameBoard = workspace.Boards:FindFirstChild(tostring(i))
				repeat wait() until p1.Character
				--trapCharacter(player1.Character)
				p1.Character.HumanoidRootPart.CFrame = gameBoard.BaseBoardParts.Bottom.CFrame * CFrame.new(5,2,0)
				repeat wait() until p2.Character
				--trapCharacter(player2.Character)
				p2.Character.HumanoidRootPart.CFrame = gameBoard.BaseBoardParts.Bottom.CFrame * CFrame.new(-5,2,0)
			    print(p1,"and",p2,"have started a game on",i)
				notifyColor:FireClient(p1,boards[i][p1.Name]["Color"])
				notifyColor:FireClient(p2,boards[i][p2.Name]["Color"])
				local boardNumber = string.match(i,"1") or string.match(i,"2") or string.match(i,"3") or string.match(i,"4")
				pathShowEvent:FireClient(p1,boardNumber)
				pathShowEvent:FireClient(p2,boardNumber)
				local random = Random.new()
				local turn = random:NextInteger(1,2)
				if turn == 1 then
					boards[i][p1.Name]["Turn"] = true
					notifyTurn:FireClient(p1, p1)
					notifyTurn:FireClient(p2, p1)
				elseif turn == 2 then
					boards[i][p2.Name]["Turn"] = true
					notifyTurn:FireClient(p2, p2)
					notifyTurn:FireClient(p1, p2)
				else print("Error, turn is broken on generate!")
				end
				break
			end
		end
	else print("Error: can't play against self")
	end
end
--[[This function checks the queue table for players
	If there is enough to start a game, start one
	If there is more than enough, start one, then requeue
	]]
function startQueue()
	for i,v in pairs(queue)do
	notifyColor:FireClient(v, Color3.new(1,1,1))
	notifyTurn:FireClient(v,"Queue")
	end
	if #queue == 2 then-- Enough to queue one game
		if queue[1]~=nil and queue[2] ~= nil then
		startGame(queue[1],queue[2])--Start a game with both players
		print(queue[1], "and", queue[2])
		queue = {}
		print("=2")
		end
	elseif #queue > 2 then-- An extra player(s) will remain
		if queue[1]~=nil and queue[2] ~= nil then
		startGame(queue[1],queue[2])
		table.remove(queue,2)
		table.remove(queue,1)
		print(">2")
		startQueue()
		end
	else print("<2 - need more players")
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
	-Call cleanup board funct.
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
--Initializing of boards, only runs one time at start of server!
spawnBoards()
