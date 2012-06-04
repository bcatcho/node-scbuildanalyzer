root = exports ? this

SCSim = root.SCSim
_ = root._ #require underscore
chai = root.chai
should = chai.should()


class SCSim.TestBehavior extends SCSim.Behavior
  constructor: ->
    @prop = 0
    super()

  @defaultState
    update: -> -> @prop += 1

    messages:
      prop100: -> @prop = 100


class SCSim.TestBlockingBehavior extends SCSim.Behavior
  constructor: ->
    @prop = 0
    super()

  @defaultState
    update: -> -> @prop += 1

    messages:
      block: -> @block()


class SCSim.TestInstantiationBehavior extends SCSim.Behavior
  constructor: ->
    @prop = 0
    super()

  instantiate: (prop) ->
    @prop = prop
    super()

  @defaultState
    update: -> ->


describe "SCSim.Actor", ->
  describe "instantiate", ->
    it "should create a behavior with named arguments", ->
      a = new SCSim.Actor [{name: "TestInstantiationBehavior", args: [20] }]
      a.instantiate()
      a.behaviors.TestInstantiationBehavior.prop.should.equal 20


describe "SCSim.Behavior", ->
  describe "blockActor()", ->
    it "should take over an actor", ->
      a = new SCSim.Actor [{name: "TestBehavior"}, {name:"TestBlockingBehavior"}]
      a.instantiate()
      a.behaviors.TestBlockingBehavior.blockActor()
      a.update()
      a.behaviors.TestBehavior.prop.should.equal 0
      a.behaviors.TestBlockingBehavior.prop.should.equal 1
  
  describe "unblockActor()", ->
    it "should let all of the Actor's behaviors start updating again", ->
      a = new SCSim.Actor [{name: "TestBehavior"}, {name:"TestBlockingBehavior"}]
      a.instantiate()
      a.behaviors.TestBlockingBehavior.blockActor()
      a.update()
      a.behaviors.TestBlockingBehavior.unblockActor()
      a.update()
      a.behaviors.TestBehavior.prop.should.equal 1
      a.behaviors.TestBlockingBehavior.prop.should.equal 2


describe "SCSim.Trainable", ->
  actr = null
  sim = null
  simRun = null

  beforeEach ->
    gameData = new SCSim.GameData
    gameData.addUnit "testUnit", 0, 0, 2, 0, {name: "Trainable"}, {name: "TestBehavior"}
    simRun = new SCSim.SimRun
    simRun.start()
    sim = simRun.sim
    sim.gameData = gameData
    actr = sim.makeActor "testUnit"

  it "should aquire the correct build time", ->
    actr.behaviors.Trainable.buildTime.should.equal 2
  
  it "should block other behaviors till done", ->
    actr.say "prop100"
    actr.behaviors.TestBehavior.prop.should.equal 0

    simRun.update() for i in [0..10]
    actr.say "prop100"
    actr.behaviors.TestBehavior.prop.should.equal 100


describe 'SCSim.Trainer', ->
  simRun = new SCSim.SimRun
  simRun.start()
  base = simRun.executeCmd SCSim.GameCmd.select("nexus")

  it 'should queue up two workers at base', ->
    simRun.executeCmd SCSim.GameCmd.select("nexus").and.train 'probe'
    simRun.executeCmd SCSim.GameCmd.select("nexus").and.train 'probe'
    simRun.executeCmd SCSim.GameCmd.select("nexus").and.train 'probe'

    base.behaviors["Trainer"].queued.length.should.equal 2
