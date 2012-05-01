root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim
_ = root._ #require underscore


class SCSim.Simulation extends SCSim.Behavior
  constructor: (emitter) ->
    @subActors = {}
    @emitter = emitter
    @time = new SCSim.SimTime
    @beingBuilt = []
    super()
    @instantiate()

  # TODO remove the params
  makeActor: (name, a, b, c, d) ->
    actorData = SCSim.data.get(name)
    instance = new SCSim.Actor actorData.behaviors, a,b,c,d
    instance.actorName = name
    instance.sim = @
    instance.simId = _.uniqueId()
    instance.emitter = @emitter
    instance.time = @time
    @subActors[instance.simId] = instance
    instance.instantiate?()
    instance

  trainActor: (name, callback) ->
    actor = @makeActor name
    actor.say "addCallback", callback
    actor

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


class SCSim.PrimaryStructure extends SCSim.Behavior
  constructor: ->
    @mineralAmt = 0
    @mins = []
    @_rallyResource = @mins[0]
    super()

  rallyResource: -> @_rallyResource

  instantiate: ->
    super()
    @mins = (@sim.makeActor("minPatch", @) for i in [1..8])
    @harvesters = @sim.makeActor("probe") for i in [1..6]
    @_rallyResource = @mins[0]
    h.say "gatherFromResource", @_rallyResource for h in @harvesters

  getMostAvailableMinPatch: ->
    @mins = _.sortBy @mins, (m) -> m.targetedBy
    @mins[0]

  @defaultState
    messages:
      depositMinerals: (minAmt) ->
        @mineralAmt += minAmt
        # TODO this is for logging purposes. do something about this
        @say "mineralsCollected", @mineralAmt


class SCSim.MinPatch extends SCSim.Behavior
  constructor: (base, startingAmt = 100) ->
    @amt = startingAmt
    @_base = base
    @_targetedBy = 0
    @harvesters = []
    @harvesterMining = null
    @harvesterOverlapThreshold = SCSim.config.harvesterOverlapThreshold
    super()

  base: -> @_base
  targetedBy: -> @_targetedBy

  getClosestAvailableResource: ->
    sortedMins = _(@_base.mins).sortBy (m) -> m.get "targetedBy"
    for m in sortedMins when m isnt @
      return m

  isAvailable: ->
    @harvesterMining == null

  isAvailableSoon: (harvester) ->
    (@harvesterMiningTimeDone - @time.sec < @harvesterOverlapThreshold)

  @defaultState
    messages:
      harvesterArrived: (harvester) ->
        @harvesters.push harvester

      mineralsHarvested: (amtHarvested) ->
        @amt -= amtHarvested

      harvestBegan: (harvester, timeMiningDone) ->
        @harvesterMiningTimeDone = timeMiningDone
        @harvesterMining = harvester

      harvestComplete: (harvester, amtMined) ->
        @harvesterMining = null
        @harvesters = _(@harvesters).rest()
        @amt -= amtMined

      harvestAborted: (harvester) ->
        @harvesters = _(@harvesters).without(harvester)
        if @harvesterMining is harvester
          @harvesterMining = null

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
    super()

  @defaultState
    messages:
      gatherFromResource: (resource) ->
        @targetResource = resource
        @targetResource.say "targetedByHarvester"
        @go "approachResource"

  @state "approachResource"
    update: ->
      @sayAfter @t_toBase, "resourceReached"

    messages:
      resourceReached: ->
        @targetResource.say "harvesterArrived", @
        @go "waitAtResource"

  @state "waitAtResource"
    update: -> ->
      # FIXME breakes "dont switch state in update loop convention?"
      @go "harvest" if @targetResource.get "isAvailable"

    enterState: ->
      if @targetResource.get "isAvailable"
        @go "harvest"
      else if not @targetResource.get "isAvailableSoon"
        nextResource = @targetResource.get "getClosestAvailableResource"
        @say "changeTargetResource", nextResource if nextResource

    messages:
      changeTargetResource: (newResource) ->
        @targetResource.say "harvestAborted", @
        @targetResource.say "untargetedByHarvester"
        @targetResource = newResource
        @targetResource.say "targetedByHarvester"
        @go "approachResource"

  @state "harvest"
    update: ->
      @sayAfter @t_mine, "harvestComplete"

    enterState: ->
      @targetResource.say "harvestBegan", @, @time.sec + @t_mine

    messages:
      harvestComplete: ->
        @targetResource.say "harvestComplete", @, @collectAmt
        @go "approachDropOff", @targetResource.get "base"

  @state "approachDropOff"
    update: (dropOff) ->
      @sayAfter @t_toBase, "dropOffReached", dropOff

    messages:
      dropOffReached: (dropOff) ->
        @go "dropOff", dropOff

  @state "dropOff"
    enterState: (dropOff) ->
      dropOff.say "depositMinerals", @collectAmt
      @say "dropOffComplete", dropOff

    messages:
      dropOffComplete: (dropOff) ->
        @go "approachResource"
