{_} = require 'underscore'

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

class EconSim extends SimActor
  constructor: (baseCount) ->
    @bases = (new Base for i in [1..baseCount])


class Base extends SimActor
  constructor: (mineralPatchCount = 8, gasGyserCount = 2) ->
    @workers
    @mins = (new MineralPatch for i in [1..mineralPatchCount])

  getMostAvailableMinPatch: ->
    @mins = _.sortBy @mins, (m) -> m.workers.length
    @mins[0]


class MineralPatch extends SimActor
  constructor: (startingAmt) ->
    @amt = startingAmt || 100
    @workers = []
    @switchStateTo 'default'
    @workerMining = null

  isAvailable: ->
    @workerMining == null 

  @state
    default: -> =>
    messages:
      attachWorker: (worker) ->
        @workers.push worker

      mineralsHarvested: (amtHarvested) ->
        @amt -= amtHarvested

      workerStartedMining: (worker) ->
        @workerMining = worker



class Worker extends SimActor
  constructor: ->
    @t_toBase = 10
    @t_toPatch = 10
    @t_mine = 5
    @collectAmt = 5
    @switchStateTo 'created'

  @state
    created: (t) -> (t) =>
    messages:
      gatherMinerals: (base) ->
        @base = base
        @say 'gatherFromMinPatch', base.getMostAvailableMinPatch()

      gatherFromMinPatch: (minPatch) ->
        minPatch.say 'attachWorker', @
        @switchStateTo 'travelingToMinPatch', minPatch
  
  @state
    mining: (minPatch) ->
      minPatch.say 'workerStartedMining', @
      miningTimeLeft = @t_mine
      (t) =>
        miningTimeLeft--

  @state
    waitingToMine: (minPatch) -> (t) ->
      if minPatch.isAvailable()
        @switchStateTo 'mining', minPatch

  @state
    travelingToMinPatch: (minPatch) ->
      travelTimeLeft = @t_toPatch
      (t) =>
        travelTimeLeft--
        if travelTimeLeft < 0 then @say 'arrivedAtMinPatch', minPatch

    messages:
      arrivedAtMinPatch: (minPatch) ->
        if minPatch.isAvailable()
          @switchStateTo 'mining', minPatch
        else
          @switchStateTo 'waitingToMine', minPatch

#exports
root = exports ? window  
root.Worker = Worker
root.EconSim = EconSim
root.Base = Base
root.MineralPatch = MineralPatch
root.SimActor = SimActor
