local Constants = require "constants"
local CounterManager = {}

function CounterManager:new()
    local instance = {}
    self.__index = self
    setmetatable(instance, self)

    instance:init()

    return instance
end

function CounterManager:init()
    self.deactivateCounters();
end

function CounterManager:deactivateCounters()
    for player, GUID in pairs(Constants.Guid.Counter) do
        getObjectFromGUID(GUID).interactable = false
    end
end

return CounterManager