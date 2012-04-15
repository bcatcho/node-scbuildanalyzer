chai = require 'chai'
chai.should()
expect = chai.expect
common = require '../coffee/sim.common.coffee'
econ = require '../coffee/sim.econ.coffee' 
require 'underscore'



logger = new common.SimEventLog
logger.watchFor ['depositMinerals']

common.SimSingletons.register common.SimEventLog, logger

class TBase extends econ.Base
   removeXWorkersFromRandomPatch: (x) ->
      patch = Math.round( Math.random() *( @mins.length - 1))
      @mins[patch].workers.pop() for i in [1..x]
      @mins[patch]

   addXworkersToEachMinPatch: (x) ->
      @mins.forEach (m) => 
         m.say 'workerArrived', util.Wrkr() for i in [1..x]
         m.say 'workerStartedMining', m.workers[0]

util = 
   Wrkr: -> new econ.Worker
   Min: -> new econ.MineralPatch
   Base: -> new TBase
   FullBase: ->
      b = util.Base()
      b.addXworkersToEachMinPatch 2
      b

describe 'EconSim', ->
   it 'sets up', ->
      sim = new econ.EconSim 6
      sim.bases.length.should.equal 6 

describe 'EconSim::MineralPatch', ->
   it 'sets up', ->
      min = new econ.MineralPatch
      min.amt.should.be.a 'number'

   it 'attaches new workers that target it via event', ->
      min = new econ.MineralPatch
      min.say 'workerArrived', util.Wrkr()
      min.workers.length.should.equal 1

   it 'subtract minerals on mineralsHarvested event', ->
      min = new econ.MineralPatch
      expectedAmt = min.amt - 5
      min.say 'mineralsHarvested', 5
      min.amt.should.equal expectedAmt

describe 'When a new Worker is told to gather from an empty Mineral Patch', ->
   wrkr = util.Wrkr()
   base = util.FullBase()
   minPatch = base.removeXWorkersFromRandomPatch 2
   minPatchOriginalAmt = minPatch.amt
   wrkr.say 'gatherMinerals', minPatch 

   describe 'first', ->
      it 'will target the patch specificied by the base', ->
         wrkr.targetResource.should.equal minPatch
      
      it 'then should start traveling to said patch', ->
         wrkr.stateName.should.equal 'travelingToMinPatch'

      it 'and should take the right amount of time to get there', ->
         travelTime = wrkr.t_toPatch
         wrkr.update() for i in [0..travelTime]
         ['mining', 'waitingToMine'].should.include wrkr.stateName

   describe 'once it arrives at the patch', ->
      it 'will wait to mine if a worker is already there', ->
         wrkr.stateName.should.equal 'waitingToMine'

      it 'and will start mining once the last worker has finished', ->
         minPatch.workerMining = null 
         wrkr.update()
         expect(wrkr.stateName).to.equal 'mining'
  
   describe 'then once the mining time is up', ->
      it 'will start traveling back to base once the mining time is up', ->
         travelTime = wrkr.t_mine
         wrkr.update() for i in [0..travelTime]
         wrkr.stateName.should.equal 'returningMinsToBase'

      it 'should have removed the correct amount of minerals from the mineral patch', ->
         minPatch.amt.should.equal minPatchOriginalAmt - wrkr.collectAmt

      it 'should be removed from the mineral\'s worker queueu', ->
         minPatch.workers.should.not.include wrkr

      it 'should take the right amount of time to get there', ->
         wrkr.update() for i in [0..wrkr.t_toBase]
         wrkr.stateName.should.equal 'depositingMineralsToBase'

   describe 'when it arrives at the base', ->
      it 'will deposite the right amount of minerals to the base', ->
         originalBaseMineralAmt = minPatch.base.mineralAmt
         wrkr.update()
         minPatch.base.mineralAmt.should.equal (originalBaseMineralAmt + wrkr.collectAmt)

      it 'then goes back to the same mineral patch', ->
         wrkr.update()
         wrkr.stateName.should.equal 'travelingToMinPatch'
         wrkr.targetResource.should.equal minPatch

   describe 'all the while, the event logger', ->
      it "should have heard about the base's new minerals", ->
         logger.events['depositMinerals'].length.should.equal 1
         

