root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim
_ = root._ #require underscore


class SCSim.BuildHelper
  trainProbesConstantly: (smarts, numProbes) ->
    iterator = () -> true
    cmd = SCSim.GameCmd.select("nexus").and.train "probe"
    for i in [0..numProbes-1]
      smarts.addToBuild i*17, iterator, cmd
    null

  trainSupplyConstantly: (smarts) ->
    iterator = (gState, rules) -> true
    cmd = SCSim.GameCmd.select("probe").and.build "pylon"
    smarts.addToBuild (17*3), iterator, cmd
    for i in [2..6]
      seconds = i*17*5
      smarts.addToBuild seconds, iterator, cmd
    null
