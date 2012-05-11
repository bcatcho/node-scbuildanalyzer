root = exports ? this

SCSim = root.SCSim
_ = root._ #require underscore
chai = root.chai
should = chai.should()


describe "SCSim.GameRules", ->
  rules = null
  beforeEach ->
    gameData = new SCSim.GameData
    gameData.addUnit "testUnit", 10, 20, 1, 1
    rules = new SCSim.GameRules gameData

  describe "canTrainUnit()", ->
    it "should be true if enough supply, gas, min, and tech", ->
      hud = { minerals: 10, gas: 20 , supply:0, supplyCap: 100}
      result = rules.canTrainUnit "testUnit", hud
      result.should.be.true

    it "should be false if unit min&gas cost more than our bank", ->
      hud = { minerals: 9, gas: 19 }
      result = rules.canTrainUnit "testUnit", hud
      result.should.be.false

    it "should be false if only unit min cost more than our bank", ->
      hud = { minerals: 9, gas: 100 }
      result = rules.canTrainUnit "testUnit", hud
      result.should.be.false

    it "should be false if unit would excede supply cap", ->
      hud = { minerals: 100, gas: 100 , supply:0, supplyCap: 0}
      result = rules.canTrainUnit "testUnit", hud
      result.should.be.false


class SCSim.TestCmdBehavior extends SCSim.Behavior
  constructor: ->
    @_prop = 0
    super()

  prop: -> @_prop

  @defaultState
    messages:
      prop100: -> @_prop = 100
      propTimes2: -> @_prop *= 2


describe "SCSim.Cmd", ->
  gameData = new SCSim.GameData
  gameData.addUnit "testUnit", 0, 0, 2, 0, {name: "TestCmdBehavior"}

  describe "select()", ->
    hud = null
    sim = null
    beforeEach ->
      simRun = new SCSim.SimRun gameData
      sim = simRun.sim
      hud = simRun.hud

    it "constructs a command on selectUnit", ->
      unit = sim.makeActor "testUnit"
      hud.addUnit unit

      cmd = SCSim.Cmd.selectA "testUnit"

      cmd.should.be.an.instanceOf SCSim.Cmd

  describe "say()", ->
    hud = null
    sim = null
    beforeEach ->
      simRun = new SCSim.SimRun gameData
      sim = simRun.sim
      hud = simRun.hud

    it "returns a cmd that modifies a specific type of actor", ->
      unit = sim.makeActor "testUnit"
      hud.addUnit unit

      cmd = SCSim.Cmd.selectA("testUnit").say "prop100"
      cmd.execute hud

      unit.get("prop").should.equal 100

    it "can be chained with other commands", ->
      unit = sim.makeActor "testUnit"
      hud.addUnit unit

      cmd = SCSim.Cmd.selectA("testUnit")
                      .say("prop100")
                      .say("propTimes2")
      cmd.execute hud

      unit.get("prop").should.equal 200


