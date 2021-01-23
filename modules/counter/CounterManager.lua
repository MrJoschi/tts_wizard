local Constants = require "constants"
local PlayerManager = require "modules.player.playermanager"
local CounterManager = {}

function CounterManager:new(playerManager)
    local instance = {}
    self.__index = self
    setmetatable(instance, self)

    instance.playerManager = playerManager

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

function CounterManager:destroyUnusedCounters()
    for player, GUID in pairs(Constants.Guid.Counter) do
          if self.playerManager:getPlayers()[player] == nil then
            destroyObject(getObjectFromGUID(GUID))
          end
    end
end

return CounterManager