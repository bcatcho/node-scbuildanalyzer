root = exports ? this

SCSim = root.SCSim
_ = root._ #require underscore
chai = root.chai
should = chai.should()
expect = chai.expect


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
    hud = sim = null
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
    hud = sim = null
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


describe "SCSim.Smarts", ->
  describe "addToBuild()", ->
    smarts = new SCSim.Smarts

    it "adds first build step at index 0", ->
      smarts.addToBuild 10, () -> "first"
      smarts.build[0].iterator().should.equal "first"

    it "adds a later build step after the first", ->
      smarts.addToBuild 20, () -> "second"
      smarts.build[1].iterator().should.equal "second"

    it "inserts another build step in sorted order", ->
      smarts.addToBuild 15, () -> "third"
      smarts.build[1].iterator().should.equal "third"
      
    it "adds a duplicate before it's corresponding match", ->
      smarts.addToBuild 10, () -> "fourth"
      smarts.build[0].iterator().should.equal "fourth"

  describe "decideNextCommand()", ->
    gameData = new SCSim.GameData
    gameData.addUnit "minOnly", 10, 0, 10, 1
    gameData.addUnit "gasOnly", 0, 10, 10, 1
    gameData.addUnit "minAndGas", 10, 10, 10, 1
    smarts = new SCSim.Smarts gameData
    hud = new SCSim.Hud new SCSim.EventEmitter

    buyMinOnly = () -> "buyMinOnly"

    canBuyMinOnly = (hud, rules) ->
      rules.canTrainUnit "minOnly", hud

    beforeEach ->
      [hud.minerals, hud.gas] = [0, 0]
      smarts = new SCSim.Smarts gameData

    it "will buy a unit it can afford and has enough supply for", ->
      smarts.addToBuild 0, canBuyMinOnly, buyMinOnly
      hud.minerals = 10
      hud.supply = 9
      time = new SCSim.SimTime

      cmd = smarts.decideNextCommand hud, time
      cmd.should.equal buyMinOnly

    it "will not buy something it can't afford", ->
      smarts.addToBuild 0, canBuyMinOnly, buyMinOnly
      hud.minerals = 9
      hud.supply = 9
      time = new SCSim.SimTime

      cmd = smarts.decideNextCommand hud, time
      expect(cmd).to.be.null

    it "will buy what it can afford at a specified time", ->
      smarts.addToBuild 20, canBuyMinOnly, buyMinOnly
      hud.minerals = 10
      hud.supply = 9
      time = new SCSim.SimTime 20

      cmd = smarts.decideNextCommand hud, time
      cmd.should.equal buyMinOnly

    it "won't buy what it can afford _before_ the specified time", ->
      smarts.addToBuild 20, canBuyMinOnly, buyMinOnly
      hud.minerals = 10
      hud.supply = 9
      time = new SCSim.SimTime 19

      cmd = smarts.decideNextCommand hud, time
      expect(cmd).to.be.null
