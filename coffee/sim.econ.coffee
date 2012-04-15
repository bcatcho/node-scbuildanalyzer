root = exports ? this
_ = require 'underscore'
common = require './sim.common.coffee'

class EconSim extends common.SimActor
   constructor: (baseCount) ->
     @bases = (new Base for i in [1..baseCount])


class Base extends common.SimActor
   constructor: (mineralPatchCount = 8, gasGyserCount = 2) ->
     @workers
     @mins = (new MineralPatch(@) for i in [1..mineralPatchCount])
     @mineralAmt = 0
     @switchStateTo 'default'
     super

   getMostAvailableMinPatch: ->
     @mins = _.sortBy @mins, (m) -> m.workers.length
     @mins[0]
   
   @state
      default: -> ->
      messages:
         depositMinerals: (minAmt) ->
            @mineralAmt += minAmt


class MineralPatch extends common.SimActor
   constructor: (base, startingAmt = 100) ->
     @amt = startingAmt 
     @base = base
     @workers = [] 
     @switchStateTo 'default'
     @workerMining = null
     super

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
     @t_toBase = 10
     @t_toPatch = 10
     @t_mine = 5
     @targetResource
     @collectAmt = 5
     @switchStateTo 'created'
     super

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
          @switchStateTo 'depositingMineralsToBase', base

   @state
     depositingMineralsToBase: (base) -> (t) ->
        base.say 'depositMinerals', @collectAmt
        @say 'finishedDepositingMineralsToBase', base

     messages:
        finishedDepositingMineralsToBase: (base) ->
            @switchStateTo 'travelingToMinPatch'

        

#exports
root.Worker = Worker
root.EconSim = EconSim
root.Base = Base
root.MineralPatch = MineralPatch
