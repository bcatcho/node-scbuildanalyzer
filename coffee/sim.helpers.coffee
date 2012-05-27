root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim
_ = root._ #require underscore

SCSim.helpers =
  setupMap: (sim) ->
    nexus = sim.makeActor "nexus"
    nexus.say "trainInstantly"
    minPatch = nexus.get "getMostAvailableMinPatch"

    for i in [0..4]
      probe = sim.makeActor "probe"
      probe.say "trainInstantly"
      probe.say "gatherFromResource", minPatch
