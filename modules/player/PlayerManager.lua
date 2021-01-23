local Constants = require "constants"
local Helpers = require "helpers"
local PlayerManager = {}

function PlayerManager:new()
    local instance = {}
    self.__index = self
    setmetatable(instance, self)

    instance.playersArray = {}
    instance.players = {}
    instance.numberOfPlayers = 0

    instance:init()

    return instance
end

function PlayerManager:init()
end

function PlayerManager:setPlayerNumber()
    self.playersArray = getSeatedPlayers()
    self.players = {}

    for id, player in pairs(self.playersArray) do
        self.players[player] = player
    end

    self.numberOfPlayers = Helpers.getSize(self.players)

    if self.numberOfPlayers < Constants.Config.countPlayerMin or self.numberOfPlayers > Constants.Config.countPlayerMax then
        broadcastToAll("Dieses Spiel ist nur für "..Constants.Config.countPlayerMin.."-"..Constants.Config.countPlayerMax.." Spieler!", "Red")
        return false
    end

    broadcastToAll("You are playing with "..self.numberOfPlayers.." player(s)", "Green")
    return true
end

function PlayerManager:getPlayers()
    return self.players
end

function PlayerManager:getNumberOfPlayers()
    return self.numberOfPlayers
end

function PlayerManager:getRandomPlayer()
    local randomNumber = math.random(1, self:getNumberOfPlayers())
    return self.playersArray[randomNumber]
end

return PlayerManager