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
    gameData.addUnit "testUnit", 10, 10, 1, 1

    rules = new SCSim.GameRules gameData
    emitter = new SCSim.EventEmitter
    gState = new SCSim.GameState emitter, rules

  describe "canTrainUnit()", ->
    it "should be true if enough supply, gas, min, and tech", ->
      hud = { minerals: 10, gas: 20 , supply:0, supplyCap: 100}
      result = rules.canTrainUnit hud, "testUnit"
      result.should.be.true

    it "should be false if unit min&gas cost more than our bank", ->
      hud = { minerals: 9, gas: 19 }
      result = rules.canTrainUnit hud, "testUnit"
      result.should.be.false

    it "should be false if only unit min cost more than our bank", ->
      hud = { minerals: 9, gas: 100 }
      result = rules.canTrainUnit hud, "testUnit"
      result.should.be.false

    it "should be false if unit would excede supply cap", ->
      hud = { minerals: 100, gas: 100 , supply:0, supplyCap: 0}
      result = rules.canTrainUnit hud, "testUnit"
      result.should.be.false

  describe "applyCollectResources()", ->
    it "should increase minerals and gas", ->
      gState.resources.minerals = 0
      gState.resources.gas = 0

      rules.applyCollectResources gState, 5, 7

      gState.resources.minerals.should.equal 5
      gState.resources.gas.should.equal 7

  describe "applyTrainUnit()", ->
    it "should affect min, gas and supply", ->
      gState.resources.minerals = 10
      gState.resources.gas = 10
      gState.supply.inUse = 0
      gState.supply.cap = 10

      rules.applyTrainUnit gState, "testUnit"

      gState.resources.minerals.should.equal 0
      gState.resources.gas.should.equal 0
      gState.supply.inUse.should.equal 1


describe "SCSim.GameCmd", ->
  describe "fluent interface", ->
    it "should make a new GameCmd that selects a probe unit", ->
      cmd = SCSim.GameCmd.select "probe"

      cmd.subject.should.equal "probe"

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
  interp = rules = gState = emitter = null

  beforeEach ->
    gameData = new SCSim.GameData
    gameData.addUnit "testUnit", 10, 10, 1, 1
    rules = new SCSim.GameRules gameData
    emitter = new SCSim.EventEmitter
    gState = new SCSim.GameState emitter, rules
    interp = new SCSim.GameCmdInterpreter

  describe "canExecute", ->
    it "returns true when enough resources & supply to train", ->
      gState.resources.minerals = 10
      gState.resources.gas = 10
      gState.supply.inUse = 0
      gState.supply.cap = 10
      cmd = SCSim.GameCmd.select("nexus").and.train "testUnit"

      result = interp.canExecute gState, rules, cmd

      result.should.be.true

    it "returns false when there isnt enough minerals to train", ->
      gState.resources.minerals = 0
      gState.resources.gas = 10
      gState.supply.inUse = 0
      gState.supply.cap = 10
      cmd = SCSim.GameCmd.select("nexus").and.train "testUnit"

      result = interp.canExecute gState, rules, cmd

      result.should.be.false




