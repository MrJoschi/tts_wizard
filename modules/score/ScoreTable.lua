local Constants = require "constants"
local PlayerManager = require "modules.player.playermanager"
local ScoreTable = {}

function ScoreTable:new()
    local instance = {}
    self.__index = self
    setmetatable(instance, self)

    instance.pointblock = getObjectFromGUID(Constants.Guid.ScoreBoard.Pointblock)
    instance.textPlayer = {}

    instance.textPointsOrigin = getObjectFromGUID(Constants.Guid.ScoreBoard.TextPoint)
    instance.textPoints = {}
    instance.textBids = {}

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
end

function ScoreTable:reset()
    self:writeHeadlines()
    self:initTextPoints()
    self:initTextBids()
end

function ScoreTable:writePoints(round)
    for index, player in pairs(PlayerManager:getPlayersArray()) do
        self.textPoints[index][round].setValue(tostring(points[index]))
        UI.setAttribute("ScoreboardPlayer"..index, "text", PlayerManager:getName(player)..": "..points[index])
    end
end

function ScoreTable:writeHeadlines()
    if PlayerManager:getNumberOfPlayers() < 6 then
        for i = 6, PlayerManager:getNumberOfPlayers() + 1, -1 do
            self.textPlayer[i].destruct()
        end
    end
    for index, player in pairs(PlayerManager:getPlayersArray()) do
        self.textPlayer[index].setValue(Player[player].steam_name)
    end
end

function ScoreTable:initTextPoints()
    self.textPoints = {}   -- create the matrix
    local numberOfPlayers = PlayerManager:getNumberOfPlayers()

    for i = 1, numberOfPlayers do
        self.textPoints[i] = {}     -- create a new row
        for j = 1, 60 / numberOfPlayers do
        -- for j = 1, 20 do
            self.textPoints[i][j] = self.textPointsOrigin.clone({
              position     = {x = -20.84 + 2.34 * i, y = -4.1, z = 8.24 - 0.903 * j} --y-Koordinate ist ein Bug
            })
        end
    end
end

function ScoreTable:initTextBids()
    self.textBids = {}   -- create the matrix
    local numberOfPlayers = PlayerManager:getNumberOfPlayers()
    local playersArray = PlayerManager:getPlayersArray()

    for i, player in pairs(playersArray) do
        -- for i = 1, 6 do
            self.textBids[player] = {}     -- create a new row
        for j = 1, 60 / numberOfPlayers do
            -- for j = 1, 20 do
                self.textBids[player][j] = self.textPointsOrigin.clone({
                position     = {x = -19.68 + 2.34 * i, y = -4.1, z = 8.24 - 0.903 * j} --y-Koordinate ist ein Bug
            })
        end
    end
end

return ScoreTable