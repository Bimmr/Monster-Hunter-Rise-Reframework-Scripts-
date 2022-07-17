local calls = {{
    path = "snow.data.FacilityDataManager",
    instructions = {{
        type = 2,
        name = "_Kitchen",
        operation = 1
    }, {
        type = 2,
        name = "_MealFunc",
        operation = 1
    }, {
        type = 2,
        name = "<AvailableDangoList>k__BackingField",
        operation = 1
    }, {
        type = 1,
        name = "get_Item",
        args = 1,
        operation = 1
    }, {
        type = 2,
        name = "_Param",
        operation = 1
    }, {
        type = 2,
        name = "_Id",
        operation = 1
    }}
}, {
    path = "snow.data.FacilityDataManager",
    instructions = {{
        type = 2,
        name = "_Kitchen",
        operation = 1,
        args = nil
    }, {
        type = 2,
        name = "_MealFunc",
        operation = 1
    }, {
        type = 2,
        name = "_MealTicketFlag",
        operation = 2,
        value = "true"
    }}
}, {
    -- local typeOptions = {"Method", "Field", "ArrayIndex"}
    -- local operationOptions = {"Get", "Set", "Call"}
    path = "snow.player.PlayerManager",
    instructions = {{
        type = 2,
        name = "PlayerList",
        operation = 1
    }, {
        type = 3,
        name = "0",
        operation = 1
    }, {
        type = 2,
        name = "_ShotDamageUpDurationTimer",
        operation = 1
    }}
}}

local hooks = {{
    path = "snow.facility.kitchen.MealFunc",
    method = "update",
    time = 1,
    prehook = 1,
    instructions = {{
        type = 2,
        name = "_MealTicketFlag",
        operation = 2,
        value = true
    }}
}}

-- sdk.hook(sdk.find_type_definition(updateHook.path):get_method("update"), pre(args), post(args))
local function stringify(obj)
    if type(obj) == "table" then
        obj = json.dump_string(obj)
    else
        obj = tostring(obj)
    end
    return obj
end

-- local typeOptions = {"Method", "Field", "ArrayIndex"}
-- local operationOptions = {"Get", "Set", "Call"}
local function performInstructions(last, instructions)
    if not last then return "Error with Singleton" end
    for i, instruction in ipairs(instructions) do
        if instruction.type == 1 then
            local args = nil
            if not (instruction.args == nil or instruction.args == "") then args = instruction.args end
            if args then log.debug("args: " .. args) end
            if instruction.operation == 1 or instruction.operation == 3 then
                if not args then
                    last = last:call(instruction.name) -- TODO: Split args
                else
                    last = last:call(instruction.name, args) -- TODO: Split args
                end
            elseif instruction.operation == 2 then
                last = last:call(instruction.name, instruction.value)
            end
        elseif instruction.type == 2 then
            if instruction.operation == 1 then
                last = last:get_field(instruction.name)
            elseif instruction.operation == 2 then
                last:set_field(instruction.name, instruction.value)
            end
        elseif instruction.type == 3 then
            last = last[instruction.name]
        end
        if last == nil then
            instruction.status = "Instruction " .. i .. " returned nil"
            return "Instruction " .. i .. " returned nil"
        else
            instruction.status = "Success"
        end
    end
    return stringify(last)
end

local function initHook(hook)
    local path = hook.path
    local method = hook.method
    local time = hook.time
    local prehook = hook.prehook
    local instructions = hook.instructions
    local hook = sdk.find_type_definition(path):get_method(method)
    sdk.hook(hook, function(args)
        if time == 1 then end
        if prehook == 1 then return sdk.PreHookResult.SKIP_ORIGINAL end
    end, function(retval)
        if time == 2 then end
    end)
end

