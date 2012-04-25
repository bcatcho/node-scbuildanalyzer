root = exports ? this

chai = root.chai
should = chai.should()

SCSim = root.SCSim
_ = root._

#configure
SCSim.config.secsPerTick = 1 # to speed up tests

# tests
describe 'Simulation with one base one worker', ->
  sim = new SCSim.Simulation
  base = null

  describe 'When told to create a new Simulation::Base', ->
    base = sim.makeActor "nexus"

  describe 'When told to start', ->
    it 'should change state to running', ->
      sim.say 'start'
      sim.stateName.should.equal 'running'

    it 'should be at tick count = 0', ->
      sim.time.tick.should.equal 0

  describe 'When the base creates a new worker', ->
    base.say "trainUnit", 'probe'

    it 'the base should receive minerals after some time', ->
      sim.update() for i in [1..50]
      base.behaviors["PrimaryStructure"].mineralAmt.should.be.above 0

describe 'Simulation with one base and two workers', ->
  sim = new SCSim.Simulation
  sim.logger.fwatchFor 'harvestBegan', (e) -> "#{e.simId}"
  sim.say 'start'
  base = sim.makeActor "nexus"

  it 'should queue up two workers at base', ->
    base.say "trainUnit", 'probe'
    base.say "trainUnit", 'probe'
    base.say "trainUnit", 'probe'
    base.behaviors["Trainer"].buildQueue.length.should.equal 3

  it 'will make the first worker harvest while the 2nd builds', ->
    sim.update() while base.behaviors["Trainer"].buildQueue.length > 0
    base.behaviors["PrimaryStructure"].mineralAmt.should.be.above 0

  it 'will distribute the workers amongst two mineral patches', ->
    timeOut = 200
    until sim.logger.eventOccurs('workerCanceledHarvest', timeOut--)
      sim.update()
    sim.update() for i in [1..40]
    console.log(_(sim.logger.event('harvestBegan')).unique())
    _(sim.logger.event('harvestBegan')).unique().length.should.be.above 1


