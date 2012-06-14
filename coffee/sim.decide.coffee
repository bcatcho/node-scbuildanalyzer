root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim
_ = root._ #require underscore


class SCSim.BuildOrder
  constructor: ->
    @build = []
    @interpreter = new SCSim.GameCmdInterpreter

  decideNextCommand: (hud, time, rules) ->
    if (@build.length == 0)
      return null
    if (@build[0].seconds <= time.sec and @build[0].iterator(hud,rules))
      if (@interpreter.canExecute hud, rules, @build[0].cmd)
        return @build.shift(0).cmd
    null

  addToBuild: (seconds, iterator, cmd) ->
    buildStep =
      seconds: seconds
      iterator: iterator
      cmd: cmd

    index = @_findIndexForBuildTime seconds
    @build.splice(index, 0, buildStep)

  _findIndexForBuildTime: (seconds) ->
    index = 0
    while @build[index] and @build[index].seconds <= seconds
      index +=1
    return index


class SCSim.SimRun
  constructor: (gameData, buildOrder) ->
    @gameData = gameData ? SCSim.data
    @rules = new SCSim.GameRules @gameData
    @buildOrder = buildOrder ? new SCSim.BuildOrder @rules
    @emitter = new SCSim.EventEmitter
    @gameState = new SCSim.GameState @emitter, @rules
    @sim = new SCSim.Simulation @emitter, @gameData
    @interpreter = new SCSim.GameCmdInterpreter
    @simHasStarted = false

  runForSeconds: (seconds) ->
    @start() if (!@simHasStarted)
    time = @sim.time
    seconds += time.sec
    @update() until time.sec > seconds

  update: ->
    command = @buildOrder.decideNextCommand @gameState, @sim.time, @rules
    if command
      @interpreter.execute @gameState, @rules, command
    @sim.update()

  start: (mapSetupMethod) ->
    SCSim.helpers.setupResources @gameState
    @sim.say "start"
    (mapSetupMethod ? SCSim.helpers.setupMap) @sim
    @simHasStarted = true

  executeCmd: (command) ->
    # this is a hook for outsiders to execute arbitrary commands.
    # it is usefull for tests
    @interpreter.execute @gameState, @rules, command


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
