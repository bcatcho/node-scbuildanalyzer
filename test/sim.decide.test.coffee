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


describe "SCSim.Cmd", ->
  describe "select()", ->
    hud = null
    sim = null
    beforeEach ->
      simRun = new SCSim.SimRun
      sim = simRun.sim
      hud = simRun.hud

    it "should return a fn to select the specified actor from a HUD", ->
      unit = sim.makeActor "probe"
      hud.addUnit unit

      cmd = SCSim.Cmd.selectUnit "probe"

      unit.should.equal cmd(hud)