local function drawCallMenu()
    local changed = false
    imgui.begin_window("Dev Menu - Calls", nil, ImGuiWindowFlags_AlwaysAutoResize)

    for i, call in ipairs(calls) do
        -- if imgui.tree_node("Call #" .. i) then
        if imgui.collapsing_header("Call #" .. i) then
            imgui.spacing()
            imgui.begin_rect()
            changed, call.path = imgui.input_text("Managed Singleton " .. i, call.path)
            local singleton = sdk.get_managed_singleton(call.path)
            imgui.end_rect(5, 1)
            imgui.spacing()
            imgui.spacing()
            for i1, instruction in ipairs(call.instructions) do
                imgui.spacing()
                imgui.begin_rect()
                local typeOptions = {"Method", "Field", "ArrayIndex"}
                local operationOptions = {"Get", "Set", "Call"}
                if instruction.type ~= 1 then table.remove(operationOptions, #operationOptions) end
                changed, instruction.type = imgui.combo("Type " .. i .. "-" .. i1, instruction.type, typeOptions)
                changed, instruction.operation = imgui.combo("Operation " .. i .. "-" .. i1, instruction.operation,
                                                             operationOptions)
                changed, instruction.name = imgui.input_text("Name/Index " .. i .. "-" .. i1, instruction.name)
                if instruction.type == 1 then
                    changed, instruction.args = imgui.input_text("Args " .. i .. "-" .. i1, instruction.args)
                end

                if (i1 ~= #call.instructions and (instruction.status ~= "Success" and instruction.status ~= nil)) or
                    (instruction.status ~= "Success" and instruction.status ~= nil) then
                    imgui.input_text("Status " .. i .. "-" .. i1, instruction.status, ImGuiInputTextFlags_ReadOnly)
                end

                -- If operation is GET and is last item in instructions, show value
                if instruction.operation == 1 and i1 == #call.instructions then
                    imgui.input_text("Value " .. i .. "-" .. i1, performInstructions(singleton, call.instructions),
                                     ImGuiInputTextFlags_ReadOnly)

                    --  If operation is SET, show value input, and a set button
                elseif instruction.operation == 2 then
                    changed, instruction.value = imgui.input_text("Value " .. i .. "-" .. i1, instruction.value)
                    if imgui.button("Set Value " .. i .. "-" .. i1) then
                        performInstructions(singleton, call.instructions)
                    end
                    -- If operation is CALL, show value input, and a call button
                elseif instruction.operation == 3 then

                    if imgui.button("Call Method " .. i .. "-" .. i1) then
                        performInstructions(singleton, call.instructions)
                    end
                end
                imgui.spacing()
                imgui.end_rect(5, 1)
                imgui.spacing()
                imgui.spacing()
            end
            if imgui.button("Add New Instruction") then
                table.insert(call.instructions, {
                    type = "",
                    name = "",
                    value = "",
                    operation = 1
                })
            end

            imgui.same_line()
            if imgui.button("Remove Last Instruction") then
                table.remove(call.instructions, #call.instructions)
            end
            -- imgui.tree_pop()
            imgui.spacing()
            imgui.spacing()
            imgui.spacing()
            imgui.spacing()
        end
    end
    imgui.separator()
    imgui.spacing()
    if imgui.button("Add New Call") then
        table.insert(calls, {
            path = "",
            instructions = {}
        })
    end
    imgui.same_line()
    if imgui.button("Remove Last Call") then table.remove(calls, #calls) end
    imgui.end_window()
end

local function drawHookMenu()
    local changed = false
    imgui.begin_window("Dev Menu - Hooks", nil, ImGuiWindowFlags_AlwaysAutoResize)

    for i, hook in ipairs(hooks) do
        if imgui.collapsing_header("Hook #" .. i) then
            imgui.spacing()
            imgui.begin_rect()
            changed, calls[i].path = imgui.input_text("Singleton " .. i, hook.path)
            changed, calls[i].method = imgui.input_text("Method" .. i, hook.method)
            changed, calls[i].time = imgui.combo("Time " .. i, hook.time, {"Pre", "Post"})
            changed, calls[i].prehook = imgui.combo("PreHook " .. i, hook.prehook, {"CALL_ORIGINAL", "SKIP_ORIGINAL"})
            if imgui.button("Init Hook " .. i) then initHook(hook) end
            -- drawInstructions(hook, i)
            imgui.separator()
            imgui.spacing()
            imgui.spacing()
            imgui.spacing()
        end
    end
    imgui.separator()

    if imgui.button("Add New Hook") then
        table.insert(hooks, {
            path = "",
            method = "",
            instructions = {}
        })
    end
    imgui.same_line()
    if imgui.button("Remove Last Hook") then table.remove(hooks, #hooks) end
    imgui.end_window()
end

re.on_draw_ui(function()
    drawCallMenu()
    -- drawHookMenu()
end)
