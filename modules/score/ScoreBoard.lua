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

function ScoreBoard:reset(game)
    self:writeScoreboard(game)
end

function ScoreBoard:writeScoreboard(game)
    -- TODO game hier durchzuschleusen ist kacke, braucht man das hier wirklich?
    for index, player in pairs(PlayerManager.getPlayersArray()) do
        UI.setAttributes("ScoreboardPlayer"..index, {color = player, text = Player[player].steam_name})
        UI.setAttributes("ScoreboardPoints"..index, {color = player, text = game.points[index]})
    end
end

return ScoreBoard