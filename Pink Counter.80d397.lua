function bid(player)
    Global.call("bid", {counterObject = self,  counterPlayer = player.color, counterValue = self.getValue()})
end