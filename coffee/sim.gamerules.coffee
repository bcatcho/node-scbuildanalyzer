root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim
_ = root._ #require underscore


#SCSim.Enum =
#  command: ["train", "research", "warpIn"]
#  subject: ["structure", "unit", "upgrade"]


class SCSim.GameRules
  constructor: (gameData) ->
    @gameData = gameData

  canTrainUnit: (unitName, hud) ->
    data = @gameData.get unitName
    @meetsCriteria data, hud, @canAfford, @hasEnoughSupply, @hasTechPath

  canAfford: (data, hud) ->
    (hud.gas >= data.gas and hud.minerals >= data.min)

  hasEnoughSupply: (data, hud) ->
    (data.supply <= hud.supplyCap - hud.supply)

  hasTechPath: (data, hud) ->
    true

  meetsCriteria: (data, hud, criteria...) ->
    criteria.reduce ((acc, c) -> acc and c(data, hud)), true


# Acts out the Cmd's that are emitted from the build order
# It serves as a proxy between the Sim and a User
class SCSim.GameCmdInterpreter
  constructor: (@hud, @rules) ->
    false

  execute: (cmd, hud, rules) ->
    false


class SCSim.GameCmd
  constructor: (subjectName, subjectType) ->
    @subjectName = subjectName
    @subjectType = subjectType
    @verb
    @predicateName
    @predicateType

  @select: (subjectType, subjectName) ->
    new @ subjectType, subjectName

  train: (predType, predName) ->
    [@verb, @predicateType, @predicateName] = ["train", predType, predName]
    return @

  # fluent interface conjunctions
  and: -> @


# An abstraction to represent how a player would normally control the game
# This layer is accessible to the user
class SCSim.Cmd
  constructor: (@subject, @verbs = [])->

  @selectA: (name) ->
    new @ (hud) ->
      hud.structures[name]?[0] || hud.units[name]?[0]

  # conjunctions for readability
  and: -> @

  say: (msg, a, b, c, d) ->
    @verbs.push (unit) -> unit.say msg, a, b, c, d
    return @

  train =
    structure: (name) ->
    unit: (name) ->


  execute: (hud) ->
    s = @subject(hud)
    v(s) for v in @verbs
