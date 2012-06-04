root = exports ? this

SCSim = root.SCSim
_ = root._

chai = root.chai
should = chai.should()


#configure
SCSim.config.secsPerTick = .5 # to speed up tests

testHelper =
  setupMapWithNoProbes: (sim) ->
    nexus = sim.makeActor "nexus"
    nexus.say "trainInstantly"


describe 'Simulation with one base one worker', ->
  simRun = new SCSim.SimRun
  sim = simRun.sim
  simRun.start()
  base = simRun.gameState.structures.nexus[0]

  describe 'When the base creates a new worker', ->
    base.say "trainUnit", 'probe'

    it 'the base should receive minerals after some time', ->
      simRun.update() for i in [1..60]
      base.behaviors["PrimaryStructure"].mineralAmt.should.be.above 0


describe 'Simulation with one base and two workers', ->
  simRun = new SCSim.SimRun
  simRun.start testHelper.setupMapWithNoProbes
  harvestedMinPatchIds = [] # for a later test
  simRun.emitter.observe "targetedByHarvester",
    (e) => harvestedMinPatchIds.push e.simId

  simRun.executeCmd SCSim.GameCmd.select("nexus").and.train 'probe'
  simRun.executeCmd SCSim.GameCmd.select("nexus").and.train 'probe'
  simRun.executeCmd SCSim.GameCmd.select("nexus").and.train 'probe'

  it 'workers will seek other resources if theirs is taken', ->
    timeOut = 100
    harvesterChangedResources = false
    simRun.emitter.observe "changeTargetResource",
      (e) => harvesterChangedResources = true

    simRun.update() while (timeOut-- >= 0 and harvesterChangedResources is false)

    harvesterChangedResources.should.be.true

  it 'will find other min patches', ->
    _(harvestedMinPatchIds).unique().length.should.equal 2


