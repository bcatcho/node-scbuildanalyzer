root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim
_ = root._ #require underscore

SCSim.helpers =
  setupResources: (gameState) ->
    gameState.resources.minerals = 50
    gameState.resources.gas = 0
    gameState.supply.inUse = 0
    gameState.supply.cap = 10

  setupMap: (sim) ->
    nexus = sim.makeActor "nexus"
    nexus.say "trainInstantly"

    for i in [0..5]
      nexus.say "trainUnitInstantly", "probe"

