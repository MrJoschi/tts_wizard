local Constants = require "constants"
local PlayerManager = require "modules.player.playermanager"
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

function ScoreBoard:reset()
    self:writeScoreboard()
end

function ScoreBoard:writeScoreboard()
    for index, player in pairs(PlayerManager.getPlayersArray()) do
        UI.setAttributes("ScoreboardPlayer"..index, {color = player, text = Player[player].steam_name})
        UI.setAttributes("ScoreboardPoints"..index, {color = player, text = points[index]})
    end
end

return ScoreBoard