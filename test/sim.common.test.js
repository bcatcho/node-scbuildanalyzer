// Generated by CoffeeScript 1.3.3
(function() {
  var SCSim, chai, root, should, _,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  SCSim = root.SCSim;

  _ = root._;

  chai = root.chai;

  should = chai.should();

  SCSim.TestBehavior = (function(_super) {

    __extends(TestBehavior, _super);

    function TestBehavior() {
      this.prop = 0;
      TestBehavior.__super__.constructor.call(this);
    }

    TestBehavior.defaultState({
      update: function() {
        return function() {
          return this.prop += 1;
        };
      },
      messages: {
        prop100: function() {
          return this.prop = 100;
        }
      }
    });

    return TestBehavior;

  })(SCSim.Behavior);

  SCSim.TestBlockingBehavior = (function(_super) {

    __extends(TestBlockingBehavior, _super);

    function TestBlockingBehavior() {
      this.prop = 0;
      TestBlockingBehavior.__super__.constructor.call(this);
    }

    TestBlockingBehavior.defaultState({
      update: function() {
        return function() {
          return this.prop += 1;
        };
      },
      messages: {
        block: function() {
          return this.block();
        }
      }
    });

    return TestBlockingBehavior;

  })(SCSim.Behavior);

  SCSim.TestInstantiationBehavior = (function(_super) {

    __extends(TestInstantiationBehavior, _super);

    function TestInstantiationBehavior() {
      this.prop = 0;
      TestInstantiationBehavior.__super__.constructor.call(this);
    }

    TestInstantiationBehavior.prototype.instantiate = function(prop) {
      this.prop = prop;
      return TestInstantiationBehavior.__super__.instantiate.call(this);
    };

    TestInstantiationBehavior.defaultState({
      update: function() {
        return function() {};
      }
    });

    return TestInstantiationBehavior;

  })(SCSim.Behavior);

  describe("SCSim.Actor", function() {
    return describe("instantiate", function() {
      return it("should create a behavior with named arguments", function() {
        var a;
        a = new SCSim.Actor([
          {
            name: "TestInstantiationBehavior",
            args: [20]
          }
        ]);
        a.instantiate();
        return a.behaviors.TestInstantiationBehavior.prop.should.equal(20);
      });
    });
  });

  describe("SCSim.Behavior", function() {
    describe("blockActor()", function() {
      return it("should take over an actor", function() {
        var a;
        a = new SCSim.Actor([
          {
            name: "TestBehavior"
          }, {
            name: "TestBlockingBehavior"
          }
        ]);
        a.instantiate();
        a.behaviors.TestBlockingBehavior.blockActor();
        a.update();
        a.behaviors.TestBehavior.prop.should.equal(0);
        return a.behaviors.TestBlockingBehavior.prop.should.equal(1);
      });
    });
    return describe("unblockActor()", function() {
      return it("should let all of the Actor's behaviors start updating again", function() {
        var a;
        a = new SCSim.Actor([
          {
            name: "TestBehavior"
          }, {
            name: "TestBlockingBehavior"
          }
        ]);
        a.instantiate();
        a.behaviors.TestBlockingBehavior.blockActor();
        a.update();
        a.behaviors.TestBlockingBehavior.unblockActor();
        a.update();
        a.behaviors.TestBehavior.prop.should.equal(1);
        return a.behaviors.TestBlockingBehavior.prop.should.equal(2);
      });
    });
  });

  describe("SCSim.Trainable", function() {
    var actr, sim, simRun;
    actr = null;
    sim = null;
    simRun = null;
    beforeEach(function() {
      var gameData;
      gameData = new SCSim.GameData;
      gameData.addUnit("testUnit", 0, 0, 2, 0, {
        name: "Trainable"
      }, {
        name: "TestBehavior"
      });
      simRun = new SCSim.SimRun;
      simRun.start();
      sim = simRun.sim;
      sim.gameData = gameData;
      return actr = sim.makeActor("testUnit");
    });
    it("should aquire the correct build time", function() {
      return actr.behaviors.Trainable.buildTime.should.equal(2);
    });
    return it("should block other behaviors till done", function() {
      var i, _i;
      actr.say("prop100");
      actr.behaviors.TestBehavior.prop.should.equal(0);
      for (i = _i = 0; _i <= 10; i = ++_i) {
        simRun.update();
      }
      actr.say("prop100");
      return actr.behaviors.TestBehavior.prop.should.equal(100);
    });
  });

  describe('SCSim.UnitTrainer', function() {
    var base, simRun;
    simRun = new SCSim.SimRun;
    simRun.start();
    base = simRun.executeCmd(SCSim.GameCmd.select("nexus"));
    return it('should queue up two workers at base', function() {
      simRun.executeCmd(SCSim.GameCmd.select("nexus").and.train('probe'));
      simRun.executeCmd(SCSim.GameCmd.select("nexus").and.train('probe'));
      simRun.executeCmd(SCSim.GameCmd.select("nexus").and.train('probe'));
      return base.behaviors["UnitTrainer"].queued.length.should.equal(2);
    });
  });

}).call(this);
