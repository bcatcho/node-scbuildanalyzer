root = exports ? this
SCSim = root.SCSim ? {}
root.SCSim = SCSim

# Unit Obj Helper
u = (min, gas, buildTime, supply, actor) ->
  min: min
  gas: gas
  buildTime: buildTime
  supply: supply
  actor: () -> SCSim[actor]

# Building Obj Helper
b = (min, gas, buildTime) ->
  min: min
  gas: gas
  buildTime: buildTime

SCSim.config =
  secsPerTick: .1
  workerOverlapThreshold: .4

SCSim.data =
  units:
    probe: u 50, 0, 17, 1, "Harvester"

  buildings:
    pylon: b 100, 0, 25


