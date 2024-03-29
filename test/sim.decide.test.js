// Generated by CoffeeScript 1.3.3
(function() {
  var SCSim, chai, expect, root, should, _,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  SCSim = root.SCSim;

  _ = root._;

  chai = root.chai;

  should = chai.should();

  expect = chai.expect;

  SCSim.TestCmdBehavior = (function(_super) {

    __extends(TestCmdBehavior, _super);

    function TestCmdBehavior() {
      this._prop = 0;
      TestCmdBehavior.__super__.constructor.call(this);
    }

    TestCmdBehavior.prototype.prop = function() {
      return this._prop;
    };

    TestCmdBehavior.defaultState({
      messages: {
        prop100: function() {
          return this._prop = 100;
        },
        propTimes2: function() {
          return this._prop *= 2;
        }
      }
    });

    return TestCmdBehavior;

  })(SCSim.Behavior);

  describe("SCSim.BuildOrder", function() {
    describe("addToBuild()", function() {
      var smarts;
      smarts = new SCSim.BuildOrder;
      it("adds first build step at index 0", function() {
        smarts.addToBuild(10, function() {
          return "first";
        });
        return smarts.build[0].iterator().should.equal("first");
      });
      it("adds a later build step after the first", function() {
        smarts.addToBuild(20, function() {
          return "second";
        });
        return smarts.build[1].iterator().should.equal("second");
      });
      it("inserts another build step in sorted order", function() {
        smarts.addToBuild(15, function() {
          return "third";
        });
        return smarts.build[1].iterator().should.equal("third");
      });
      return it("adds a duplicate before it's corresponding match", function() {
        smarts.addToBuild(10, function() {
          return "fourth";
        });
        return smarts.build[0].iterator().should.equal("fourth");
      });
    });
    return describe("decideNextCommand()", function() {
      var buyMinOnly, canBuyMinOnly, gameData, hud, rules, smarts;
      gameData = new SCSim.GameData;
      gameData.addUnit("minOnly", 10, 0, 10, 1);
      gameData.addUnit("gasOnly", 0, 10, 10, 1);
      gameData.addUnit("minAndGas", 10, 10, 10, 1);
      rules = new SCSim.GameRules(gameData);
      smarts = new SCSim.BuildOrder(rules);
      hud = new SCSim.GameState(new SCSim.EventEmitter, rules);
      SCSim.helpers.setupResources(hud);
      buyMinOnly = SCSim.GameCmd.select("nexus").and.train("minOnly");
      canBuyMinOnly = function(hud, rules) {
        return true;
      };
      beforeEach(function() {
        var _ref;
        _ref = [0, 0], hud.resources.minerals = _ref[0], hud.resources.gas = _ref[1];
        hud.supply.inUse = 0;
        hud.supply.cap = 10;
        return smarts = new SCSim.BuildOrder(rules);
      });
      it("will buy a unit it can afford and has enough supply for", function() {
        var cmd, time;
        smarts.addToBuild(0, canBuyMinOnly, buyMinOnly);
        hud.resources.minerals = 10;
        hud.supply.inUse = 9;
        time = new SCSim.SimTime;
        cmd = smarts.decideNextCommand(hud, time, rules);
        return cmd.should.equal(buyMinOnly);
      });
      it("will not buy something it can't afford", function() {
        var cmd, time;
        smarts.addToBuild(0, canBuyMinOnly, buyMinOnly);
        hud.resources.minerals = 9;
        hud.supply.inUse = 9;
        time = new SCSim.SimTime;
        cmd = smarts.decideNextCommand(hud, time, rules);
        return expect(cmd).to.be["null"];
      });
      it("will buy what it can afford at a specified time", function() {
        var cmd, time;
        smarts.addToBuild(20, canBuyMinOnly, buyMinOnly);
        hud.resources.minerals = 10;
        hud.supply.inUse = 9;
        time = new SCSim.SimTime(20);
        cmd = smarts.decideNextCommand(hud, time, rules);
        return cmd.should.equal(buyMinOnly);
      });
      return it("won't buy what it can afford _before_ the specified time", function() {
        var cmd, time;
        smarts.addToBuild(20, canBuyMinOnly, buyMinOnly);
        hud.resources.minerals = 10;
        hud.supply.inUse = 9;
        time = new SCSim.SimTime(19);
        cmd = smarts.decideNextCommand(hud, time);
        return expect(cmd).to.be["null"];
      });
    });
  });

}).call(this);
