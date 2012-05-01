// Generated by CoffeeScript 1.3.1
(function() {
  var SCSim, root, _, _ref;

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  SCSim = (_ref = root.SCSim) != null ? _ref : {};

  root.SCSim = SCSim;

  _ = root._;

  SCSim.Hud = (function() {

    Hud.name = 'Hud';

    function Hud(emitter) {
      this.minerals = 0;
      this.gas = 0;
      this.supply = 0;
      this.supplyCap = 0;
      this.production = {};
      this.alerts = [];
      this.economy = {};
      this.units = {};
      this.buildings = {};
      this.events = {};
      this.emitter = emitter;
      this.setupEvents();
    }

    Hud.prototype.exampleProduction = function() {
      return {
        thing: "name",
        timeLeft: 0,
        alertWhenDone: "name is done"
      };
    };

    Hud.prototype.addEvent = function(eventName, filter, callBack) {
      return this.emitter.observe(eventName, function(eventObj) {
        return callBack(filter(eventObj));
      });
    };

    Hud.prototype.setupEvents = function() {
      var _this = this;
      this.addEvent("depositMinerals", function(e) {
        return e.args[0];
      }, function(minAmt) {
        return _this.minerals += minAmt;
      });
      this.addEvent("trainUnitComplete", function(e) {
        return e.args[0].actorName;
      }, function(unitName) {
        var u;
        u = SCSim.data.units[unitName];
        return _this.supply += u.supply;
      });
      return this.addEvent("purchase", function(e) {
        return e.args[0];
      }, function(unitName) {
        var u;
        u = SCSim.data[unitName];
        _this.minerals -= u.min;
        return _this.gas -= u.gas;
      });
    };

    return Hud;

  })();

  SCSim.Smarts = (function() {

    Smarts.name = 'Smarts';

    function Smarts() {}

    return Smarts;

  })();

  SCSim.SimRun = (function() {

    SimRun.name = 'SimRun';

    function SimRun(smarts) {
      this.smarts = smarts;
      this.emitter = new SCSim.EventEmitter;
      this.hud = new SCSim.Hud(this.emitter);
      this.sim = new SCSim.Simulation(this.emitter);
    }

    SimRun.prototype.update = function() {
      return this.sim.update();
    };

    SimRun.prototype.start = function() {
      return this.sim.say("start");
    };

    return SimRun;

  })();

}).call(this);
