root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim


# Unit Obj Helper
unit = (min, gas, buildTime, supply, behaviors...) ->
  min: min
  gas: gas
  buildTime: buildTime
  supply: supply
  behaviors: behaviors


# Structure Obj Helper
structure = (min, gas, buildTime, behaviors...) ->
  min: min
  gas: gas
  buildTime: buildTime
  behaviors: behaviors


# Neutral Obj Helper
neutral = (behaviors...) ->
  behaviors: behaviors

behave = (name, args...) ->
  name: name
  args: args

SCSim.config =
  secsPerTick: .5 # FIXME? this affects the precision of harvester decisions
  harvesterOverlapThreshold: .3 # this number + secs Per Tick is important


SCSim.data =
  get: (name) ->
    return @units[name] || @structure[name] || @neutral[name]

  units:
    probe: unit 50, 0, 17, 1, behave("Harvester"), behave("Trainable")

  structure:
    pylon: structure 100, 0, 25, behave("Trainable"), behave("SupplyStructure", 10)
    nexus: structure 400, 0, 100, behave("PrimaryStructure"), behave("Trainer")

  neutral:
    minPatch: neutral behave("MinPatch")
