root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim
_ = root._ #require underscore


class SCSim.BuildOrder
  constructor: ->
    @build = []
    @interp = new SCSim.GameCmdInterpreter

  decideNextCommand: (hud, time, rules) ->
    if (@build.length == 0)
      return null
    if (@build[0].seconds <= time.sec and @build[0].iterator(hud,rules))
      if (@interp.canExecute hud, rules, @build[0].cmd)
        return @build.pop(0).cmd
    null

  addToBuild: (seconds, iterator, cmd) ->
    buildStep = { seconds, iterator, cmd }
    index = _(@build).sortedIndex buildStep, (bStep) -> bStep.seconds
    @build.splice index, 0, buildStep


class SCSim.SimRun
  constructor: (gameData, smarts) ->
    @gameData = gameData ? SCSim.data
    @rules = new SCSim.GameRules @gameData
    @smarts = smarts ? new SCSim.BuildOrder @rules
    @emitter = new SCSim.EventEmitter
    @gameState = new SCSim.GameState @emitter, @rules
    @sim = new SCSim.Simulation @emitter, @gameData
    @interp = new SCSim.GameCmdInterpreter

  update: ->
    # pass the current gamestate (HUD) to the smarts
    command = @smarts.decideNextCommand @gameState, @sim.time, @rules
    # execute whatever the smarts decides
    if command
      @interp.execute @gameState, @rules, command
    # advance one tick
    @sim.update()

  start: ->
    SCSim.helpers.setupResources @gameState
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

    enterState: ->
      SCSim.helpers.setupMap @

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
