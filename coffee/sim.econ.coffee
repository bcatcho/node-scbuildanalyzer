root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim
_ = root._ #require underscore


class SCSim.PrimaryStructure extends SCSim.Behavior
  constructor: ->
    @mineralAmt = 0
    @_mins = []
    @_rallyResource
    super()

  rallyResource: -> @_rallyResource
  mins: -> @_mins

  instantiate: ->
    super()
    for i in [1..8]
      min = @sim.makeActor "minPatch"
      min.say "setBase", @
      @_mins.push min
    @_rallyResource = @_mins[0]

  getMostAvailableMinPatch: ->
    # TODO you don't understand how this works
    _(@_mins).min (m) -> m.get "targetedBy"

  @defaultState
    messages:
      depositMinerals: (minAmt) ->
        @mineralAmt += minAmt

      trainUnitComplete: (unit) ->
        unit.say "gatherFromResource", @_rallyResource


class SCSim.SupplyStructure extends SCSim.Behavior
  constructor: () ->
    super()

  instantiate: (supply) ->
    @supplyAmt = supply
    super()

  @defaultState
    messages:
      trainingComplete: ->
        # it knows about Trainable thing. Needs an interface/contract?
        # Are structures inherently trainable? do we need a trainable behavior?
        # Structure behavior?
        @say "supplyCapIncreased", @supplyAmt


class SCSim.MinPatch extends SCSim.Behavior
  constructor:  ->
    @amt = 100
    @_base
    @_targetedBy = 0
    @harvesters = []
    @harvesterMining = null
    @harvesterOverlapThreshold = SCSim.config.harvesterOverlapThreshold
    super()

  base: -> @_base
  targetedBy: -> @_targetedBy

  getClosestAvailableResource: ->
    @_base.get "getMostAvailableMinPatch"

  isAvailable: ->
    @harvesterMining == null

  isAvailableSoon: (harvester) ->
    (@harvesterMiningTimeDone - @time.sec < @harvesterOverlapThreshold)

  @defaultState
    messages:
      setBase: (base) ->
        @_base = base

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
