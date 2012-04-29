root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim
_ = root._ #require underscore


class SCSim.WarpInBuilder extends SCSim.Behavior
  constructor: ->

  @defaultState
    messages:
      build: (name) ->
        @sim.say "trainActor", name


class SCSim.Trainable extends SCSim.Behavior
  constructor: (@callbacks = []) ->
    @buidTime
    @startTime

  instantiate: ->
    @buildTime = (SCSim.data.get @actor.actorName).buildTime
    @blockActor()
    @go "default"

  @defaultState
    update: -> ->
      if @startTime + @buildTime <= @time.sec
        @say "trainingComplete"

    enterState: ->
      @startTime = @time.sec

    messages:
      trainingComplete: ->
        @unblockActor()
        @go "trained"
        c() for c in @callbacks

  @state "trained", {}
