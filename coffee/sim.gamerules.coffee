root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim
SCSim.Enums ?= {}; SCe = SCSim.Enums # convenience enum lookup

_ = root._ #require underscore


enumFromList = (list...) ->
  obj = {}
  obj[str] = str for str in list
  obj

SCe.Msg = enumFromList "depositMinerals", "trainingComplete", "trainUnit"


# Tracks game state by observing and evaluating sim events with GameRules
class SCSim.GameState
  constructor: (emitter, rules) ->
    @resources = minerals : 0, gas: 0
    @supply = inUse: 0, cap: 0
    @units = {}
    @structures = {}
    @observeEvents emitter, rules

  addUnit: (unit) ->
    @units[unit.actorName] = [] if not @units[unit.actorName]
    @units[unit.actorName].push unit

  observeEvents: (emitter, rules) ->
    # convenience method
    obs = (eventName, filter, callBack) ->
      emitter.observe eventName, (eventObj) ->
        callBack filter(eventObj)

    obs SCe.Msg.depositMinerals,
      (e) -> e.args[0],
      (minAmt) => rules.applyCollectResources @, minAmt, 0
    
    obs SCe.Msg.trainingComplete,
      (e) -> e.args[0],
      (actor) =>
        # FIXME this is a terrible way to detect new buildings maybe
        if SCSim.data.isStructure actor.actorName
          @structures[actor.actorName] ?= []
          @structures[actor.actorName].push actor

    obs "trainUnitComplete",
      (e) -> e.args[0],
      (unit) =>
        u = SCSim.data.units[unit.actorName]
        @supply.inUse += u.supply
        @units[unit.actorName] ?= []
        @units[unit.actorName].push unit


class SCSim.GameRules
  constructor: (@gameData) ->

  canTrainUnit: (gameState, unitName) ->
    unit = @gameData.get unitName
    @meetsCriteria unit, gameState, @canAfford, @hasEnoughSupply, @hasTechPath

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

  applyTrainUnit: (gameState, unitName) ->
    unit = @gameData.get unitName
    gameState.resources.minerals -= unit.min
    gameState.resources.gas -= unit.gas
    gameState.supply.inUse += unit.supply


# Acts out the Cmd's that are emitted from the build order
# It serves as a proxy between the Sim and a User
class SCSim.GameCmdInterpreter
  constructor: (@hud, @rules) ->
    @testState =
      resources:
        minerals : 0
        gas: 0
      supply:
        inUse: 0
        cap: 0

    @verbToRule =
      train: "applyTrainUnit"

  execute: (gameState, rules, cmd) ->
    actors = gameState.units[cmd.subject] || gameState.structures[cmd.subject]
    actor = actors[0]
    @_applyRuleForAction gameState, rules, cmd.verb, cmd.verbObject
    @_executeAction actor, cmd.verb, cmd.verbObject

  canExecute: (gameState, rules, cmd) ->
    @testState.resources.minerals = gameState.resources.minerals
    @testState.resources.gas = gameState.resources.gas
    @testState.supply.inUse = gameState.supply.inUse
    @testState.supply.cap = gameState.supply.cap

    @_applyRuleForAction @testState, rules, cmd.verb, cmd.verbObject

    return false if (@testState.resources.minerals < 0)
    return false if (@testState.resources.gas < 0)
    return false if (@testState.supply.inUse > @testState.supply.cap)
    return true

  _applyRuleForAction: (gameState, rules, verb, verbObject) ->
    rules[@verbToRule[verb]] gameState, verbObject
  
  _executeAction: (actor, verb, verbObject) ->
    @_actions[verb] actor, verbObject
  
  _actions:
    train: (actor, verbObject) ->
      actor.say SCe.Msg.trainUnit, verbObject


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


