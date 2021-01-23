local Constants = require "constants"
local Helpers = require "helpers"

local playersArray = {}
local players = {}
local numberOfPlayers = 0

local PlayerManager = {
    setPlayerNumber = function()
        playersArray = getSeatedPlayers()
        players = {}

        for id, player in pairs(playersArray) do
            players[player] = player
        end

        numberOfPlayers = Helpers.getSize(players)

        if numberOfPlayers < Constants.Config.countPlayerMin or numberOfPlayers > Constants.Config.countPlayerMax then
            broadcastToAll("Dieses Spiel ist nur für "..Constants.Config.countPlayerMin.."-"..Constants.Config.countPlayerMax.." Spieler!", "Red")
            return false
        end

        broadcastToAll("You are playing with "..numberOfPlayers.." player(s)", "Green")
        return true
    end,
    getPlayers = function()
        return players
    end,
    getPlayersArray = function()
        return playersArray
    end,
    hasPlayer = function(player)
        return players[player] ~= nil
    end,
    getNumberOfPlayers = function()
        return numberOfPlayers
    end,
    getRandomPlayer = function()
        local randomNumber = math.random(1, numberOfPlayers)
        return playersArray[randomNumber]
    end,
}

return PlayerManager