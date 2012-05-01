root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim


# Unit Obj Helper
u = (min, gas, buildTime, supply, behaviors...) ->
  min: min
  gas: gas
  buildTime: buildTime
  supply: supply
  behaviors: behaviors


# Building Obj Helper
b = (min, gas, buildTime, behaviors...) ->
  min: min
  gas: gas
  buildTime: buildTime
  behaviors: behaviors


# Neutral Obj Helper
n = (behaviors...) ->
  behaviors: behaviors


SCSim.config =
  secsPerTick: .5 # FIXME? this affects the precision of harvester decisions
  harvesterOverlapThreshold: .3 # this number + secs Per Tick is important


SCSim.data =
  get: (name) ->
    return @units[name] || @buildings[name] || @neutral[name]

  units:
    probe: u 50, 0, 17, 1, "Harvester", "Trainable"

  buildings:
    pylon: b 100, 0, 25
    nexus: b 400, 0, 100, "PrimaryStructure", "Trainer"

  neutral:
    minPatch: n "MinPatch"
