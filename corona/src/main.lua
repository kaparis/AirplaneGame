-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Load Classes
-------------------------------------------------------------------------------

local physics = require( "physics" )
physics.start()
physics.setGravity(0, 0)

-- Seed the random number generator
math.randomseed( os.time() )

-------------------------------------------------------------------------------
-- Variables & Constants
-------------------------------------------------------------------------------
local _W = display.contentWidth
local _H = display.contentHeight


local title
local playBtn
local creditsBtn
local titleView
	
local creditsView

local player

local enemiesSpawned = 0
local enemiesTable = {} 

local lives = 3
local score = 0
local level = 1
local isAlive = true
local gameLoopTimer
local scoreText
local levelText
local lastKeyPress

--local shotSound = audio.loadSound('gun-sound.wav')

-- Set up display groups
local backGroup = display.newGroup()  -- Display group for the background image
local levelGroup = display.newGroup()  -- Display group for the ships
local uiGroup = display.newGroup()    -- Display group for UI objects like the score

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-- Load Level
function levelSetup()
    display.setStatusBar(display.HiddenStatusBar)

    --Load Player
    player = display.newImageRect( levelGroup, "assets/Aircraft_01.png", 110,92 )
    player.x = display.contentCenterX
    player.y = display.contentCenterY + 200
    player.myName = "player"
    physics.addBody( player, "dynamic", { radius=50, isSensor=true } )

    scoreText = display.newText( uiGroup, "Score: " .. score, 250,  0, native.systemFont, 21 )
    livesText = display.newText( uiGroup, "Lives: " .. lives, 150, 0, native.systemFont, 21 )
    levelText = display.newText(uiGroup,"Level: " .. level, 50, 0, native.systemFont, 21 )
    --14:55:28.109  cx:160
    --14:55:28.109  xy:240
    --14:55:28.109  ch:480
    --14:55:28.109  cw:320

    --Create global screen boundaries
    --local leftWall = display.newRect(0,0,1, display.contentHeight*2 )
    --local rightWall = display.newRect (display.contentWidth, 0, 1, display.contentHeight*2)
    --local topWall = display.newRect (0, -40, display.contentWidth, 0)
    --local bottomWall = display.newRect (0, display.contentHeight, display.contentHeight, 1)
    --leftWall.strokeWidth = 3
    --rightWall.strokeWidth = 3
    --topWall.strokeWidth = 3
    --bottomWall.strokeWidth = 3
    --physics.addBody (leftWall, "static", { bounce = 0.1} )
    --physics.addBody (rightWall, "static", { bounce = 0.1} )
    --physics.addBody (topWall, "static", { bounce = 0.1} )
    --physics.addBody (bottomWall, "static", { bounce = 0.1} )
    

    -- Add Shoot Ability
    local function onShoot()

        local newbullet = display.newImageRect( levelGroup, "assets/bullet_2_blue.png", 10, 26 )
        physics.addBody( newbullet, "dynamic", { isSensor=true } )
        newbullet.isBullet = true
        newbullet.myName = "shot"
    
        newbullet.x = player.x
        newbullet.y = player.y
        newbullet:toBack()
        
        transition.to( newbullet, { 
            y=-100, 
            time=2000, 
            onComplete = function() display.remove( newLaser ) end
            } )
    end
    
    player:addEventListener( "tap", onShoot )
    
    -- Add Movement Ability
    local function onDragPlayer( event )
        local player = event.target
        local phase = event.phase
    
        if ( "began" == phase ) then
            -- Set touch focus on the player
            display.currentStage:setFocus( player )
            -- Store initial offset position
            player.touchOffsetX = event.x - player.x
        elseif ( "moved" == phase ) then
            -- Move the ship to the new touch position
            player.x = event.x - player.touchOffsetX
        elseif ( "ended" == phase or "cancelled" == phase ) then
            -- Release touch focus on the ship
            display.currentStage:setFocus( nil )
        end
    
        return true  -- Prevents touch propagation to underlying objects
    end
    
    player:addEventListener( "touch", onDragPlayer )

    -- Keyboard Event Manager
    local function onKeyEvent( event )        
        --Print which key was pressed down/up
        --local message = "Key '" .. event.keyName .. "' was pressed " .. event.phase
        --print( message )

        if ( event.phase == "down" and event.keyName == "left" ) then
            player:setLinearVelocity( -100, 0 )    
        elseif ( event.phase == "down" and event.keyName == "right" ) then
            player:setLinearVelocity( 100, 0 )
        elseif ( event.phase == "down" and event.keyName == "up" ) then
            player:setLinearVelocity( 0, -100 )
        elseif ( event.phase == "down" and event.keyName == "down" ) then
            player:setLinearVelocity( 0, 100 )
        elseif ( event.phase == "down" and event.keyName == "space" ) then
            onShoot()
        elseif ( event.keyName ~= "space" and event.keyName == lastKeyPress) then
            player:setLinearVelocity( 0, 0 )
        end

        -- Stop Player from exiting screen
        --if ( player.x <= 0 or player.x > display.contentWidth or
        --    player.y <= 0 or player.y > display.contentHeight + 100 )
        --then
        --    player:setLinearVelocity( 0, 0 )
        --end

        lastKeyPress = event.keyName

        -- If the "back" key was pressed on Android, prevent it from backing out of the app
        if ( event.keyName == "back" ) then
            if ( system.getInfo("platform") == "Android" ) then
                return true
            end
        end
    
        -- IMPORTANT! Return false to indicate that this app is NOT overriding the received key
        -- This lets the operating system execute its default handling of the key
        return false
    end

    Runtime:addEventListener( "key", onKeyEvent )

