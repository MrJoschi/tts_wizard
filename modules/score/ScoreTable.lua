local Constants = require "constants"
local ScoreTable = {}

function ScoreTable:new()
    local instance = {}
    self.__index = self
    setmetatable(instance, self)

    instance.pointblock = getObjectFromGUID(Constants.Guid.ScoreBoard.Pointblock)
    instance.textPlayer = {}

    instance:init()

    return instance
end

function ScoreTable:init()
    -- Deaktviere den Schreibblock
    self.pointblock.interactable = false

    for i = 1, 6, 1 do
        self.textPlayer[i] = getObjectFromGUID(Constants.Guid.ScoreBoard.TextPlayer[i])
    end

    textPointsOrigin = getObjectFromGUID(Constants.Guid.ScoreBoard.TextPoint)
end

return ScoreTable