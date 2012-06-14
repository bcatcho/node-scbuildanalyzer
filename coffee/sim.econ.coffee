root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim
SCSim.Enums ?= {}; SCe = SCSim.Enums # convenience enum lookup
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
    super()
    @supplyAmt = supply

  @defaultState
    messages:
      trainingComplete: ->
        # it knows about Trainable thing. Needs an interface/contract?
        # Are structures inherently trainable? do we need a trainable behavior?
        # Structure behavior?
        @say SCe.Msg.supplyCapChanged, @supplyAmt


class SCSim.MinPatch extends SCSim.Behavior
  constructor:  ->
    @amt = 1000
    @_base
    @_targetedBy = 0
    super()

  base: -> @_base
  targetedBy: -> @_targetedBy

  getClosestAvailableResource: ->
    @_base.get "getMostAvailableMinPatch"
  
  getMostAvailableResource: ->
    if (@_targetedBy > 0)
      @_base.get "getMostAvailableMinPatch"

  isSaturated: ->
    @_targetedBy >= 1

  resourcesForHarvesterCount: ->
    collectionRate = 0 if @_targetedBy is 0
    collectionRate = 40 if @_targetedBy is 1
    collectionRate = 80 if @_targetedBy is 2
    collectionRate = 100 if @_targetedBy > 2

    # FIXME - config value
    rate = (SCSim.config.secsPerTick * (collectionRate/60))
    return rate

  @defaultState
    update: -> (t) ->
      collectionAmt = @resourcesForHarvesterCount()
      @say "mineralsHarvested", collectionAmt

    messages:
      setBase: (base) ->
        @_base = base

      mineralsHarvested: (amtHarvested) ->
        @_base.say "depositMinerals", amtHarvested
        @amt -= amtHarvested

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
        
        if (nextResource = @targetResource.get "getMostAvailableResource")
          @say "changeTargetResource"
          @targetResource = nextResource

        @targetResource.say "targetedByHarvester"
