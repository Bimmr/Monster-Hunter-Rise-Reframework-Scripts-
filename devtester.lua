local updateHook = {
    path = "snow.player.___",
    field = "_",
    value = ""
}
local playerData = {
    field = "",
    method = "",
    value = ""
}
local function getPlayerData()
    local playman = sdk.get_managed_singleton("snow.player.PlayerManager")
    local playerbase = playman:call("findMasterPlayer")
    local pd = playerbase:call("get_PlayerData")
    if playerData.field == "" then
        return pd:call(playerData.method)
    end
    return pd:get_field(playerData.field)
end

local function createUpdateHook()
    sdk.hook(sdk.find_type_definition(updateHook.path):get_method("update"), function(args)
        local obj = sdk.to_managed_object(args[2])
        if not obj then
            value = "No Object"
            return
        end
        local value = obj:get_field(updateHook.field)
        if type(value) == "table" or type(value) == 'userdata' then
            value = json.dump_string(value)
            
        end
            updateHook.value = value
    end, function(retval)
    end)
end
re.on_frame(function()
    draw.text("UH Value: " .. tostring(updateHook.value), 10, 10, "0xFFFFFFFF")
    draw.text("PD Value: " .. getPlayerData(), 10, 25, "0xFFFFFFFF")
end)

re.on_draw_ui(function()

    imgui.begin_window("Dev Menu", nil, ImGuiWindowFlags_AlwaysAutoResize)
    local changed = false
    imgui.text("[Update Hook]")
    changed, updateHook.path = imgui.input_text("UH Path", updateHook.path)
    changed, updateHook.field = imgui.input_text("UH Field", updateHook.field)
    if imgui.button("Start Hook") then
        createUpdateHook()
    end
    imgui.new_line()
    imgui.text("[Player Data]")
    changed, playerData.field = imgui.input_text("PD Field", playerData.field)
    imgui.text("[Player Data]")
    changed, playerData.method = imgui.input_text("PD Method", playerData.method)
    imgui.new_line()
    imgui.end_window()
end)
