local Constants = require "constants"
local ScoreBoard = {}

function ScoreBoard:new()
    local instance = {}
    self.__index = self
    setmetatable(instance, self)

    instance:init()

    return instance
end

function ScoreBoard:init()
end

return ScoreBoard