root = exports ? this

SCSim = root.SCSim
_ = root._

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


describe "SCSim.Behavior", ->
  describe "blockActor()", ->
    it "should take over an actor", ->
      a = new SCSim.Actor ["TestBehavior", "TestBlockingBehavior"]
      a.instantiate()
      a.behaviors.TestBlockingBehavior.blockActor()
      a.update()
      a.behaviors.TestBehavior.prop.should.equal 0
      a.behaviors.TestBlockingBehavior.prop.should.equal 1
  
  describe "unblockActor()", ->
    it "should let all of the Actor's behaviors start updating again", ->
      a = new SCSim.Actor ["TestBehavior", "TestBlockingBehavior"]
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
  SCSim.data.units["testUnit"] =
    buildTime: 2
    behaviors: ["Trainable", "TestBehavior"]

  beforeEach ->
    simRun = new SCSim.SimRun
    simRun.start()
    sim = simRun.sim
    actr = sim.makeActor "testUnit"

  it "should aquire the correct build time", ->
    actr.behaviors.Trainable.buildTime.should.equal 2
  
  it "should block other behaviors till done", ->
    actr.say "prop100"
    actr.behaviors.TestBehavior.prop.should.equal 0

    simRun.update() for i in [0..10]
    actr.say "prop100"
    actr.behaviors.TestBehavior.prop.should.equal 100

