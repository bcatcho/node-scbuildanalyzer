root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim
SCSim.Enums ?= {}; SCe = SCSim.Enums # convenience enum lookup
_ = root._ #require underscore


class SCSim.Trainable extends SCSim.Behavior
  constructor: ->
    @callbacks = []

  instantiate: ->
    super()
    @buildTime = (@sim.gameData.get @actor.actorName).buildTime

  @defaultState
    update: -> ->
      if @startTime + @buildTime <= @time.sec
        @go "trained"

    enterState: ->
      @blockActor()
      @startTime = @time.sec

    messages:
      trainInstantly: () ->
        @go "trained"

      addCallback: (fn) ->
        # Callbacks will be called on completion of training
        @callbacks.push(fn)

  @state "trained"
    enterState: ->
      @unblockActor()
      callback(@actor) for callback in @callbacks
      @say "trainingComplete", @actor


class SCSim.UnitTrainer extends SCSim.Behavior
  constructor: ->
    @building
    @queued = []
    super()

  queueLength: ->
    @queued.length

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


class SCSim.StructureBuilder extends SCSim.Behavior
  constructor: ->
    super()

  @defaultState
    messages:
      buildStructure: (structureName) ->
        actor = @sim.makeActor structureName
