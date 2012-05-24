// Generated by CoffeeScript 1.3.3
(function() {
  var SCSim, chai, root, should, _;

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  SCSim = root.SCSim;

  _ = root._;

  chai = root.chai;

  should = chai.should();

  describe("class BuildHelper", function() {
    return describe("BuildProbesConstantly", function() {
      var bHelper, smarts, _ref;
      _ref = [null, null], bHelper = _ref[0], smarts = _ref[1];
      beforeEach(function() {
        bHelper = new SCSim.BuildHelper;
        return smarts = new SCSim.Smarts;
      });
      return it("creates probes every time one is about to finish", function() {
        bHelper.trainProbesConstantly(smarts, 2);
        smarts.build[0].seconds.should.equal(0);
        return smarts.build[1].seconds.should.equal(17);
      });
    });
  });

}).call(this);