local Constants = require "constants"
local PlayerManager = require "modules.player.playermanager"

local UIManager = {
    init = function(self)
        UI.setAttribute("TurnScreen", "active", "true")
        UI.setAttribute("Scoreboard", "active", "true")
    end,
    printEndScreen = function (self, player)
        UI.setAttributes("PermanentTextTop", {text = "GAME OVER\nThe winner is: "..PlayerManager:getName(player), color = player})
    end
}

return UIManager