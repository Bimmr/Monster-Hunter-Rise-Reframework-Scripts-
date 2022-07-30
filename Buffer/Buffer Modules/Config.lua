local configPath = "Buffer.json"
local config = {}

-- Get the config file - return config as JSON or nil if not found
function config.get_config()
    if json ~= nil then
       return json.load_file(configPath)
    end
    return nil
end

-- Save the current table into the config
function config.save_section(config_section)
    local current_config = config.get_config() or {}

     -- Should only be one key but this way we can grab the key 
    for key, value in pairs(config_section) do
        local config_section_key = key
        current_config[config_section_key] = value
    end

    json.dump_file(configPath, current_config)
end

-- Get the section from the config that matches the provided key
function config.get_section(config_section_key)
    local current_config = config.get_config()
    if current_config == nil then return nil end
    return current_config[config_section_key] or {}
end

-- Set a single key and value into the config
function config.set(key, value)
    local current_config = config.get_config() or {}
    current_config[key] = value
    json.dump_file(configPath, current_config)
end

-- Get a single value from the config from the provided key
function config.get(key)
    local current_config = config.get_config()
    if current_config == nil then return nil end
    return current_config[key]
end

return config
