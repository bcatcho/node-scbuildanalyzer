root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim
_ = root._ #require underscore

SCSim.helpers =
  setupMap: (sim) ->
    nexus = sim.makeActor "nexus"
    nexus.say "trainInstantly"