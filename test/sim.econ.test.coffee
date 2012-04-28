root = exports ? this

SCSim = root.SCSim
_ = root._

chai = root.chai
should = chai.should()

#configure
SCSim.config.secsPerTick = .5 # to speed up tests

# tests
describe 'Simulation with one base one worker', ->
  simRun = new SCSim.SimRun
  sim = simRun.sim
  base = null

  describe 'When told to create a new Simulation::Base', ->
    base = sim.makeActor "nexus"

  describe 'When told to start', ->
    it 'should change state to running', ->
      simRun.start()
      sim.stateName.should.equal 'running'

    it 'should be at tick count = 0', ->
      sim.time.tick.should.equal 0

  describe 'When the base creates a new worker', ->
    base.say "trainUnit", 'probe'

    it 'the base should receive minerals after some time', ->
      simRun.update() for i in [1..50]
      base.behaviors["PrimaryStructure"].mineralAmt.should.be.above 0

describe 'Simulation with one base and two workers', ->
  simRun = new SCSim.SimRun
  sim = simRun.sim
  base = sim.makeActor "nexus"
  simRun.start()
  base.behaviors["PrimaryStructure"].mins = base.behaviors["PrimaryStructure"].mins[..1]

  it 'should queue up two workers at base', ->
    base.say "trainUnit", 'probe'
    base.say "trainUnit", 'probe'
    base.say "trainUnit", 'probe'
    base.behaviors["Trainer"].buildQueue.length.should.equal 3

  it 'will make the first worker harvest while the 2nd builds', ->
    simRun.update() while base.behaviors["Trainer"].buildQueue.length > 0
    base.behaviors["PrimaryStructure"].mineralAmt.should.be.above 0

  it 'workers will seek other resources if theirs is taken', ->
    timeOut = 50
    simRun.emitter.observe "changeTargetResource", (e) => timeOut = -999
    simRun.update() until timeOut-- < 0
    timeOut.should.equal -999 - 1

  it 'will find other min patches', ->
    harvestedMinPatchIds = []
    simRun.emitter.observe "harvestBegan", (e) => harvestedMinPatchIds.push e.simId

    simRun.update() for i in [1..40]
    _(harvestedMinPatchIds).unique().length.should.equal 2


