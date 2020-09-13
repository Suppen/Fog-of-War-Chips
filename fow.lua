-- GUID of the FoW zone this handler handles
fowGuid = nil
-- Flag telling whether or not the save timer is running
timerIsRunning = false

-- Handler for the object's load event
function onload()
    -- Check if there are any saved data in the GM notes
    local isSetup = false
    local saved_data = self.getGMNotes()
    if saved_data ~= "" then
        -- Try to set up the zone from the saved data
        isSetup = pcall(initFromSavedData, saved_data)

        -- If the initialization failed, notify the user
        if not isSetup then
            print("Could not load FoW zone from storage")
        end
    end

    -- If the FoW zone has not been set up for some reason, show the setup button
    if not isSetup then
        createSetupButton()
    end
end

-- Handler for the object's destroy event
function onDestroy()
    -- Destroy the linked FoW zone
    destroyFoWZone()

    -- Stop the save timer
    stopSaveTimer()
end

-- Destroys the linked FoW zone. Does nothing if it does not exist
function destroyFoWZone()
    local fowZone = getObjectFromGUID(fowGuid)
    if fowZone ~= nil then
        fowZone.destruct()
    end
end

-- Initializes the FoW zone from saved data
function initFromSavedData(saved_data)
    -- Parse it as JSON
    local loaded_data = JSON.decode(saved_data)

    -- Check if the linked zone exists, and create it if it doesn't
    local fowZone = getObjectFromGUID(loaded_data.fowGuid)
    if fowZone == nil then
        spawnFromJSON(loaded_data.json)
    else
        fowGuid = fowZone.getGUID()
    end
end

-- Makes the setup button
function createSetupButton()
    self.clearButtons()
    self.createButton({
        label = "Setup",
        click_function = "buttonClick_setup",
        function_owner = self,
        position = {0,0.3,0},
        rotation = {0,180,0},
        height = 350,
        width = 800,
        font_size = 250,
        color = {0,0,0},
        font_color = {1,1,1}
    })
end

-- Handles clicks on the setup button
function buttonClick_setup()
    -- Lock the object so it isn't accidently moved. All the FoW buttons will move with it if it is
    self.setLock(true)

    -- Remove all existing buttons
    self.clearButtons()

    -- Create new buttons over each FoW zone
    createButtonsOnAllFoWObjects()
end

-- Makes the save button
function createSaveButton()
    self.clearButtons()
    self.createButton({
        label = "Save",
        click_function = "buttonClick_save",
        function_owner = self,
        position = {0,0.3,0},
        rotation = {0,180,0},
        height = 350,
        width = 800,
        font_size = 250,
        color = {0,0,0},
        font_color = {1,1,1}
    })
end

-- Handles clicks on the save button
function buttonClick_save()
    saveState()
    print("FoW state saved")
end

--Creates selection buttons on FoW zones. Mostly copied from the workshop item "FoW on a tray"
function createButtonsOnAllFoWObjects()
    local numberOfButtons = 0
    for _, obj in ipairs(getAllObjects()) do
        if obj.name == "FogOfWar" then
            numberOfButtons = numberOfButtons+1
            local objGUID = obj.getGUID()
            --On a normal bag, the button positions aren't the same size as the bag.
            globalScaleFactor = 1 * 1/self.getScale().x
            --Super sweet math to set button positions
            local selfPos = self.getPosition()
            local objPos = obj.getPosition()
            local deltaPos = findOffsetDistance(selfPos, objPos, obj)
            local objPos = rotateLocalCoordinates(deltaPos, self)
            objPos.x = -objPos.x * globalScaleFactor
            objPos.y = objPos.y * globalScaleFactor
            objPos.z = objPos.z * globalScaleFactor
            --Offset rotation of bag
            local rot = self.getRotation()
            rot.y = -rot.y + 180
            --Create the button
            local funcName = "selectButton_" .. objGUID
            local func = function() linkWithFoWZone(objGUID) end
            self.setVar(funcName, func)
            self.createButton({
                click_function=funcName,
                function_owner=self,
                position=objPos,
                rotation=rot,
                height=500,
                width=500,
                color={0.75,0.25,0.25,0.6},
            })
        end
    end

    if numberOfButtons == 0 then
        print("No FoW zones found")
        createSetupButton()
    end
end

--Find delta (difference) between 2 x/y/z coordinates. Copied from the workshop item "FoW on a tray"
function findOffsetDistance(p1, p2, obj)
    local deltaPos = {}
    local bounds = obj.getBounds()
    deltaPos.x = (p2.x-p1.x)
    deltaPos.y = (p2.y-p1.y) + (bounds.size.y - bounds.offset.y)
    deltaPos.z = (p2.z-p1.z)
    return deltaPos
end

--Used to rotate a set of coordinates by an angle. Copied from the workshop item "FoW on a tray"
function rotateLocalCoordinates(desiredPos, obj)
    local objPos, objRot = obj.getPosition(), obj.getRotation()
    local angle = math.rad(objRot.y)
    local x = desiredPos.x * math.cos(angle) - desiredPos.z * math.sin(angle)
    local z = desiredPos.x * math.sin(angle) + desiredPos.z * math.cos(angle)
    --return {x=objPos.x+x, y=objPos.y+desiredPos.y, z=objPos.z+z}
    return {x=x, y=desiredPos.y, z=z}
end

-- Spawns a FoW zone from a JSON string and links it to this object
function spawnFromJSON(json)
    -- If created immediately, some timing issue with One World causes other objects to be hidden, even when in a revealed part of the FoW. Compensate by waiting a bit before creating the zone
    Wait.frames(function()
        spawnObjectJSON({
            json = json,
            callback_function = function(obj) linkWithFoWZone(obj.getGUID()) end
        })
    end, 30)
end

--Links the FoW handler with a FoW zone
function linkWithFoWZone(guid)
    -- Store the zone's GUID
    fowGuid = guid

    -- Change the buttons
    self.clearButtons()
    createSaveButton()

    -- Save the zone's state and start the save timer
    saveState()
    startSaveTimer()
end

-- Starts the saving timer, if it is not already running
function startSaveTimer()
    if not timerIsRunning then
        timerIsRunning = true
        Timer.create({
            identifier = self.getGUID(),
            repetitions = 0, -- Infinite
            function_name = "saveState",
            delay = 60
        })
    end
end

-- Stops the saving timer, if it is running
function stopSaveTimer()
    if timerIsRunning then
        Timer.destroy(self.getGUID())
        timerIsRunning = false
    end
end

-- Saves the state of the FoW zone to the GM description of the handler
function saveState()
    local fowZone = getObjectFromGUID(fowGuid)
    if fowZone ~= nil then
        self.setGMNotes(JSON.encode({
           fowGuid = fowGuid,
           json = fowZone.getJSON()
        }))
    else
        print("Could not find FoW zone linked to \"" .. self.getName() .. "\". Was it deleted? If that was intended, please also delete the corresponding FoW token")
        stopSaveTimer()
    end
end
