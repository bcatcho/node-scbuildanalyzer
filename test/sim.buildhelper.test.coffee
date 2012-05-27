root = exports ? this

SCSim = root.SCSim
_ = root._ #require underscore
chai = root.chai
should = chai.should()


describe "class BuildHelper", ->

  describe "BuildProbesConstantly", ->
    [bHelper, smarts] = [null, null]

    beforeEach ->
      bHelper = new SCSim.BuildHelper
      smarts = new SCSim.BuildOrder

    it "creates probes every time one is about to finish", ->
      bHelper.trainProbesConstantly smarts, 2

      smarts.build[0].seconds.should.equal 0
      smarts.build[1].seconds.should.equal 17

