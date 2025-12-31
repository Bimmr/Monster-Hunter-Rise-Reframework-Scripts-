local Utils = require("Buffer.Misc.Utils")
local configPath = "Buffer/Config.json"
local Config = {}

--- Navigate to the final key in a nested table based on a dot-separated key string
--- @param config_table table The root configuration table
--- @param key string The dot-separated key string (e.g., "section.subsection.key")
--- @return table The parent table containing the final key
--- @return string The final key in the path
local function navigate_to_key(config_table, key)
    if string.find(key, ".") == nil then
        return config_table, key
    end
    
    local keys = Utils.split(key, ".")
    local current = config_table
    
    for i = 1, #keys - 1 do
        if current[keys[i]] == nil then
            current[keys[i]] = {}
        end
        current = current[keys[i]]
    end
    
    return current, keys[#keys]
end

--- Get the config table from the config file
--- @return table|nil The config table or nil if not found
function Config.get_config()
    if json ~= nil then return json.load_file(configPath) end
    return nil
end

--- Save an entire section to the config file
--- @param config_section table A table containing the section to save, with the section name as
function Config.save_section(config_section)
    local current_config = Config.get_config() or {}

    -- Should only be one key but this way we can grab the key 
    for key, value in pairs(config_section) do
        local config_section_key = key
        current_config[config_section_key] = value
    end

    json.dump_file(configPath, current_config)
end

--- Get a section from the config file
--- @param config_section_key string The section key to retrieve
--- @return table|nil The section table or nil if not found
function Config.get_section(config_section_key)
    local current_config = Config.get_config()
    if current_config == nil then return nil end
    return current_config[config_section_key] or {}
end

--- Save a single value to the config at the provided key
--- If a key with a . is given, it will update it in the section
--- @param key string The dot-separated key string (e.g., "section.subsection.key")
--- @param value any The value to set at the specified key
function Config.set(key, value)
    local current_config = Config.get_config() or {}
    local parent, final_key = navigate_to_key(current_config, key)
    parent[final_key] = value
    json.dump_file(configPath, current_config)
end

--- Get a single value from the config at the provided key
--- If a key with a . is given, it will return the value from the section
--- @param key string The dot-separated key string (e.g., "section.subsection.key")
--- @return any The value at the specified key or nil if not found
function Config.get(key)
    local current_config = Config.get_config()
    if current_config == nil then return nil end
    
    if string.find(key, ".") == nil then
        return current_config[key]
    end
    
    local keys = Utils.split(key, ".")
    local value = current_config
    for i = 1, #keys do
        value = value[keys[i]]
        if value == nil then return nil end
    end
    return value
end

return Config

