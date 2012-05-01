root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim
_ = root._ #require underscore


class SCSim.Trainable extends SCSim.Behavior
  constructor: ->
    @callbacks = []

  instantiate: ->
    @buildTime = (SCSim.data.get @actor.actorName).buildTime
    super()

  @defaultState
    update: -> ->
      if @startTime + @buildTime <= @time.sec
        @say "trainingComplete"

    enterState: ->
      @blockActor()
      @startTime = @time.sec

    messages:
      addCallback: (fn) ->
        @callbacks.push(fn)

      trainingComplete: ->
        @unblockActor()
        c(@actor) for c in @callbacks
        @go "trained"

  @state "trained", {}


class SCSim.Trainer extends SCSim.Behavior
  constructor: ->
    @building
    @queued = []
    super()

  updateBuildQueue: ->
    if @building is undefined and @queued.length > 0
      @building = @sim.trainActor @queued[0],
        (unit) => @say "trainUnitComplete", unit
      @queued = @queued[1..]

  @defaultState
    messages:
      trainUnit: (unitName) ->
        @queued.push unitName
        @updateBuildQueue()

      trainUnitComplete: (unit) ->
        # TODO it would be nice if i another behavior could specify this
        unit.say "gatherFromResource", @actor.get "rallyResource"

        @building = undefined
        @updateBuildQueue()


class SCSim.WarpInBuilder extends SCSim.Behavior
  constructor: ->

  @defaultState
    messages:
      build: (name) ->
        @sim.say "trainActor", name
