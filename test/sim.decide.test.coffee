root = exports ? this

SCSim = root.SCSim
_ = root._ #require underscore
chai = root.chai
should = chai.should()
expect = chai.expect


class SCSim.TestCmdBehavior extends SCSim.Behavior
  constructor: ->
    @_prop = 0
    super()

  prop: -> @_prop

  @defaultState
    messages:
      prop100: -> @_prop = 100
      propTimes2: -> @_prop *= 2


describe "SCSim.BuildOrder", ->
  describe "addToBuild()", ->
    smarts = new SCSim.BuildOrder

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
    rules = new SCSim.GameRules gameData
    smarts = new SCSim.BuildOrder rules
    hud = new SCSim.GameState new SCSim.EventEmitter, rules
    SCSim.helpers.setupResources hud

    buyMinOnly = SCSim.GameCmd.select("nexus").and.train "minOnly"

    canBuyMinOnly = (hud, rules) -> true

    beforeEach ->
      [hud.resources.minerals, hud.resources.gas] = [0, 0]
      hud.supply.inUse = 0
      hud.supply.cap = 10
      smarts = new SCSim.BuildOrder rules

    it "will buy a unit it can afford and has enough supply for", ->
      smarts.addToBuild 0, canBuyMinOnly, buyMinOnly
      hud.resources.minerals = 10
      hud.supply.inUse = 9

      time = new SCSim.SimTime

      cmd = smarts.decideNextCommand hud, time, rules
      cmd.should.equal buyMinOnly

    it "will not buy something it can't afford", ->
      smarts.addToBuild 0, canBuyMinOnly, buyMinOnly
      hud.resources.minerals = 9
      hud.supply.inUse = 9
      time = new SCSim.SimTime

      cmd = smarts.decideNextCommand hud, time, rules
      expect(cmd).to.be.null

    it "will buy what it can afford at a specified time", ->
      smarts.addToBuild 20, canBuyMinOnly, buyMinOnly
      hud.resources.minerals = 10
      hud.supply.inUse = 9
      time = new SCSim.SimTime 20

      cmd = smarts.decideNextCommand hud, time, rules
      cmd.should.equal buyMinOnly

    it "won't buy what it can afford _before_ the specified time", ->
      smarts.addToBuild 20, canBuyMinOnly, buyMinOnly
      hud.resources.minerals = 10
      hud.supply.inUse = 9
      time = new SCSim.SimTime 19

      cmd = smarts.decideNextCommand hud, time
      expect(cmd).to.be.null
