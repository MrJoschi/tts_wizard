Game = {}

function Game:new(name)
    local instance = {}
    self.__index = self
    setmetatable(instance, self)

    instance.deckZone = getObjectFromGUID(deckZoneGUID)

    instance.name = name

    return instance
end

function Game:start()
    print('das game ist gestartet')
end

function Game:setTrump()
    local deckZoneObjects = self.deckZone.getObjects()

    for _, item in ipairs(deckZoneObjects) do
        if item.tag == "Card" then
            trump = item.getName()
        end
    end

    interpretTrump()
end

local wizard = Game:new('wizard')
local bohnanza = Game:new('bohnanza')

print(wizard.name)
print(bohnanza.name)
wizard:start()
bohnanza:start()

-- return Game