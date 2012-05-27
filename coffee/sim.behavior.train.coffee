root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim
SCSim.Enums ?= {}; SCe = SCSim.Enums # convenience enum lookup
_ = root._ #require underscore


class SCSim.Trainable extends SCSim.Behavior
  constructor: ->
    @callbacks = []

  instantiate: ->
    @buildTime = (@sim.gameData.get @actor.actorName).buildTime
    super()

  @defaultState
    update: -> ->
      if @startTime + @buildTime <= @time.sec
        @say "complete"

    enterState: ->
      @blockActor()
      @startTime = @time.sec

    messages:
      trainInstantly: () ->
        @say "complete"

      addCallback: (fn) ->
        @callbacks.push(fn)

      complete: ->
        @unblockActor()
        c(@actor) for c in @callbacks
        @go "trained"

  @state "trained"
    enterState: ->
      @say "trainingComplete", @actor


class SCSim.Trainer extends SCSim.Behavior
  constructor: ->
    @building
    @queued = []
    super()

  updateBuildQueue: ->
    if @building is undefined and @queued.length > 0
      @building = @sim.makeActor @queued[0]
      # Notify the whole actor when the unit completes so that other behaviors
      # can add their own hooks
      @building.say "addCallback", ((unit) => @say "trainUnitComplete", unit)
      @queued = @queued[1..]

  @defaultState
    messages:
      trainUnit: (unitName) ->
        @queued.push unitName
        @updateBuildQueue()

      trainUnitInstantly: (unitName) ->
        actor = @sim.makeActor unitName
        # Notify the whole actor when the unit completes so that other behaviors
        # can add their own hooks
        actor.say "addCallback", ((unit) => @say "trainUnitComplete", unit)
        actor.say "trainInstantly"


      trainUnitComplete: (unit) ->
        @building = undefined
        @updateBuildQueue()


class SCSim.WarpInBuilder extends SCSim.Behavior
  constructor: ->

  @defaultState
    messages:
      build: (structureName) ->
        @sim.say "trainActor", structureName
