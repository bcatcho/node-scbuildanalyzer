_ = window._
SCSim = window.SCSim ? {}
window.SCSim = SCSim
should = chai.should()
SCSim.EconSim = class EconSim extends SCSim.SimActor
  constructor: ->
    @subActors = {}
    @logger = new SCSim.SimEventLog
    @time = new SCSim.SimTimer
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
      @time.step()
      @subActors[actr].update(@time.tick) for actr of @subActors


SCSim.SimBase = class SimBase extends SCSim.SimActor
  constructor: ->
    @mineralAmt = 0
    @mins = []
    @rallyResource = @mins[0]
    @t_buildWorker = 17
    @buildQueue = []
    super()

  instantiate: ->
    @mins = (@sim.createActor(SimMineralPatch, @) for i in [1..8])
    @rallyResource = @mins[0]

  updateBuildQueue: ->
    if @buildQueue.length > 0
      thingBuilding = @buildQueue[0]
      if @isExpired @t_buildWorker - (@time.tick - thingBuilding.startTime)
        thing = @sim.createActor thingBuilding.thing
        thing.say 'gatherFromMinPatch', @rallyResource
        @buildQueue = @buildQueue[1..]
        if @buildQueue.length > 0
          @buildQueue[0].startTime = @time.tick
        

  getMostAvailableMinPatch: ->
    @mins = _.sortBy @mins, (m) -> m.workers.length
    @mins[0]

  @defaultState
    update: -> ->
      @updateBuildQueue()

    messages:
      depositMinerals: (minAmt) ->
        @mineralAmt += minAmt

      buildNewWorker: ->
        @buildQueue.push({startTime: @time.tick , thing: SimWorker})


SCSim.SimMineralPatch = class SimMineralPatch extends SCSim.SimActor
  constructor: (base, startingAmt = 100) ->
    @amt = startingAmt
    @base = base
    @workers = []
    @workerMining = null
    super()

  getClosestAvailableResource: ->
    for m in @base.mins when m isnt @
      return m if m.isAvailable()

  isAvailable: ->
    @workerMining == null

  @defaultState
    update: @noopUpdate

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

      workerCanceledHarvest: (wrkr) ->
        @workers = _(@workers).without(wrkr)
        if @workerMining is wrkr
          @workerMining = null


SCSim.SimWorker = class SimWorker extends SCSim.SimActor
  constructor: ->
    @t_toBase = 3
    @t_toPatch = 3
    @t_mine = 4
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
        @switchStateTo 'approachResource'

  @state "approachResource"
    update: ->
      @sayAfter @t_toPatch, 'arrivedAtMinPatch'

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
      else
        nextResource = @targetResource.getClosestAvailableResource()
        @say 'changeTargetResource', nextResource if nextResource

    messages:
      changeTargetResource: (newResource) ->
        @targetResource.say 'workerCanceledHarvest', @
        @targetResource = newResource
        @switchStateTo 'approachResource'

  @state "harvest"
    update: ->
      @sayAfter @t_mine, 'finishedMining'

    enterState: ->
      @targetResource.say 'workerStartedMining', @

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
