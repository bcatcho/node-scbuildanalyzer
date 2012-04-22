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
describe 'Simulation with one base one worker', ->
  sim = new SCSim.Simulation
  base = null

  describe 'When told to create a new Simulation::Base', ->
    base = sim.createActor SCSim.PrimaryStructure

    it 'should have a new Simulation::Base subActor', ->
      _(sim.subActors).containsInstanceOf(SCSim.PrimaryStructure).should.equal true
    
  describe 'When told to start', ->
    it 'should change state to running', ->
      sim.say 'start'
      sim.stateName.should.equal 'running'

    it 'should be at tick count = 0', ->
      sim.time.tick.should.equal 0

  describe 'When the base creates a new worker', ->
    base.say 'buildUnit', 'probe'

    it 'should _not yet_ have another subActor that is a Simulation::Worker', ->
      filter = (a) -> a instanceof SCSim.Harvester
      _(sim.subActors).filter(filter).length.should.equal 6

    it 'but after update(build time) it should have a Worker subActor', ->
      sim.update() for i in [1..100]
      _(sim.subActors).containsInstanceOf(SCSim.Harvester).should.equal true

    it 'the base should receive minerals after some time', ->
      sim.update() for i in [1..50]
      base.mineralAmt.should.be.above 0

describe 'Simulation with one base and two workers', ->
  sim = new SCSim.Simulation
  sim.logger.fwatchFor 'workerStartedMining', (e) -> "#{e.simId}"
  sim.say 'start'
  base = sim.createActor SCSim.PrimaryStructure

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