end -- function levelSetup()

local function createEnemies(dt)

    local newEnemy = display.newImageRect( levelGroup, "assets/Aircraft_02.png", 110, 92 )
    newEnemy:rotate( 180 )
    table.insert( enemiesTable, newEnemy )
    physics.addBody( newEnemy, "dynamic", { radius=40 } )
    newEnemy.myName = "enemy"

    newEnemy.x = math.random( 50,display.contentWidth - 50 )
    newEnemy.y = math.random( 50, 270 ) * -1
    newEnemy:setLinearVelocity( 0, 50 )

end

local function restorePlayer()
    
    player.isBodyActive = false
    player.x = display.contentCenterX
    player.y = display.contentHeight - 100

    -- Fade in the ship
    transition.to( player, { alpha=1, time=4000,
        onComplete = function()
            player.isBodyActive = true
            died = false
        end
    } )
end

local function clearEnemies()
    -- Remove enemies on screen
    for i = #enemiesTable, 1, -1 do
        local thisenemy = enemiesTable[i]
        display.remove( thisenemy )
        table.remove( enemiesTable, i )
    end
end

local function onCollision( event )
    if ( event.phase == "began" ) then
        local obj1 = event.object1
        local obj2 = event.object2
  
        print (obj1)
        print (obj2)

        if ( ( obj1.myName == "shot" and obj2.myName == "enemy" ) or
            ( obj1.myName == "enemy" and obj2.myName == "shot" ) ) then
            display.remove( obj1 )
            display.remove( obj2 )

            for i = #enemiesTable, 1, -1 do
                if ( enemiesTable[i] == obj1 or enemiesTable[i] == obj2 ) then
                    table.remove( enemiesTable, i )
                    break
                end
            end

            -- Increase score
            score = score + 100
            scoreText.text = "Score: " .. score

        elseif ( ( obj1.myName == "enemy" and obj2.myName == "player" ) or
                ( obj1.myName == "player" and obj2.myName == "enemy" ) ) then
            
                    if ( died == false ) then
                died = true
            end

            -- Update lives
            lives = lives - 1
            livesText.text = "Lives: " .. lives

            -- Out of Lives
            if ( lives <= 0 ) then
                display.remove( ship )
            else
                player.alpha = 0
                clearEnemies()
                timer.performWithDelay( 1000, restorePlayer )
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Main Function
-------------------------------------------------------------------------------
levelSetup()
Runtime:addEventListener( "collision", onCollision )

local function gameLoop()
    createEnemies()
    
    -- Remove enemies which have drifted off screen
    for i = #enemiesTable, 1, -1 do
        local thisenemy = enemiesTable[i]
 
        if ( thisenemy.x < -100 or
             thisenemy.x > display.contentWidth + 100 or
             thisenemy.y < -100 or
             thisenemy.y > display.contentHeight + 100 )
        then
            display.remove( thisenemy )
            table.remove( enemiesTable, i )
        end
    end

end

gameLoopTimer = timer.performWithDelay( 500, gameLoop, 0 )