chai = require 'chai'
common = require '../coffee/sim.common.coffee'
econ = require '../coffee/sim.econ.coffee'
_ = require 'underscore'

# setup chai
chai.should()
expect = chai.expect

# set up dependencies
logger = common.SimSingletons.register common.SimEventLog
time = common.SimSingletons.register common.SimTimer

#tests
describe 'EconSim with one base one worker', ->
  before ->
    logger.clear()
    time.reset()
  sim = new econ.EconSim
  base = null

  describe 'When told to create a new EconSim::Base', ->
    base = sim.createActor econ.Base

    it 'should have a new EconSim::Base subActor', ->
      _(sim.subActors).containsInstanceOf(econ.Base).should.equal true
    
  describe 'When told to start', ->
    it 'should change state to running', ->
      sim.say 'start'
      sim.stateName.should.equal 'running'

    it 'should be at tick count = 0', ->
      sim.time.tick.should.equal 0

  describe 'When the base creates a new worker', ->
    base.say 'buildNewWorker'

    it 'should _not yet_ have another subActor that is a EconSim::Worker', ->
      _(sim.subActors).containsInstanceOf(econ.Worker).should.equal false

    it 'but after update(build time) it should have a Worker subActor', ->
      sim.update() for i in [1..base.t_buildWorker]
      _(sim.subActors).containsInstanceOf(econ.Worker).should.equal true

    it 'the base should receive minerals after some time', ->
      sim.update() for i in [1..50]
      base.mineralAmt.should.be.above 0

describe 'EconSim with one base and two workers', ->
  before ->
    logger.clear()
    logger.fwatchFor 'workerStartedMining', (e) -> "#{e.simId}"
    time.reset()

  sim = new econ.EconSim
  sim.say 'start'
  base = sim.createActor econ.Base

  it 'should queue up two workers at base', ->
    base.say 'buildNewWorker'
    base.say 'buildNewWorker'
    sim.update()
    base.buildQueue.length.should.equal 2

  it 'will make the first worker harvest while the 2nd builds', ->
    sim.update() while base.buildQueue.length > 0
    base.mineralAmt.should.be.above 0

  it 'will distribute the workers amongst two mineral patches', ->
    timeOut = 200
    sim.update() until logger.eventOccurs('workerCanceledHarvest', timeOut--)
    sim.update() for i in [0..10]
    _(logger.event('workerStartedMining')).unique().length.should.equal 2



describe 'MineralPatch', ->
  before ->
    logger.clear()
    time.reset()

  it 'sets up', ->
    min = new econ.MineralPatch
    min.amt.should.be.a 'number'

  it 'attaches new workers that target it via event', ->
    min = new econ.MineralPatch
    min.say 'workerArrived', new econ.Worker
    min.workers.length.should.equal 1

  it 'subtract minerals on mineralsHarvested event', ->
    min = new econ.MineralPatch
    expectedAmt = min.amt - 5
    min.say 'mineralsHarvested', 5
    min.amt.should.equal expectedAmt

describe 'Worker.gatherResource()', ->
  before ->
    logger.clear()
    logger.watchFor ["depositMinerals"]
    time.reset()

  sim = new econ.EconSim()
  sim.say 'start'
  wrkr = sim.createActor econ.Worker
  base = sim.createActor econ.Base
  minPatch = base.getMostAvailableMinPatch()
  minPatchOriginalAmt = minPatch.amt
  wrkr.say 'gatherMinerals', minPatch

  describe 'first', ->
    it 'will target the patch specificied by the base', ->
      wrkr.targetResource.should.equal minPatch

    it 'then should start traveling to said patch', ->
      wrkr.stateName.should.equal 'approachResource'

    it 'and should take the right amount of time to get there', ->
      travelTime = wrkr.t_toPatch
      sim.update() for i in [0..travelTime]
      wrkr.stateName.should.not.equal 'approachResource'

    it 'it should immediately start to mine', ->
      wrkr.stateName.should.equal 'harvest'

  describe 'then once the mining time is up', ->
    it 'will start traveling back to base once the mining time is up', ->
      travelTime = wrkr.t_mine
      sim.update() for i in [0..travelTime]
      wrkr.stateName.should.equal 'approachDropOff'

    it 'should have removed minerals from the mineral patch', ->
      minPatch.amt.should.equal minPatchOriginalAmt - wrkr.collectAmt

    it 'should be removed from the mineral\'s worker queueu', ->
      minPatch.workers.should.not.include wrkr

    it 'should take the right amount of time to get there', ->
      sim.update() for i in [0..wrkr.t_toBase]
      wrkr.stateName.should.equal 'approachResource'

  describe 'when it arrives at the base', ->
    it 'will deposite the right amount of minerals to the base', ->
      minPatch.base.mineralAmt.should.equal wrkr.collectAmt

    it 'then goes back to the same mineral patch', ->
      wrkr.stateName.should.equal 'approachResource'
      wrkr.targetResource.should.equal minPatch

  describe 'all the while, the event logger', ->
    it "should have heard about the base's new minerals", ->
      logger.event('depositMinerals').length.should.equal 1

