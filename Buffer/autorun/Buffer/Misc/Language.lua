local Utils = require("Buffer.Misc.Utils")
local Config = require("Buffer.Misc.Config")

--- @class Language
--- Manages multi-language support with JSON language files and font loading
local Language = {
    current = "en-us",
    font = {
        name = nil,
        data = nil,
        size = 16
    },
    languages = {},
    sorted = {},
}

--- Initializes the language system by loading all language files and applying saved settings
--- Loads languages from JSON files, restores user's language preference, and sets up fonts
function Language.init()
    Language.load_languages()
    Language.current = Config.get("window.language") or Language.current
    Language.font.size = Config.get("window.font_size") or Language.font.size
    Language.change(Language.current)
end

--- Changes the active language and optionally updates the font size
--- @param new_language string The language code to switch to (e.g., "en-us", "ja-jp")
--- @param new_font_size number|nil Optional new font size to apply
function Language.change(new_language, new_font_size)
    if not new_language or Language.languages[new_language] == nil then
        re.msg("Buffer: Invalid language '" .. tostring(new_language) .. "'. Keeping current Language.")
        return
    end
    
    Language.current = new_language
    Config.set("window.language", Language.current)
    if new_font_size ~= nil then
        Config.set("window.font_size", new_font_size)
        Language.font.size = new_font_size
    end
    Language.font.name = Language.languages[Language.current]["_USE_FONT"]
    Language.font.data = imgui.load_font(Language.font.name, Language.font.size, {0x1, 0xFFFF, 0})
end

--- Loads all language JSON files from the Buffer\Languages\ directory
--- Populates the languages table with parsed JSON data for each language
--- Displays an error message and returns early if no language files are found
function Language.load_languages()
    local files = fs.glob([[Buffer\\Languages\\.*json]])
    if files == nil or #files == 0 then
        re.msg("Buffer:\nUnable to load Language files.\n\nIf you're using a mod manager such as Vortex you may need to manually install this mod as it looks like language files weren't moved over. If you're not using a mod manager then looks like you forgot to move all the files.\n\nThis will now produce an error and the mod will not load!")
        return
    end
    for i = 1, #files do
        local file = files[i]
        local fileName = Utils.split(file, "\\")[#Utils.split(file, "\\")]
        local languageName = Utils.split(fileName, ".")[1]
        Language.languages[languageName] = json.load_file(file)
    end
    Language.sorted = Language.sort_languages()
end
--- Sorts all loaded language codes alphabetically
--- @return table An array of language codes sorted alphabetically
function Language.sort_languages()
    local languages = {}
    for k, v in pairs(Language.languages) do
        table.insert(languages, k)
    end
    table.sort(languages, function(a, b) return a < b end)
    return languages
end

--- Gets the display name of a language from its language code
--- @param code string The language code (e.g., "en-us", "ja-jp")
--- @return string The display name of the language or "Unknown" if not found
function Language.getLanguageName(code)
    if Language.languages[code] == nil then return "Unknown" end
    return Language.languages[code]["_LANGUAGE_NAME"] or "Unknown"
end

--- Gets a translated value from the current language using a key path
--- Supports nested keys using dot notation (e.g., "ui.settings.title")
--- @param key string The translation key or nested key path (dot-separated)
--- @return string|nil The translated string or an error message if key not found
function Language.get(key)
    if Language.languages[Language.current] == nil or Language.languages[Language.current] == "" then
        return "Invalid Language Key: " .. key
    end

    local language_data = Language.languages[Language.current]
    if language_data == nil then
        return "Invalid Language Key: " .. key
    end
    
    if string.find(key, ".") == nil then
        local value = language_data[key]
        return value ~= nil and value or "Invalid Language Key: " .. key
    else
        local keys = Utils.split(key, ".")
        local value = language_data
        for i = 1, #keys do
            value = value[keys[i]]
            if value == nil then
                return "Invalid Language Key: " .. key
            end
        end
        return value
    end
end

return Language
