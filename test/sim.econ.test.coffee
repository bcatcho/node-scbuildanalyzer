root = exports ? this

chai = root.chai
should = chai.should()

SCSim = root.SCSim
_ = root._

# underscore extensions
_.mixin
  containsInstanceOf: (collection, theType) ->
    if _(collection).isObject() then collection = _(collection).values()
    _(collection).any (i) -> i instanceof(theType)

#configure
SCSim.config.secsPerTick = 1 # to speed up tests

# tests
describe 'EconSim with one base one worker', ->
  sim = new SCSim.EconSim
  base = null

  describe 'When told to create a new EconSim::Base', ->
    base = sim.createActor SCSim.SimBase

    it 'should have a new EconSim::Base subActor', ->
      _(sim.subActors).containsInstanceOf(SCSim.SimBase).should.equal true
    
  describe 'When told to start', ->
    it 'should change state to running', ->
      sim.say 'start'
      sim.stateName.should.equal 'running'

    it 'should be at tick count = 0', ->
      sim.time.tick.should.equal 0

  describe 'When the base creates a new worker', ->
    base.say 'buildUnit', 'probe'

    it 'should _not yet_ have another subActor that is a EconSim::Worker', ->
      filter = (a) -> a instanceof SCSim.SimWorker
      _(sim.subActors).filter(filter).length.should.equal 6

    it 'but after update(build time) it should have a Worker subActor', ->
      sim.update() for i in [1..100]
      _(sim.subActors).containsInstanceOf(SCSim.SimWorker).should.equal true

    it 'the base should receive minerals after some time', ->
      sim.update() for i in [1..50]
      base.mineralAmt.should.be.above 0

describe 'EconSim with one base and two workers', ->
  sim = new SCSim.EconSim
  sim.logger.fwatchFor 'workerStartedMining', (e) -> "#{e.simId}"
  sim.say 'start'
  base = sim.createActor SCSim.SimBase

  it 'should queue up two workers at base', ->
    base.say 'buildUnit', 'probe'
    base.say 'buildUnit', 'probe'
    base.say 'buildUnit', 'probe'
    sim.update()
    base.buildQueue.length.should.equal 3

  it 'will make the first worker harvest while the 2nd builds', ->
    sim.update() while base.buildQueue.length > 0
    base.mineralAmt.should.be.above 0

  it 'will distribute the workers amongst two mineral patches', ->
    timeOut = 200
    until sim.logger.eventOccurs('workerCanceledHarvest', timeOut--)
      sim.update()
    sim.update() for i in [1..40]
    console.log(_(sim.logger.event('workerStartedMining')).unique())
    _(sim.logger.event('workerStartedMining')).unique().length.should.be.above 1


describe 'MineralPatch', ->
  it 'sets up', ->
    min = new SCSim.SimMineralPatch
    min.amt.should.be.a 'number'

  it 'attaches new workers that target it via event', ->
    min = new SCSim.SimMineralPatch
    min.say 'workerArrived', new SCSim.SimWorker
    min.workers.length.should.equal 1

  it 'subtract minerals on mineralsHarvested event', ->
    min = new SCSim.SimMineralPatch
    expectedAmt = min.amt - 5
    min.say 'mineralsHarvested', 5
    min.amt.should.equal expectedAmt

describe 'Worker.gatherResource()', ->
  sim = new SCSim.EconSim()
  sim.logger.watchFor ["depositMinerals"]
  sim.say 'start'
  wrkr = sim.createActor SCSim.SimWorker
  base = sim.createActor SCSim.SimBase
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
      sim.logger.event('depositMinerals').length.should.equal 1

