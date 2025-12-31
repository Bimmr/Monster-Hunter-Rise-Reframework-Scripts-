local Language = require("Buffer.Misc.Language")

local Icons = {
    glyphs = {
        great_sword = "{gray}\u{e915}{white}\u{e916}", -- {black}\u{e914}{gray}\u{e915}{white}\u{e916}"
        sword_and_shield = "\u{e917}", -- "\u{e917}{black}\u{e918}"
        dual_blades = "\u{e91c}{gray}\u{e91e}", -- "\u{e91c}{gray}\u{e91e}{black}\u{e91f}"
        long_sword = "\u{e919}\u{e91a}", -- "\u{e919}{gray}\u{e91a}{black}\u{e91b}"
        hammer = "\u{e91f}\u{e920}", -- "\u{e91f}{gray}\u{e920}{black}\u{e921}"
        hunting_horn = "\u{e922}", -- "\u{e922}{black}\u{e923}"
        lance = "\u{e925}", -- "{black}\u{e924}{white}\u{e925}"
        gunlance = "\u{e926}\u{e927}", -- "\u{e926}\u{e927}{black}\u{e928}"
        switch_axe = "\u{e92a}\u{e92b}", -- "{black}\u{e929}{white}\u{e92a}\u{e92b}"
        charge_blade = "\u{e92c}\u{e92d}{black}\u{e92e}",
        insect_glaive = "\u{e92f}\u{e930}", -- "\u{e92f}\u{e930}{black}\u{e931}"
        bow = "\u{e932}", -- "\u{e932}{black}\u{e933}"
        light_bowgun = "\u{e934}\u{e935}", -- "\u{e934}\u{e935}{black}\u{e936}"
        heavy_bowgun = "\u{e937}\u{e938}", -- "\u{e937}\u{e938}{black}\u{e939}"

        character = "\u{e901}", -- "{black}\u{e900}{white}\u{e901}"
        miscellaneous = "\u{e903}\u{e904}\u{e905}", -- "{black}\u{e902}{white}\u{e903}\u{e904}\u{e905}"

    },
    font = nil,
    loaded_font_size = nil,  -- Track the font size we loaded with
    default_color = 0xFFFFFFFF, -- White
    colors = {
        black = 0xFF333333, -- Made it more gray so it doesn't have as much contrast
        gray = 0xFF777777,
        white = 0xFFFFFFFF
    }
}

--- Loads the icon font with the current language font size
function Icons.load_icons()
    Icons.font = imgui.load_font('Monster-Hunter-Icons.ttf', Language.font.size+2, {0xE900, 0xE9FF, 0})
    Icons.loaded_font_size = Language.font.size
end

--- Reload icons if the language font size has changed
function Icons.reload_if_needed()
    if Icons.loaded_font_size ~= Language.font.size then
        Icons.load_icons()
    end
end

--- Draws the specified icon at the current cursor position
--- @param icon string The icon identifier (e.g., "great_sword", "dual_blades")
--- Supports color placeholders in format: "{color_name}\u{code}"
function Icons.draw_icon(icon)
    if Icons.font == nil then 
        Icons.load_icons() 
    else
        Icons.reload_if_needed()
    end
    
    imgui.push_font(Icons.font)
    local code = Icons.glyphs[icon] or "?"
    local pos = imgui.get_cursor_pos()
    
    -- Apply 3-point offset for character and miscellaneous icons
    if icon == "character" or icon == "miscellaneous" then
        pos.x = pos.x + 3
    end
    
    local current_color = Icons.default_color
    
    -- Parse the string for UTF-8 codes and color placeholders
    local i = 1
    while i <= #code do
        -- Check if this is a color placeholder (starts with "{")
        local color_name = code:match("^{([^}]+)}", i)
        if color_name then
            -- Look up the color from the colors table
            current_color = Icons.colors[color_name] or Icons.default_color
            i = i + #color_name + 2  -- Skip "{color_name}"
        else
            -- It's a UTF-8 character, extract and display it
            local char_start = i
            local byte = code:byte(i)
            
            -- Determine UTF-8 character length
            local char_len = 1
            if byte >= 0xF0 then
                char_len = 4
            elseif byte >= 0xE0 then
                char_len = 3
            elseif byte >= 0xC0 then
                char_len = 2
            end
            
            -- Extract the character
            local char = code:sub(char_start, char_start + char_len - 1)
            
            -- Draw the character with current color
            imgui.set_cursor_pos(pos)
            imgui.text_colored(char, current_color)

            i = i + char_len
        end
    end
    
    imgui.pop_font()
end

return Icons
