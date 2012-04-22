root = exports ? this

_ = root._ #require underscore

SCSim = root.SCSim ? {}
root.SCSim = SCSim


class SCSim.Simulation extends SCSim.Actor
  constructor: ->
    @subActors = {}
    @logger = new SCSim.EventLog
    @time = new SCSim.SimTime
    super()

  createActor: (actr, a, b, c, d) ->
    instance = new actr a,b,c,d
    instance.sim = @
    instance.simId = _.uniqueId()
    instance.logger = @logger
    instance.time = @time
    @subActors[instance.simId] = instance
    instance.instantiate?()
    instance

  getActor: (simId) ->
    return @subActors[simId]

  @defaultState
    update: @noopUpdate

    messages:
      start: -> @switchStateTo 'running'

  @state "running"
    update: -> (t) ->
      @time.step(1)
      @subActors[actr].update(@time.sec) for actr of @subActors



class SCSim.Trainer extends SCSim.Actor
  constructor: ->
    @bQueue = []
    super()




class SCSim.PrimaryStructure extends SCSim.Actor
  constructor: ->
    @mineralAmt = 0
    @mins = []
    @rallyResource = @mins[0]
    @buildQueue = []
    super()

  instantiate: ->
    @mins = (@sim.createActor(SCSim.MinPatch, @) for i in [1..8])
    @workers = @sim.createActor(SCSim.Harvester, @) for i in [1..6]
    @rallyResource = @mins[0]
    wrkr.say 'gatherFromMinPatch', @rallyResource for wrkr in @workers

  updateBuildQueue: ->
    if @buildQueue.length > 0
      unit = @buildQueue[0]
      if @isExpired (unit.buildTime - (@time.sec - unit.startTime))
        @say 'doneBuildUnit', unit.unitName

  getMostAvailableMinPatch: ->
    @mins = _.sortBy @mins, (m) -> m.targetedBy
    @mins[0]

  @defaultState
    update: -> ->
      @updateBuildQueue()

    messages:
      depositMinerals: (minAmt) ->
        @mineralAmt += minAmt
        # TODO this is for logging purposes. do something about this
        @say 'mineralsCollected', @mineralAmt

      buildUnit: (unitName) ->
        u = SCSim.data.units[unitName]
        @buildQueue.push
          startTime: @time.sec
          buildTime: u.buildTime
          unitName: unitName

      doneBuildUnit: (unitName) ->
        unit = @sim.createActor SCSim.data.units[unitName].actor()
        unit.say 'gatherFromMinPatch', @rallyResource

        @buildQueue = @buildQueue[1..]
        if @buildQueue.length > 0
          @buildQueue[0].startTime = @time.sec

class SCSim.MinPatch extends SCSim.Actor
  constructor: (base, startingAmt = 100) ->
    @amt = startingAmt
    @base = base
    @workers = []
    @workerMining = null
    @targetedBy = 0
    @workerOverlapThreshold = SCSim.config.workerOverlapThreshold
    super()

  getClosestAvailableResource: ->
    sortedMins = _(@base.mins).sortBy (m) -> m.targetedBy
    for m in sortedMins when m isnt @
      return m

  isAvailable: ->
    @workerMining == null

  isAvailableSoon: (wrkr) ->
    (@workerMiningTimeDone - @time.sec < @workerOverlapThreshold)

  @defaultState
    update: @noopUpdate

    messages:
      workerArrived: (wrkr) ->
        @workers.push wrkr

      mineralsHarvested: (amtHarvested) ->
        @amt -= amtHarvested

      workerStartedMining: (wrkr, timeMiningDone) ->
        @workerMiningTimeDone = timeMiningDone
        @workerMining = wrkr

      workerFinishedMiningXminerals: (wrkr, amtMined) ->
        @workerMining = null
        @workers = _(@workers).rest()
        @amt -= amtMined

      workerCanceledHarvest: (wrkr) ->
        @workers = _(@workers).without(wrkr)
        if @workerMining is wrkr
          @workerMining = null

      targetedByHarvester: ->
        @targetedBy += 1

      untargetedByHarvester: ->
        @targetedBy -= 1


class SCSim.Harvester extends SCSim.Actor
  constructor: ->
    @t_toBase = 2
    @t_toPatch = 2
    @t_mine = 1.5
    @targetResource
    @collectAmt = 5
    super 'idle'

  @state "idle"
    update: @noopUpdate

    messages:
      gatherMinerals: (minPatch) ->
        @say 'gatherFromMinPatch', minPatch

      gatherFromMinPatch: (minPatch) ->
        @targetResource = minPatch
        @targetResource.say 'targetedByHarvester'
        @switchStateTo 'approachResource'

  @state "approachResource"
    update: ->
      @sayAfter @t_toBase, 'arrivedAtMinPatch'

    messages:
      arrivedAtMinPatch: ->
        @targetResource.say 'workerArrived', @
        @switchStateTo 'waitAtResource'

  @state "waitAtResource"
    update: -> ->
      @switchStateTo 'harvest' if @targetResource.isAvailable()

    enterState: ->
      if @targetResource.isAvailable()
        @switchStateTo 'harvest'
      else if not @targetResource.isAvailableSoon()
        nextResource = @targetResource.getClosestAvailableResource()
        @say 'changeTargetResource', nextResource if nextResource

    messages:
      changeTargetResource: (newResource) ->
        @targetResource.say 'workerCanceledHarvest', @
        @targetResource.say 'untargetedByHarvester'
        @targetResource = newResource
        @targetResource.say 'targetedByHarvester'
        @switchStateTo 'approachResource'

  @state "harvest"
    update: ->
      @sayAfter @t_mine, 'finishedMining'

    enterState: ->
      @targetResource.say 'workerStartedMining', @, @time.sec + @t_mine

    messages:
      finishedMining: ->
        @targetResource.say 'workerFinishedMiningXminerals', @, @collectAmt
        @switchStateTo 'approachDropOff', @targetResource.base

  @state "approachDropOff"
    update: (base) ->
      @sayAfter @t_toBase, 'arrivedAtBase', base

    messages:
      arrivedAtBase: (base) ->
        @switchStateTo 'dropOff', base

  @state "dropOff"
    update: @noopUpdate

    enterState: (base) ->
      base.say 'depositMinerals', @collectAmt
      @say 'finishedDropOff', base

    messages:
      finishedDropOff: (base) ->
        @switchStateTo 'approachResource'
