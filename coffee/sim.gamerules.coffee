root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim
SCSim.Enums ?= {}; SCe = SCSim.Enums # convenience enum lookup

_ = root._ #require underscore


enumFromList = (list...) ->
  obj = {}
  obj[str] = str for str in list
  obj

SCe.Msg = enumFromList "DepositMinerals", "TrainingComplete"


# Tracks game state by observing and evaluating sim events with GameRules
class SCSim.GameState
  constructor: (emitter, rules) ->
    @resources = minerals : 0, gas: 0
    @supply = inUse: 0, cap: 0
    @units = {}
    @structures = {}
    @observeEvents emitter, rules

  observeEvents: (emitter, rules) ->
    # convenience method
    obs = (eventName, filter, callBack) ->
      emitter.observe eventName, (eventObj) ->
        callBack filter(eventObj)

    obs SCe.Msg.DepositMinerals,
      (e) -> e.args[0],
      (minAmt) => rules.applyCollectResources @, minAmt, 0


class SCSim.GameRules
  constructor: (@gameData) ->

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

  applyCollectResources: (gameState, minerals, gas) ->
    gameState.resources.minerals += minerals
    gameState.resources.gas += gas


# Acts out the Cmd's that are emitted from the build order
# It serves as a proxy between the Sim and a User
class SCSim.GameCmdInterpreter
  constructor: (@hud, @rules) ->

  execute: (cmd, hud, rules) ->
    false

  canExecute: (cmd, hud, rules) ->



class SCSim.GameCmd
  constructor: (subject) ->
    @article = "any"
    @subject = subject
    @verb
    @verbObject

    # fluent interface conjunctions
    @and = @

  @select: (subject) ->
    new @ subject

  train: (name) ->
    [@verb, @verbObject] = ["train", name]
    return @


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
