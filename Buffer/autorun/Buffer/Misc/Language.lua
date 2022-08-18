local utils = require("Buffer.Misc.Utils")
local config = require("Buffer.Misc.Config")

local language = {
    current = "en-us",
    font = {
        name = nil,
        data = nil,
        size = 16
    },
    languages = {}
}

function language.init()
    language.load_languages()
    language.current = config.get("window.language") or language.current
    language.font_size = config.get("window.font_size") or language.font_size
    language.change(language.current)
end

-- Sets the language, and updates the font size
function language.change(new_language, new_font_size)
    language.current = new_language
    config.set("window.language", language.current)
    if new_font_size ~= nil then
        config.set("window.font_size", new_font_size)
        language.font.size = new_font_size
    end
    language.font.name = language.languages[language.current]["_USE_FONT"]
    language.font.data = imgui.load_font(language.font.name, language.font.size, {0x1, 0xFFFF, 0})
end

-- Loads all languages from the language folder
function language.load_languages()
    local files = fs.glob([[Buffer\\Languages\\.*json]])
    if files == nil then return end
    for i = 1, #files do
        local file = files[i]
        local fileName = utils.split(file, "\\")[#utils.split(file, "\\")]
        local languageName = utils.split(fileName, ".")[1]
        language.languages[languageName] = json.load_file(file)
    end
end

-- Get a single value from the language from the provided key
function language.get(key)
    if language.languages[language.current] == nil then
        return "Invalid Language Key: ".. key
    else

        local language_data = language.languages[language.current]
        if language_data == nil then return nil end
        if string.find(key, ".") == nil then
            return language_data[key]
        else
            local keys = utils.split(key, ".")
            local value = language_data
            for i = 1, #keys do
                value = value[keys[i]]
                if value == nil then return "Invalid Language Key: "..key end
            end
            return value
        end
    end
end

return language
