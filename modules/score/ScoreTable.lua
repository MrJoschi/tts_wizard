local Constants = require "constants"
local PlayerManager = require "modules.player.playermanager"
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

    -- TODO kann man doch auch einfach nach den Seated Players gehen, statt alle Texte zu erstellen
    for i = 1, 6, 1 do
        self.textPlayer[i] = getObjectFromGUID(Constants.Guid.ScoreBoard.TextPlayer[i])
    end

    textPointsOrigin = getObjectFromGUID(Constants.Guid.ScoreBoard.TextPoint)
end

function ScoreTable:writeHeadlines()
    if PlayerManager.getNumberOfPlayers() < 6 then
        for i = 6, PlayerManager.getNumberOfPlayers() + 1, -1 do
            self.textPlayer[i].destruct()
        end
    end
    for index, player in pairs(PlayerManager.getPlayersArray()) do
        self.textPlayer[index].setValue(Player[player].steam_name)
    end
end



return ScoreTable