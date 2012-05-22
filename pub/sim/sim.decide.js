// Generated by CoffeeScript 1.3.3
(function() {
  var SCSim, root, _, _ref,
    __slice = [].slice,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  SCSim = (_ref = root.SCSim) != null ? _ref : {};

  root.SCSim = SCSim;

  _ = root._;

  SCSim.Hud = (function() {

    function Hud(emitter) {
      this.minerals = 0;
      this.gas = 0;
      this.supply = 0;
      this.supplyCap = 10;
      this.production = {};
      this.alerts = [];
      this.economy = {};
      this.units = {};
      this.structures = {};
      this.events = {};
      this.emitter = emitter;
      this.setupEvents();
    }

    Hud.prototype.addUnit = function(unit) {
      if (!this.units[unit.actorName]) {
        this.units[unit.actorName] = [];
      }
      return this.units[unit.actorName].push(unit);
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
      this.addEvent("trainingComplete", function(e) {
        return e.args[0];
      }, function(actor) {
        var _base, _name, _ref1;
        if (SCSim.data.isStructure(actor.actorName)) {
          if ((_ref1 = (_base = _this.structures)[_name = actor.actorName]) == null) {
            _base[_name] = [];
          }
          return _this.structures[actor.actorName].push(actor);
        }
      });
      this.addEvent("trainUnitComplete", function(e) {
        return e.args[0];
      }, function(unit) {
        var u, _base, _name, _ref1;
        u = SCSim.data.units[unit.actorName];
        _this.supply += u.supply;
        if ((_ref1 = (_base = _this.units)[_name = unit.actorName]) == null) {
          _base[_name] = [];
        }
        return _this.units[unit.actorName].push(unit);
      });
      this.addEvent("supplyCapIncreased", function(e) {
        return e.args[0];
      }, function(supplyAmt) {
        return _this.supplyCap += supplyAmt;
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

  SCSim.GameRules = (function() {

    function GameRules(gameData) {
      this.gameData = gameData;
    }

    GameRules.prototype.canTrainUnit = function(unitName, hud) {
      var data;
      data = this.gameData.get(unitName);
      return this.meetsCriteria(data, hud, this.canAfford, this.hasEnoughSupply, this.hasTechPath);
    };

    GameRules.prototype.canAfford = function(data, hud) {
      return hud.gas >= data.gas && hud.minerals >= data.min;
    };

    GameRules.prototype.hasEnoughSupply = function(data, hud) {
      return data.supply <= hud.supplyCap - hud.supply;
    };

    GameRules.prototype.hasTechPath = function(data, hud) {
      return true;
    };

    GameRules.prototype.meetsCriteria = function() {
      var criteria, data, hud;
      data = arguments[0], hud = arguments[1], criteria = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
      return criteria.reduce((function(acc, c) {
        return acc && c(data, hud);
      }), true);
    };

    return GameRules;

  })();

  SCSim.Cmd = (function() {

    function Cmd(subject, verbs) {
      this.subject = subject;
      this.verbs = verbs != null ? verbs : [];
    }

    Cmd.selectA = function(name) {
      return new this(function(hud) {
        var _ref1, _ref2;
        return ((_ref1 = hud.structures[name]) != null ? _ref1[0] : void 0) || ((_ref2 = hud.units[name]) != null ? _ref2[0] : void 0);
      });
    };

    Cmd.prototype.say = function(msg, a, b, c, d) {
      this.verbs.push(function(unit) {
        return unit.say(msg, a, b, c, d);
      });
      return this;
    };

    Cmd.prototype.execute = function(hud) {
      var s, v, _i, _len, _ref1, _results;
      s = this.subject(hud);
      _ref1 = this.verbs;
      _results = [];
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        v = _ref1[_i];
        _results.push(v(s));
      }
      return _results;
    };

    return Cmd;

  })();

  SCSim.Smarts = (function() {

    function Smarts(gameData) {
      this.build = [];
      this.rules = new SCSim.GameRules(gameData);
    }

    Smarts.prototype.decideNextCommand = function(hud, time) {
      if (this.build.length === 0) {
        return null;
      }
      if (this.build[0].seconds <= time.sec && this.build[0].iterator(hud, this.rules)) {
        return this.build.pop(0).cmd;
      }
      return null;
    };

    Smarts.prototype.addToBuild = function(seconds, iterator, cmd) {
      var buildStep, index;
      buildStep = {
        seconds: seconds,
        iterator: iterator,
        cmd: cmd
      };
      index = _(this.build).sortedIndex(buildStep, function(bStep) {
        return bStep.seconds;
      });
      return this.build.splice(index, 0, buildStep);
    };

    return Smarts;

  })();

  SCSim.SimRun = (function() {

    function SimRun(gameData, smarts) {
      this.gameData = gameData != null ? gameData : SCSim.data;
      this.smarts = smarts != null ? smarts : new SCSim.Smarts;
      this.emitter = new SCSim.EventEmitter;
      this.hud = new SCSim.Hud(this.emitter);
      this.sim = new SCSim.Simulation(this.emitter, this.gameData);
    }

    SimRun.prototype.update = function() {
      var command;
      command = this.smarts.decideNextCommand(this.hud, this.sim.time);
      if (command != null) {
        command.execute(this.hud);
      }
      return this.sim.update();
    };

    SimRun.prototype.start = function() {
      return this.sim.say("start");
    };

    return SimRun;

  })();

  SCSim.Simulation = (function(_super) {

    __extends(Simulation, _super);

    function Simulation(emitter, gameData) {
      this.emitter = emitter;
      this.gameData = gameData;
      this.subActors = {};
      this.time = new SCSim.SimTime;
      this.beingBuilt = [];
      Simulation.__super__.constructor.call(this);
      this.instantiate();
    }

    Simulation.prototype.makeActor = function(name, a, b, c, d) {
      var actorData, instance;
      actorData = this.gameData.get(name);
      instance = new SCSim.Actor(actorData.behaviors, a, b, c, d);
      instance.actorName = name;
      instance.sim = this;
      instance.simId = _.uniqueId();
      instance.emitter = this.emitter;
      instance.time = this.time;
      this.subActors[instance.simId] = instance;
      if (typeof instance.instantiate === "function") {
        instance.instantiate();
      }
      return instance;
    };

    Simulation.prototype.getActor = function(simId) {
      return this.subActors[simId];
    };

    Simulation.defaultState({
      messages: {
        start: function() {
          return this.go("running");
        }
      }
    });

    Simulation.state("running", {
      update: function() {
        return function(t) {
          var actr, _results;
          this.time.step(1);
          _results = [];
          for (actr in this.subActors) {
            _results.push(this.subActors[actr].update(this.time.sec));
          }
          return _results;
        };
      },
      enterState: function() {
        return SCSim.helpers.setupMap(this);
      },
      messages: {
        buildStructure: function(name) {
          var s;
          s = SCSim.data.get("name");
          this.say("purchase", name);
          return this.beingBuilt.push(name);
        }
      }
    });

    Simulation.prototype.say = function(msgName, a, b, c, d) {
      var _ref1, _ref2;
      if ((_ref1 = this.emitter) != null) {
        _ref1.fire(msgName, {
          name: msgName,
          time: this.time,
          simId: this.simId,
          args: [a, b, c, d]
        });
      }
      return (_ref2 = this.messages[msgName]) != null ? _ref2.call(this, a, b, c, d) : void 0;
    };

    Simulation.prototype.get = function(name, a, b, c, d) {
      if (this[name] !== void 0) {
        this[name].call(behavior, a, b, c, d);
      }
      return console.warn("failed to get " + prop);
    };

    return Simulation;

  })(SCSim.Behavior);

}).call(this);
