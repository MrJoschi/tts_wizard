local Constants = require "constants"
local PlayerManager = {}

function PlayerManager:new()
    local instance = {}
    self.__index = self
    setmetatable(instance, self)

    instance:init()

    return instance
end

function PlayerManager:init()
end

return PlayerManager