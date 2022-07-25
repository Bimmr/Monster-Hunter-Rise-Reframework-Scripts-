local configPath = "Buffer.json"
local config = {}

function config.get_config()
    if json ~= nil then
       return json.load_file(configPath)
    end
    return nil
end

function config.save_section(config_section)
    local current_config = config.get_config() or {}

     -- Should only be one key
    for key, value in pairs(config_section) do
        log.debug("Saving "..key)
        local config_section_key = key
        current_config[config_section_key] = value
    end

    json.dump_file(configPath, current_config)
    log.debug("Saved config to " .. configPath)
end


function config.get_section(config_section_key)
    local current_config = config.get_config()
    if current_config == nil then return nil end
    return current_config[config_section_key] or {}
end

return config
