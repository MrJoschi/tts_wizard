local Constants = require "constants"
local PlayerManager = require "modules.player.playermanager"

local CounterManager = {
    init = function(self)
        self.deactivateCounters()
    end,
    deactivateCounters = function()
        for player, GUID in pairs(Constants.Guid.Counter) do
            getObjectFromGUID(GUID).interactable = false
        end
    end,
    destroyUnusedCounters = function()
        for player, GUID in pairs(Constants.Guid.Counter) do
              if PlayerManager:hasPlayer(player) == false then
                destroyObject(getObjectFromGUID(GUID))
              end
        end
    end,
    clearForPlayer = function(self, player)
        getObjectFromGUID(Constants.Guid.Counter[player]).Counter.clear()
    end,
}

return CounterManager