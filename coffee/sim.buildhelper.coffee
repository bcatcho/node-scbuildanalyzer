root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim
_ = root._ #require underscore


class SCSim.BuildHelper
  trainProbesConstantly: (smarts, numProbes) ->
    iterator = () -> true
    cmd = SCSim.Cmd.selectA("nexus").say("trainUnit", "probe")
    for i in [0..numProbes-1]
      smarts.addToBuild i*17, iterator, cmd
