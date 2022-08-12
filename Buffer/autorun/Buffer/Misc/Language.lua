local utils = require("Buffer.Misc.Utils")
local config = require("Buffer.Misc.Config")

local language = {
    current = "en-us",
    languages = {}
}

function language.init()
    language.current = config.get("language")
    language.load_languages()
end

function language.load_languages()
    local files = fs.glob([[Buffer\\Languages\\.*json]])
    if files == nil then return end
    for i = 1, #files do
        local file = files[i]
        local fileName = utils.split(file, "\\")[#utils.split(file, "\\")]
        local languageName = utils.split(fileName, ".")[1]
        language.languages[languageName] = json.load_file(file)
        log.debug("Loaded language " .. languageName)
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
