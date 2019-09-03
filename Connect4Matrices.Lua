local board = {} --6 by 7 matrix from (1,1) to (6,7)
function getMatrixCoords(x,y)
  if x == 1 then -- left side
    if y == 1 then -- bottom left corner
    elseif y == 6 then -- top left corner'
    else -- just left side wall
  if x == 7 then -- right side
    if y == 1 then -- bottom right corner
    elseif y == 6 then top right corner
    else -- just right side wall
