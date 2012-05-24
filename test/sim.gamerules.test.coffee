root = exports ? this

SCSim = root.SCSim
SCe = SCSim.Enums # convenience enum lookup

_ = root._ #require underscore
chai = root.chai
should = chai.should()
expect = chai.expect


describe "SCSim.GameRules", ->
  rules = gState = null

  beforeEach ->
    gameData = new SCSim.GameData
    gameData.addUnit "testUnit", 10, 20, 1, 1

    rules = new SCSim.GameRules gameData
    emitter = new SCSim.EventEmitter
    gState = new SCSim.GameState emitter, rules

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

  describe "applyCollectResources()", ->
    it "should increase GameState's minerals and gas", ->
      gState.resources.minerals = 0
      gState.resources.gas = 0

      rules.applyCollectResources gState, 5, 7

      gState.resources.minerals.should.equal 5
      gState.resources.gas.should.equal 7


describe "SCSim.GameCmd", ->
  describe "fluent interface", ->
    it "should make a new GameCmd that selects a probe unit", ->
      cmd = SCSim.GameCmd.select "unit", "probe"

      cmd.should.be.an.instanceof SCSim.GameCmd

    it "should make a new GameCmd that selects a nexus structure", ->
      cmd = SCSim.GameCmd.select "structure", "nexus"

      cmd.should.be.an.instanceof SCSim.GameCmd

  describe "train", ->
    it "can supply a predicate to build a nexus structure with a probe", ->
      cmd = SCSim.GameCmd.select("probe").and.train "nexus"

      cmd.verb.should.equal "train"
      cmd.verbObject.should.equal "nexus"


describe "SCSim.GameState", ->
  gState = emitter = null

  beforeEach ->
    rules = new SCSim.GameRules SCSim.data
    emitter = new SCSim.EventEmitter
    gState = new SCSim.GameState emitter, rules

  it "increases in minerals on Msg.DepositMinerals", ->
    emitter.makeAndFire SCe.Msg.DepositMinerals, null, null, 5

    gState.resources.minerals.should.equal 5


describe "SCSim.GameCmdInterpreter", ->

