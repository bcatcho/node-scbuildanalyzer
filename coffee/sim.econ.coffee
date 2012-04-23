root = exports ? this

_ = root._ #require underscore

SCSim = root.SCSim ? {}
root.SCSim = SCSim

class SCSim.Simulation extends SCSim.Behavior
  constructor: ->
    @subActors = {}
    @logger = new SCSim.EventLog
    @time = new SCSim.SimTime
    super()

  makeActor: (name, a, b, c, d) ->
    actorData = (SCSim.data.units[name] ||
                  SCSim.data.buildings[name] ||
                  SCSim.data.neutral[name])
    instance = new SCSim.Actor actorData.behaviors, a,b,c,d
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
    update: @noopUpdate()

    messages:
      start: -> @switchStateTo 'running'

  @state "running"
    update: -> (t) ->
      @time.step(1)
      @subActors[actr].update(@time.sec) for actr of @subActors


class SCSim.Trainer extends SCSim.Behavior
  constructor: ->
    @buildQueue = []
    super()

  updateBuildQueue: ->
    if @buildQueue.length > 0
      unit = @buildQueue[0]
      if @isExpired (unit.buildTime - (@time.sec - unit.startTime))
        @say 'doneBuildUnit', unit.unitName

  @defaultState
    update: -> ->
      @updateBuildQueue()

    messages:
      buildUnit: (unitName) ->
        u = SCSim.data.units[unitName]
        @buildQueue.push
          startTime: @time.sec
          buildTime: u.buildTime
          unitName: unitName

      doneBuildUnit: (unitName) ->
        unit = @sim.makeActor unitName
        # FIXME what to do on build should be outside of this behavior?
        unit.say 'gatherFromMinPatch', @actor.get "rallyResource"

        @buildQueue = @buildQueue[1..]
        if @buildQueue.length > 0
          @buildQueue[0].startTime = @time.sec


class SCSim.PrimaryStructure extends SCSim.Behavior
  constructor: ->
    @mineralAmt = 0
    @mins = []
    @_rallyResource = @mins[0]
    super()

  rallyResource: -> @_rallyResource

  instantiate: ->
    @mins = (@sim.makeActor("minPatch", @) for i in [1..8])
    @workers = @sim.makeActor("probe") for i in [1..6]
    @_rallyResource = @mins[0]
    wrkr.say 'gatherFromMinPatch', @_rallyResource for wrkr in @workers

  getMostAvailableMinPatch: ->
    @mins = _.sortBy @mins, (m) -> m.targetedBy
    @mins[0]

  @defaultState
    update: @noopUpdate()

    messages:
      depositMinerals: (minAmt) ->
        @mineralAmt += minAmt
        # TODO this is for logging purposes. do something about this
        @say 'mineralsCollected', @mineralAmt


class SCSim.MinPatch extends SCSim.Behavior
  constructor: (base, startingAmt = 100) ->
    @amt = startingAmt
    @_base = base
    @_targetedBy = 0
    @workers = []
    @workerMining = null
    @workerOverlapThreshold = SCSim.config.workerOverlapThreshold
    super()

  base: -> @_base
  targetedBy: -> @_targetedBy

  getClosestAvailableResource: ->
    sortedMins = _(@_base.mins).sortBy (m) -> m.get 'targetedBy'
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
        @_targetedBy += 1

      untargetedByHarvester: ->
        @_targetedBy -= 1


class SCSim.Harvester extends SCSim.Behavior
  constructor: ->
    @t_toBase = 2
    @t_toPatch = 2
    @t_mine = 1.5
    @targetResource
    @collectAmt = 5
    super 'idle'

  @state "idle"
    update: @noopUpdate()

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
      @switchStateTo 'harvest' if @targetResource.get "isAvailable"

    enterState: ->
      if @targetResource.get "isAvailable"
        @switchStateTo 'harvest'
      else if not @targetResource.get "isAvailableSoon"
        nextResource = @targetResource.get "getClosestAvailableResource"
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
        @switchStateTo 'approachDropOff', @targetResource.get "base"

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
