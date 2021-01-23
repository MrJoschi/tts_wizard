local Constants = require "constants"
local PlayerManager = require "modules.player.playermanager"
local Table = {}

function Table:new()
    local instance = {}
    self.__index = self
    setmetatable(instance, self)

    instance.deckZone = getObjectFromGUID(Constants.Guid.Table.DeckZone)
    instance.deck = getObjectFromGUID(Constants.Guid.Table.Deck)
    instance.playZone = getObjectFromGUID(Constants.Guid.Table.DeckZone)

    instance:init()

    return instance
end

function Table:init()
    self.deck.interactable = false
end


function Table:moveTrickToWinner()
    Wait.time(function()
        local playZoneObjects = self.playZone.getObjects()
        for _, item in ipairs(playZoneObjects) do
            if item.tag == "Deck" then
                for i = 1, PlayerManager:getNumberOfPlayers(), 1 do
                    item.dealToColorWithOffset({-5+3*tricks[bestCardPlayerNumber], 0, 5}, true, bestCardPlayer)
                end
            end
        end
    end, 1)
end

function Table:collectCards(callback)
    local allObjects = getAllObjects()
    local allCards = {}
    for _, item in ipairs(allObjects) do
        if item.tag == "Card" or item.tag == "Deck" then
            table.insert(allCards, item)
        end
    end
    local allCardsDeck = group(allCards)
    Wait.time(callback, 3)
end

function Table:resetDeck()
    self.deck.setPositionSmooth({x=0,y=1,z=0}, false, false)
end

return Table