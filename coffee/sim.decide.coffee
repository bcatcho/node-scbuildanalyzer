root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim
_ = root._ #require underscore


class SCSim.Hud
  constructor: (emitter) ->
    @minerals = 0
    @gas = 0
    @supply = 0
    @supplyCap = 10
    @production = {}
    @alerts = [] # crono ready, etc
    @economy = {} # state of crono
    @units = {} # my units (Maybe?)
    @structures = {} # my buildings (Maybe ?)
    @events = {}
    @emitter = emitter
    @setupEvents()

  addUnit: (unit) ->
    @units[unit.actorName] = [] if not @units[unit.actorName]
    @units[unit.actorName].push unit

  addEvent: (eventName, filter, callBack) ->
    @emitter.observe eventName, (eventObj) -> callBack(filter(eventObj))

  setupEvents: ->
    @addEvent "depositMinerals",
      (e) -> e.args[0],
      (minAmt) => @minerals += minAmt

    @addEvent "trainUnitComplete",
      (e) -> e.args[0],
      (unit) =>
        u = SCSim.data.units[unit.actorName]
        @supply += u.supply
        @units[unit.actorName] = unit

    @addEvent "supplyCapIncreased",
      (e) -> e.args[0],
      (supplyAmt) => @supplyCap += supplyAmt

    @addEvent "purchase",
      (e) -> e.args[0],
      (unitName) =>
        u = SCSim.data[unitName]
        @minerals -= u.min
        @gas -= u.gas


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


# An abstraction to represent how a player would normally control the game
class SCSim.Cmd
  constructor: (@subject, @verbs = [])->

  @selectA: (name) ->
    new @ (hud) ->
      hud.structures[name]?[0] || hud.units[name]?[0]

  say: (msg, a, b, c, d) ->
    @verbs.push (unit) -> unit.say msg, a, b, c, d
    return @

  execute: (hud) ->
    s = @subject(hud)
    v(s) for v in @verbs


# takes a build order and a HUD and makes decisions in the form of commands
# This will be the interface by which the user can control the simulation
class SCSim.Smarts
  constructor: (gameData) ->
    @build = []
    @rules = new SCSim.GameRules gameData

  decideNextCommand: (hud, time) ->
    if @build[0].seconds <= time.sec and @build[0].iterator(hud, @rules)
      return @build.pop(0).cmd
    false

  addToBuild: (seconds, iterator, cmd) ->
    buildStep = { seconds, iterator, cmd }
    index = _(@build).sortedIndex buildStep, (bStep) -> bStep.seconds
    @build.splice index, 0, buildStep


class SCSim.SimRun
  constructor: (gameData, smarts) ->
    @gameData = gameData ? SCSim.data
    @smarts = smarts
    @emitter = new SCSim.EventEmitter
    @hud = new SCSim.Hud @emitter
    @sim = new SCSim.Simulation @emitter, @gameData

  update: ->
    #commands = @smarts.decide @hud
    @sim.update()

  start: ->
    @sim.say "start"


class SCSim.Simulation extends SCSim.Behavior
  constructor: (@emitter, @gameData) ->
    @subActors = {}
    @time = new SCSim.SimTime
    @beingBuilt = []
    super()
    @instantiate()

  makeActor: (name, a, b, c, d) ->
    actorData = @gameData.get(name)
    instance = new SCSim.Actor actorData.behaviors, a,b,c,d
    instance.actorName = name
    instance.sim = @
    instance.simId = _.uniqueId()
    instance.emitter = @emitter
    instance.time = @time
    @subActors[instance.simId] = instance
    instance.instantiate?()
    instance

  getActor: (simId) ->
    return @subActors[simId]

  @defaultState
    messages:
      start: -> @go "running"

  @state "running"
    update: -> (t) ->
      @time.step(1)
      @subActors[actr].update(@time.sec) for actr of @subActors

    messages:
      buildStructure: (name) ->
        s = SCSim.data.get "name"
        @say "purchase", name
        @beingBuilt.push name

  say: (msgName, a, b, c, d) ->
    @emitter?.fire msgName, {name: msgName, @time, @simId, args: [a, b, c, d]}
    @messages[msgName]?.call @, a, b, c, d

  get: (name, a, b, c, d) ->
    if @[name] isnt undefined
      @[name].call behavior, a, b, c, d

    console.warn("failed to get #{prop}")
