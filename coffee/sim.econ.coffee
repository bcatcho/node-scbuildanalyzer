{_} = require 'underscore'
_.mixin rot: (arr, num=1) -> @rest(arr, num).concat @first(arr, num)

class SimActor
   constructor: ->
      @events = {}
      @currentState
      @currentTransitions

   switchStateTo: (sn,a,b,c,d,e,f) ->
      @stateName = sn
      @currentState = @["state_"+sn] a,b,c,d,e,f
      @currentTransitions = @["state_"+sn].messages

   say: (msgName, arg1, arg2, arg3, arg4) ->
      @currentTransitions[msgName]?.call @, arg1, arg2, arg3, arg4

   update: (t) ->
      @currentState(t)

   @state: (fn) ->
      parts = for n,v of fn when n isnt 'messages'
         v.messages = fn.messages
         @::["state_"+n] = v
   
   isExpired: (t) -> t <= 0

   sayAfter: (timeSpan, a, b, c, d, e, f) ->
     (t) -> @say(a,b,c,d,e,f) if @isExpired timeSpan--

class EconSim extends SimActor
  constructor: (baseCount) ->
    @bases = (new Base for i in [1..baseCount])


class Base extends SimActor
  constructor: (mineralPatchCount = 8, gasGyserCount = 2) ->
    @workers
    @mins = (new MineralPatch(@) for i in [1..mineralPatchCount])


  getMostAvailableMinPatch: ->
    @mins = _.sortBy @mins, (m) -> m.workers.length
    @mins[0]


class MineralPatch extends SimActor
  constructor: (base, startingAmt = 100) ->
    @amt = startingAmt 
    @base = base
    @workers = [] 
    @switchStateTo 'default'
    @workerMining = null

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
        @workers = _.rot(@workers)
        @amt -= amtMined


class Worker extends SimActor
  constructor: ->
    @t_toBase = 10
    @t_toPatch = 10
    @t_mine = 5
    @targetResource
    @collectAmt = 5
    @switchStateTo 'created'

  @state
    created: (t) -> (t) =>
    messages:
      gatherMinerals: (minPatch) ->
        @say 'gatherFromMinPatch', minPatch

      gatherFromMinPatch: (minPatch) ->
        @targetResource = minPatch
        @switchStateTo 'travelingToMinPatch'
  
  @state
    mining: ->
      @targetResource.say 'workerStartedMining', @
      @sayAfter @t_mine, 'finishedMining'
    
    messages:
      finishedMining: ->
        @targetResource.say 'workerFinishedMiningXminerals', @, @collectAmt
        @switchStateTo 'returningMinsToBase', @targetResource.base 

  @state
    waitingToMine: -> (t) ->
      if @targetResource.isAvailable()
        @switchStateTo 'mining' 

  @state
    travelingToMinPatch: ->
      @sayAfter @t_toPatch, 'arrivedAtMinPatch'

    messages:
      arrivedAtMinPatch: ->
        @targetResource.say 'workerArrived', @
        if @targetResource.isAvailable()
          @switchStateTo 'mining'
        else
          @switchStateTo 'waitingToMine'

  @state
    returningMinsToBase: (base) ->
      @sayAfter @t_toBase, 'arrivedAtBase', base 

    messages:
      arrivedAtBase: (base) ->


#exports
root = exports ? window  
root.Worker = Worker
root.EconSim = EconSim
root.Base = Base
root.MineralPatch = MineralPatch
root.SimActor = SimActor
