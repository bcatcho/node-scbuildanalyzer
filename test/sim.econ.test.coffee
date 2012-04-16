chai = require 'chai'
chai.should()
expect = chai.expect
common = require '../coffee/sim.common.coffee'
econ = require '../coffee/sim.econ.coffee'
_ = require 'underscore'

logger = common.SimSingletons.register common.SimEventLog
logger.watchFor ["depositMinerals", "workerStartedMining"]
time = common.SimSingletons.register common.SimTimer

class TBase extends econ.Base
  constructor: ->
    super

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
  Base: ->
    b = new TBase
    b.instantiate()
    b
  FullBase: ->
    b = util.Base()
    b.addXworkersToEachMinPatch 2
    b

describe 'EconSim with one base', ->
  before ->
    logger.clear()
    time.reset()
  sim = new econ.EconSim
  base = null

  describe 'When told to create a new EconSim::Base', ->
    base = sim.createActor econ.Base

    it 'should have a new EconSim::Base subActor', ->
      _(sim.subActors).first().should.be.an.instanceOf(econ.Base)

  describe 'When told to start', ->
    it 'should change state to running', ->
      sim.say 'start'
      sim.stateName.should.equal 'running'

    it 'should be at tick count = 0', ->
      sim.time.tick.should.equal 0

  describe 'When the base creates a new worker', ->
    base.say 'buildNewWorker'

    it 'should _not yet_ have another subActor that is a EconSim::Worker', ->
      _(sim.subActors).any((a) -> a instanceof(econ.Worker)).should.equal false

    it 'but after update(build time) it should have a Worker subActor', ->
      sim.update() for i in [1..base.t_buildWorker]
      _(sim.subActors).any((a) -> a instanceof(econ.Worker)).should.equal true

    it 'should have taken the right amount of time', ->
      sim.time.tick.should.equal 5

    it 'the base should receive minerals after some time', ->
      sim.update() for i in [0..200]
      base.mineralAmt.should.be.above 0

describe 'EconSim::MineralPatch', ->
  before ->
    logger.clear()
    time.reset()

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
  before ->
    logger.clear()
    time.reset()

  sim = new econ.EconSim()
  sim.say 'start'
  wrkr = sim.createActor econ.Worker
  base = sim.createActor TBase
  minPatch = base.removeXWorkersFromRandomPatch 2
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
      logger.events['depositMinerals'].length.should.equal 1

