root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim


SCSim.config =
  secsPerTick: .5 # FIXME? this affects the precision of harvester decisions
  harvesterOverlapThreshold: .3 # this number + secs Per Tick is important


class SCSim.GameData
  constructor: ->
    @units = {}
    @structures = {}
    @neutrals = {}

  addUnit: (name, min, gas, buildTime, supply, behaviors...) ->
    @units[name] =
      min: min
      gas: gas
      buildTime: buildTime
      supply: supply
      behaviors: behaviors
  
  addStructure: (name, min, gas, buildTime, behaviors...) ->
    @structures[name] =
      min: min
      gas: gas
      buildTime: buildTime
      behaviors: behaviors

  addNeutral: (name, behaviors...) ->
    @neutrals[name] =
      behaviors: behaviors

  get: (name) ->
    return @units[name] || @structures[name] || @neutrals[name]

  isStructure: (name) ->
    return @structures[name] isnt null

# behavior helper
behave = (name, args...) ->
  name: name
  args: args

units = [
  ["probe", 50, 0, 17, 1, behave("Harvester"), behave("Trainable"), behave("StructureBuilder")]
]

structures = [
  ["pylon", 100, 0, 25, behave("Trainable"), behave("SupplyStructure", 10)]
  ["nexus", 400, 0, 100, behave("PrimaryStructure"), behave("Trainable"), behave("UnitTrainer")]
]

neutrals = [
  ["minPatch", behave("MinPatch")]
]

SCSim.loadDefaultData = (gameData) ->
  gameData.addUnit.apply gameData, u for u in units
  gameData.addStructure.apply gameData, s for s in structures
  gameData.addNeutral.apply gameData, n for n in neutrals

SCSim.data = new SCSim.GameData
SCSim.loadDefaultData SCSim.data
