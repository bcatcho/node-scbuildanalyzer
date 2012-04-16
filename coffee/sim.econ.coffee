root = exports ? this
_ = require 'underscore'
common = require './sim.common.coffee'

class EconSim extends common.SimActor
  constructor: ->
    @subActors = []
    super()

  createActor: (actr, a, b, c, d) ->
    instance = new actr a,b,c,d
    instance.sim = @
    @subActors.push(instance)
    instance.instantiate?()
    instance

  @state
    default: -> ->
    messages:
      start: -> @switchStateTo 'running'

  @state
    running: -> (t) ->
      @time.step()
      actr.update(@time.tick) for actr in @subActors

class Base extends common.SimActor
  constructor: ->
    @mineralAmt = 0
    @mins = []
    @rallyResource = @mins[0]
    @t_buildWorker = 5
    @buildQueue = []
    super()

  instantiate: ->
    @mins = (@sim.createActor(MineralPatch, @) for i in [1..8])
    @rallyResource = @mins[0]

  updateBuildQueue: ->
    if @buildQueue.length > 0
      thingBuilding = @buildQueue[0]
      if @isExpired @t_buildWorker - (@time.tick - thingBuilding.startTime)
        thing = @sim.createActor thingBuilding.thing
        thing.say 'gatherFromMinPatch', @rallyResource
        @buildQueue = _(@buildQueue).rest()

  getMostAvailableMinPatch: ->
    @mins = _.sortBy @mins, (m) -> m.workers.length
    @mins[0]

  @state
    default: -> ->
      @updateBuildQueue()

    messages:
      depositMinerals: (minAmt) ->
        @mineralAmt += minAmt

      buildNewWorker: ->
        @buildQueue.push({startTime: @time.tick , thing: Worker})


class MineralPatch extends common.SimActor
  constructor: (base, startingAmt = 100) ->
    @amt = startingAmt
    @base = base
    @workers = []
    @workerMining = null
    super()

  isAvailable: ->
    @workerMining == null

  @state
    default: -> =>
    messages:
      workerArrived: (wrkr) ->
        @workers.push wrkr

      mineralsHarvested: (amtHarvested) ->
        @amt -= amtHarvested

      workerStartedMining: (wrkr) ->
        @workerMining = wrkr

      workerFinishedMiningXminerals: (wrkr, amtMined) ->
        @workerMining = null
        @workers = _(@workers).rest()
        @amt -= amtMined


class Worker extends common.SimActor
  constructor: ->
    @t_toBase = 3
    @t_toPatch = 3
    @t_mine = 3
    @targetResource
    @collectAmt = 5
    super 'idle'

  @state
    idle: (t) -> (t) =>
    messages:
      gatherMinerals: (minPatch) ->
        @say 'gatherFromMinPatch', minPatch

      gatherFromMinPatch: (minPatch) ->
        @targetResource = minPatch
        @switchStateTo 'approachResource'

  @state
    approachResource: ->
      @sayAfter @t_toPatch, 'arrivedAtMinPatch'

    messages:
      arrivedAtMinPatch: ->
        @targetResource.say 'workerArrived', @
        @switchStateTo 'waitAtResource'

  @state
    waitAtResource: -> ->
      @switchStateTo 'harvest' if @targetResource.isAvailable()

    enterState: ->
      @switchStateTo 'harvest' if @targetResource.isAvailable()

  @state
    harvest: ->
      @sayAfter @t_mine, 'finishedMining'

    enterState: ->
      @targetResource.say 'workerStartedMining', @

    messages:
      finishedMining: ->
        @targetResource.say 'workerFinishedMiningXminerals', @, @collectAmt
        @switchStateTo 'approachDropOff', @targetResource.base

  @state
    approachDropOff: (base) ->
      @sayAfter @t_toBase, 'arrivedAtBase', base

    messages:
      arrivedAtBase: (base) ->
        @switchStateTo 'dropOff', base

  @state
    dropOff: -> ->

    enterState: (base) ->
      base.say 'depositMinerals', @collectAmt
      @say 'finishedDropOff', base

    messages:
      finishedDropOff: (base) ->
        @switchStateTo 'approachResource'


#exports
root.Worker = Worker
root.EconSim = EconSim
root.Base = Base
root.MineralPatch = MineralPatch
