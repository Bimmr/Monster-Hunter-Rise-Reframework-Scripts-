-- Settings for text
local settings = {
    textSettings = {
        enabled = true,
        textColour = "0xFFFFFFFF",
        location = {
            x = 153,
            y = 125
        },
        levels = {
            [0] = "0xd60000FF",
            [1] = "0xA7A3D5F4",
            [2] = "0xffffb224",
            [3] = "0xFF00FF00"
        }
    },
    -- Settings for icons
    iconSettings = {
        enabled = true,
        shape = 1, -- {circle, square}
        colour = "0x80313131",
        size = 6,
        spacing = 4,
        offset = 0
    }
}
-- Variables
local configure = false;
local level = 0;
local screenSize = {
    width = 0,
    height = 0
}
local configPath = "BowLevelIndicator.json"

-- Load the config
local function loadConfig()
    if json ~= nil then
        local file = json.load_file(configPath)
        if file then
            settings = file
        end
    end
end
loadConfig()

-- Save the config
local function saveConfig()
    json.dump_file(configPath, settings)
end

-- Get Quest Status
local function getQuestState()
    local quest = sdk.get_managed_singleton("snow.QuestManager")
    if not quest then
        return
    end
    return quest:get_field("_QuestStatus")
end

-- Function to get the window size
local function getWindowSize()
    local sceneManager = sdk.get_native_singleton("via.SceneManager");
    if not sceneManager then
        return
    end
    local sceneView = sdk.call_native_func(sceneManager, sdk.find_type_definition("via.SceneManager"), "get_MainView");
    if not sceneView then
        return
    end
    local sceneSize = sceneView:call("get_Size");
    if not sceneSize then
        return
    end
    local lwidth = sceneSize:get_field("w");
    if not lwidth then
        return
    end
    local lheight = sceneSize:get_field("h");
    if not lheight then
        return
    end
    screenSize = {
        width = lwidth,
        height = lheight
    }
end

-- Hook to get the Bow Level
sdk.hook(
    sdk.find_type_definition("snow.player.Bow"):get_method("update"), 
    function(args)
        local bow = sdk.to_managed_object(args[2])
        if not bow then
            return
        end
        level = bow:get_field("<ChargeLv>k__BackingField")
    end, 
    function(retval)
    end
)

re.on_frame(function()
    if screenSize.width == 0 then
        getWindowSize()
    end

    -- TODO: Find a way to check if the player is aiming, and use that instead
    if getQuestState() == 2 then

        -- Draw text level
        if settings.textSettings.enabled then
            draw.text("Bow Level: ", settings.textSettings.location.x + 1, settings.textSettings.location.y + 1,
                "0xFF000000")
            draw.text("Bow Level: ", settings.textSettings.location.x, settings.textSettings.location.y,
                settings.textSettings.textColour)

            draw.text(level, settings.textSettings.location.x + 70 + 1, settings.textSettings.location.y + 1,
                "0xFF000000")
            draw.text(level, settings.textSettings.location.x + 70, settings.textSettings.location.y,
                settings.textSettings.levels[level])
        end

        -- Draw Icons
        if settings.iconSettings.enabled then
            if level > 0 then
                local lastX = screenSize.width / 2 - settings.iconSettings.size / 2 -
                                  (settings.iconSettings.size * (level + 1) / 2) -
                                  (settings.iconSettings.spacing * (level + 1) / 2)
                for i = 0, level - 1 do
                    local x = lastX + settings.iconSettings.size + settings.iconSettings.spacing
                    lastX = x

                    -- Draw a square
                    if settings.iconSettings.shape == 2 then
                        draw.filled_rect(x, screenSize.height / 2 - settings.iconSettings.size / 2,
                            settings.iconSettings.size, settings.iconSettings.size, settings.iconSettings.colour)
                        draw.outline_rect(x, screenSize.height / 2 - settings.iconSettings.size / 2,
                            settings.iconSettings.size, settings.iconSettings.size, settings.iconSettings.colour)

                        -- Draw a circle
                    elseif settings.iconSettings.shape == 1 then
                        x = x + settings.iconSettings.size / 2
                        local y = screenSize.height / 2
                        local radius = settings.iconSettings.size / 2
                        local angle = 0
                        local step = math.pi * 2 / settings.iconSettings.size
                        for i = 0, settings.iconSettings.size do
                            local x1 = x + radius * math.cos(angle)
                            local y1 = y + radius * math.sin(angle)
                            local x2 = x + radius * math.cos(angle + step)
                            local y2 = y + radius * math.sin(angle + step)
                            draw.line(x1, y1, x2, y2, settings.iconSettings.colour)
                            angle = angle + step
                        end
                    end
                end
            end
        end
    end
end)

re.on_draw_ui(function()
    local changed = false

    if (imgui.button("Bow Level Indicator")) then
        configure = true
    end
    if configure and imgui.begin_window("Bow Level Indicator Config", true, ImGuiWindowFlags_AlwaysAutoResize) then
        if imgui.tree_node("[Text]") then

            changed, settings.textSettings.enabled = imgui.checkbox("Enabled", settings.textSettings.enabled)
            if changed then saveConfig() end
            imgui.text("Position")
            changed, settings.textSettings.location.x = imgui.drag_int("X", settings.textSettings.location.x,
                1, 0, screenSize.width)
                if changed then saveConfig() end
            changed, settings.textSettings.location.y = imgui.drag_int("Y", settings.textSettings.location.y,
                1, 0, screenSize.height)
                if changed then saveConfig() end
            if imgui.tree_node("Text Colour") then
                changed, settings.textSettings.textColour = imgui.color_picker("Text Colour",
                    settings.textSettings.textColour)
                    if changed then saveConfig() end
                imgui.tree_pop()
            end

            for i = 0, 3 do
                if imgui.tree_node("Level " .. i ) then
                    changed, settings.textSettings.levels[i] =
                        imgui.color_picker("Level " .. i, settings.textSettings.levels[i])
                        if changed then saveConfig() end
                    imgui.tree_pop()
                end
            end

            imgui.tree_pop()
        end

        if imgui.tree_node("[Icon]") then
            changed, settings.iconSettings.enabled = imgui.checkbox("Enabled", settings.iconSettings.enabled)
            if changed then saveConfig() end
            local possibleShapes = {"Circle", "Square"}
            changed, settings.iconSettings.shape = imgui.combo("Shape", settings.iconSettings.shape, possibleShapes)
            if changed then saveConfig() end

            if imgui.tree_node("Colour") then
                changed, settings.iconSettings.colour = imgui.color_picker("Colour", settings.iconSettings.colour)
                if changed then saveConfig() end
                imgui.tree_pop()
            end
            changed, settings.iconSettings.size = imgui.drag_int("Size", settings.iconSettings.size, 1, 0, 50)
            if changed then saveConfig() end
            changed, settings.iconSettings.spacing = imgui.drag_int("Spacing", settings.iconSettings.spacing, 1, 0, 20)
            if changed then saveConfig() end
            changed, settings.iconSettings.offset = imgui.drag_int("Offset", settings.iconSettings.offset, 1, screenSize.height/2*-1, screenSize.height/2)
            if changed then saveConfig() end

            imgui.tree_pop()
        end

        imgui.end_window()
    else
        configure = false
    end
end)
