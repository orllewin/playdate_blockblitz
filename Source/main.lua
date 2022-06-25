--[[ 

  Playdate is 400x240
  Block Blitz has a game grid of 20x31 16x8 cells (well, 8x8 with a 2:1 horizontal scale)
  The zeroth row is score, we'll lose that for now...
  
  Width:
  This implementation doubles the cell width and uses 20 columns of 16 = 320 pixels, then adds 
  a horizontal offset of 40.
  
  Height:
  If we stick to 8 pixel high cells we end up with 30 rows, which is perfect, same as the original
  
  Note. I've deliberately hacked this together in a single file, it's not meant to be well written.
  
]] 

local DEBUG = false
local level = 4
local playerXIndex = 10
local playerYIndex = 27
local craneIndex = -1
local brickXIndex = -1
local brickYIndex = -1

import "CoreLibs/sprites"

local graphics <const> = playdate.graphics

--We're at 10fps to mimic a BBC micro so don't need these optimisations but...
local fmod <const> = math.fmod
local random <const> = math.random

-- 1 empty
-- 2 solid
-- 3 gantry
-- 4 full brick
-- 5 half brick
-- 6 crane
-- 7 falling brick
local imageTable = graphics.imagetable.new("frames")

local rowMaps = {}
for i=1,30 do
  rowMaps[i] = graphics.tilemap.new()
  rowMaps[i]:setImageTable(imageTable)
	rowMaps[i]:setTiles({1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, 320)--preset to blank...
end

function buildLevel()
  for i=29,29-(level-1),-1 do
    if(fmod(i,2) == 0)then
      rowMaps[i]:setTiles({4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4}, 320)
    else
      rowMaps[i]:setTiles({5, 5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5, 5}, 320)
    end
  end
  rowMaps[29 - level]:setTiles({3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 3}, 320)
end

rowMaps[1]:setTiles({3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}, 320)--Gantry
rowMaps[6]:setTiles({3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 3}, 320)--Final/Target Level
rowMaps[30]:setTiles({2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2}, 320)--Floor
buildLevel()

local playerDefault = playdate.graphics.image.new("player_default")
local playerLeft = playdate.graphics.image.new("player_left")
local playerRight = playdate.graphics.image.new("player_right")

local playerSprite = playdate.graphics.sprite.new(playerDefault)
local craneSprite = playdate.graphics.sprite.new(imageTable:getImage(6))
local fallingBrickSprite = playdate.graphics.sprite.new(imageTable:getImage(7))--todo - new image

local playerMinX = 32
local playerMaxX = 272

playdate.display.setRefreshRate(10)
playdate.graphics.setBackgroundColor(playdate.graphics.kColorBlack)
playdate.display.setOffset(40, 0)

--Crane 
local CraneStates = {Seeking = 0, Deciding = 1, ExitingLeft = 2, ExitingRight = 3}
local craneState = CraneStates.Seeking
craneSprite:setCenter(0, 0)
craneSprite:moveTo(craneIndex * 16, 8)
craneSprite:add()

local brickFalling = false
fallingBrickSprite:setCenter(0, 0)
fallingBrickSprite:moveTo(brickXIndex * 16, brickYIndex * 16)
fallingBrickSprite:add()

playerSprite:setCenter(0, 0)
playerSprite:moveTo(playerXIndex * 16, playerYIndex * 8)
playerSprite:add()

function playdate.update()
  playdate.graphics.clear()
  
  if(playdate.buttonIsPressed(playdate.kButtonLeft))then
    playerSprite:setImage(playerLeft)
    if(playerSprite.x > playerMinX)then
			--check block to left and block to left and above
			local tileLeft = rowMaps[playerYIndex+2]:getTileAtPosition(playerXIndex, 1)
			
			-- brick to left
			if(tileLeft == 7)then
				
				-- but is there a brick above that
				local tileLeftAbove = rowMaps[playerYIndex+1]:getTileAtPosition(playerXIndex, 1)
				if(tileLeftAbove == 7)then
					--can't move
				else
					-- move up
					playerXIndex -= 1
					playerYIndex -= 1
				end
			else
				-- no brick to left, but how about below
				local tileLeftBelow = rowMaps[playerYIndex+3]:getTileAtPosition(playerXIndex, 1)
				if(tileLeftBelow == 7 or tileLeftBelow == 2)then
					playerXIndex -= 1
				else
					local tileLeft2Below = rowMaps[playerYIndex+4]:getTileAtPosition(playerXIndex, 1)
					if(tileLeft2Below == 1)then
						--can't move
					else
						playerXIndex -= 1
						playerYIndex += 1
					end
				end
			end		
			playerSprite:moveTo(playerXIndex * 16, playerYIndex * 8)
    end
  elseif(playdate.buttonIsPressed(playdate.kButtonRight))then
		playerSprite:setImage(playerRight)
		if(playerSprite.x < playerMaxX)then
    	--check block to right and block to right and above
			local tileRight = rowMaps[playerYIndex+2]:getTileAtPosition(playerXIndex + 2, 1)
			if(tileRight == 7)then
				local tileRightAbove = rowMaps[playerYIndex+1]:getTileAtPosition(playerXIndex + 2, 1)
				if(tileRightAbove == 7)then
					--can't move
				else
					playerXIndex += 1
					playerYIndex -= 1
				end
			else
				-- no brick to left, but how about below
				local tileRightBelow = rowMaps[playerYIndex+3]:getTileAtPosition(playerXIndex + 2, 1)
				if(tileRightBelow == 7 or tileRightBelow == 2)then
					playerXIndex += 1
				else
					local tileRight2Below = rowMaps[playerYIndex+4]:getTileAtPosition(playerXIndex + 2, 1)
					if(tileRight2Below == 1)then
						--can't move
					else
						playerXIndex += 1
						playerYIndex += 1
					end
				end
			end		
			playerSprite:moveTo(playerXIndex * 16, playerYIndex * 8)
		end
  else
    playerSprite:setImage(playerDefault)
  end
  
  playdate.graphics.sprite.update()
    

  if(DEBUG) then
    graphics.setColor(playdate.graphics.kColorWhite)
    local y = 0
    while y < 240 do
      graphics.drawLine(0, y, 320, y)
      y = y + 8
    end
    
    local x = 0
    while x < 320 do
      graphics.drawLine(x, 0, x, 240)
      x = x + 16
    end
  end
  
  for i=1,#rowMaps do
    rowMaps[i]:draw(0, (i-1)*8)
  end
  
	updateBrick()
  craneMove()
  drawBrickOutlines()
end

function updateBrick()
	if(brickFalling)then
		brickYIndex += 1
		local tile = rowMaps[brickYIndex]:getTileAtPosition(brickXIndex+1, 1)		
		if(tile == 1)then
			fallingBrickSprite:moveTo(brickXIndex * 16, brickYIndex * 8)
		else
			local tiles = rowMaps[brickYIndex-1]:setTileAtPosition(brickXIndex + 1, 1, 7)
			rowMaps[brickYIndex-1]:draw(0, (brickYIndex-2)*8)
			brickFalling = false
		end
	end
end

function craneMove()
  if(craneState == CraneStates.Seeking)then
    if(craneIndex == playerXIndex)then
      --Above player, drop or shuffle position
      craneState = CraneStates.Deciding
    elseif(craneIndex < playerXIndex)then
      --to left of player, move right
      craneIndex += 1
      craneSprite:moveTo(craneIndex * 16, 8)
    else
      --to right of player, move left
      craneIndex -= 1
      craneSprite:moveTo(craneIndex * 16, 8)
    end
  elseif(craneState == CraneStates.Deciding)then
    if(random() < 0.25)then
      if(random() < 0.5)then
        craneIndex += 1
        craneSprite:moveTo(craneIndex * 16, 8)
        if(random() < 0.25)then
          dropBrick(craneIndex)
          craneExit()
        else
          craneState = CraneStates.Seeking
        end
      else 
        craneIndex -= 1
        craneSprite:moveTo(craneIndex * 16, 8)
        if(random() < 0.25)then
          dropBrick(craneIndex)
          craneExit()
        else
          craneState = CraneStates.Seeking
        end
      end
    else
      if(brickFalling == false)then
        dropBrick(craneIndex)
      end
      craneExit()
    end
  elseif(craneState == CraneStates.ExitingLeft)then
    if(craneIndex >= 0)then
      craneIndex -= 1
      craneSprite:moveTo(craneIndex * 16, 8)
    else
      craneState = CraneStates.Seeking
    end
  elseif(craneState == CraneStates.ExitingRight)then
    if(craneIndex < 19)then
      craneIndex += 1
      craneSprite:moveTo(craneIndex * 16, 8)
    else
      craneState = CraneStates.Seeking
    end
  end
end

function dropBrick(index)
  brickFalling = true
  brickXIndex = index
  brickYIndex = 3
end

function craneExit()
  if(craneIndex <= 10)then
    craneState = CraneStates.ExitingLeft
  else
    craneState = CraneStates.ExitingRight
  end
end

function drawBrickOutlines()
  graphics.setColor(playdate.graphics.kColorWhite)
  graphics.drawRect(0, 232 - (level * 8), 32, (level * 8))
  graphics.drawRect(288, 232 - (level * 8), 32, (level * 8))
end