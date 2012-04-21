// Generated by CoffeeScript 1.3.1
(function() {
  var EconSim, SCSim, SimBase, SimMineralPatch, SimWorker, root, _, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  _ = root._;

  SCSim = (_ref = root.SCSim) != null ? _ref : {};

  root.SCSim = SCSim;

  SCSim.EconSim = EconSim = (function(_super) {

    __extends(EconSim, _super);

    EconSim.name = 'EconSim';

    function EconSim() {
      this.subActors = {};
      this.logger = new SCSim.SimEventLog;
      this.time = new SCSim.SimTimer;
      EconSim.__super__.constructor.call(this);
    }

    EconSim.prototype.createActor = function(actr, a, b, c, d) {
      var instance;
      instance = new actr(a, b, c, d);
      instance.sim = this;
      instance.simId = _.uniqueId();
      instance.logger = this.logger;
      instance.time = this.time;
      this.subActors[instance.simId] = instance;
      if (typeof instance.instantiate === "function") {
        instance.instantiate();
      }
      return instance;
    };

    EconSim.prototype.getActor = function(simId) {
      return this.subActors[simId];
    };

    EconSim.defaultState({
      update: EconSim.noopUpdate,
      messages: {
        start: function() {
          return this.switchStateTo('running');
        }
      }
    });

    EconSim.state("running", {
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
      }
    });

    return EconSim;

  })(SCSim.SimActor);

  SCSim.SimBase = SimBase = (function(_super) {

    __extends(SimBase, _super);

    SimBase.name = 'SimBase';

    function SimBase() {
      this.mineralAmt = 0;
      this.mins = [];
      this.rallyResource = this.mins[0];
      this.buildQueue = [];
      SimBase.__super__.constructor.call(this);
    }

    SimBase.prototype.instantiate = function() {
      var i, wrkr, _i, _j, _len, _ref1, _results;
      this.mins = (function() {
        var _i, _results;
        _results = [];
        for (i = _i = 1; _i <= 8; i = ++_i) {
          _results.push(this.sim.createActor(SimMineralPatch, this));
        }
        return _results;
      }).call(this);
      for (i = _i = 1; _i <= 6; i = ++_i) {
        this.workers = this.sim.createActor(SCSim.SimWorker, this);
      }
      this.rallyResource = this.mins[0];
      _ref1 = this.workers;
      _results = [];
      for (_j = 0, _len = _ref1.length; _j < _len; _j++) {
        wrkr = _ref1[_j];
        _results.push(wrkr.say('gatherFromMinPatch', this.rallyResource));
      }
      return _results;
    };

    SimBase.prototype.updateBuildQueue = function() {
      var unit;
      if (this.buildQueue.length > 0) {
        unit = this.buildQueue[0];
        if (this.isExpired(unit.buildTime - (this.time.sec - unit.startTime))) {
          return this.say('doneBuildUnit', unit.unitName);
        }
      }
    };

    SimBase.prototype.getMostAvailableMinPatch = function() {
      this.mins = _.sortBy(this.mins, function(m) {
        return m.targetedBy;
      });
      return this.mins[0];
    };

    SimBase.defaultState({
      update: function() {
        return function() {
          return this.updateBuildQueue();
        };
      },
      messages: {
        depositMinerals: function(minAmt) {
          this.mineralAmt += minAmt;
          return this.say('mineralsCollected', this.mineralAmt);
        },
        buildUnit: function(unitName) {
          var u;
          u = SCSim.data.units[unitName];
          return this.buildQueue.push({
            startTime: this.time.sec,
            buildTime: u.buildTime,
            unitName: unitName
          });
        },
        doneBuildUnit: function(unitName) {
          var unit;
          unit = this.sim.createActor(SCSim.data.units[unitName].actor());
          unit.say('gatherFromMinPatch', this.rallyResource);
          this.buildQueue = this.buildQueue.slice(1);
          if (this.buildQueue.length > 0) {
            return this.buildQueue[0].startTime = this.time.sec;
          }
        }
      }
    });

    return SimBase;

  })(SCSim.SimActor);

  SCSim.SimMineralPatch = SimMineralPatch = (function(_super) {

    __extends(SimMineralPatch, _super);

    SimMineralPatch.name = 'SimMineralPatch';

    function SimMineralPatch(base, startingAmt) {
      if (startingAmt == null) {
        startingAmt = 100;
      }
      this.amt = startingAmt;
      this.base = base;
      this.workers = [];
      this.workerMining = null;
      this.targetedBy = 0;
      this.workerOverlapThreshold = SCSim.config.workerOverlapThreshold;
      SimMineralPatch.__super__.constructor.call(this);
    }

    SimMineralPatch.prototype.getClosestAvailableResource = function() {
      var m, sortedMins, _i, _len;
      sortedMins = _(this.base.mins).sortBy(function(m) {
        return m.targetedBy;
      });
      for (_i = 0, _len = sortedMins.length; _i < _len; _i++) {
        m = sortedMins[_i];
        if (m !== this) {
          return m;
        }
      }
    };

    SimMineralPatch.prototype.isAvailable = function() {
      return this.workerMining === null;
    };

    SimMineralPatch.prototype.isAvailableSoon = function(wrkr) {
      return this.workerMiningTimeDone - this.time.sec < this.workerOverlapThreshold;
    };

    SimMineralPatch.defaultState({
      update: SimMineralPatch.noopUpdate,
      messages: {
        workerArrived: function(wrkr) {
          return this.workers.push(wrkr);
        },
        mineralsHarvested: function(amtHarvested) {
          return this.amt -= amtHarvested;
        },
        workerStartedMining: function(wrkr, timeMiningDone) {
          this.workerMiningTimeDone = timeMiningDone;
          return this.workerMining = wrkr;
        },
        workerFinishedMiningXminerals: function(wrkr, amtMined) {
          this.workerMining = null;
          this.workers = _(this.workers).rest();
          return this.amt -= amtMined;
        },
        workerCanceledHarvest: function(wrkr) {
          this.workers = _(this.workers).without(wrkr);
          if (this.workerMining === wrkr) {
            return this.workerMining = null;
          }
        },
        targetedByHarvester: function() {
          return this.targetedBy += 1;
        },
        untargetedByHarvester: function() {
          return this.targetedBy -= 1;
        }
      }
    });

    return SimMineralPatch;

  })(SCSim.SimActor);

  SCSim.SimWorker = SimWorker = (function(_super) {

    __extends(SimWorker, _super);

    SimWorker.name = 'SimWorker';

    function SimWorker() {
      this.t_toBase = 2;
      this.t_toPatch = 2;
      this.t_mine = 1.5;
      this.targetResource;
      this.collectAmt = 5;
      SimWorker.__super__.constructor.call(this, 'idle');
    }

    SimWorker.state("idle", {
      update: SimWorker.noopUpdate,
      messages: {
        gatherMinerals: function(minPatch) {
          return this.say('gatherFromMinPatch', minPatch);
        },
        gatherFromMinPatch: function(minPatch) {
          this.targetResource = minPatch;
          this.targetResource.say('targetedByHarvester');
          return this.switchStateTo('approachResource');
        }
      }
    });

    SimWorker.state("approachResource", {
      update: function() {
        return this.sayAfter(this.t_toBase, 'arrivedAtMinPatch');
      },
      messages: {
        arrivedAtMinPatch: function() {
          this.targetResource.say('workerArrived', this);
          return this.switchStateTo('waitAtResource');
        }
      }
    });

    SimWorker.state("waitAtResource", {
      update: function() {
        return function() {
          if (this.targetResource.isAvailable()) {
            return this.switchStateTo('harvest');
          }
        };
      },
      enterState: function() {
        var nextResource;
        if (this.targetResource.isAvailable()) {
          return this.switchStateTo('harvest');
        } else if (!this.targetResource.isAvailableSoon()) {
          nextResource = this.targetResource.getClosestAvailableResource();
          if (nextResource) {
            return this.say('changeTargetResource', nextResource);
          }
        }
      },
      messages: {
        changeTargetResource: function(newResource) {
          this.targetResource.say('workerCanceledHarvest', this);
          this.targetResource.say('untargetedByHarvester');
          this.targetResource = newResource;
          this.targetResource.say('targetedByHarvester');
          return this.switchStateTo('approachResource');
        }
      }
    });

    SimWorker.state("harvest", {
      update: function() {
        return this.sayAfter(this.t_mine, 'finishedMining');
      },
      enterState: function() {
        return this.targetResource.say('workerStartedMining', this, this.time.sec + this.t_mine);
      },
      messages: {
        finishedMining: function() {
          this.targetResource.say('workerFinishedMiningXminerals', this, this.collectAmt);
          return this.switchStateTo('approachDropOff', this.targetResource.base);
        }
      }
    });

    SimWorker.state("approachDropOff", {
      update: function(base) {
        return this.sayAfter(this.t_toBase, 'arrivedAtBase', base);
      },
      messages: {
        arrivedAtBase: function(base) {
          return this.switchStateTo('dropOff', base);
        }
      }
    });

    SimWorker.state("dropOff", {
      update: SimWorker.noopUpdate,
      enterState: function(base) {
        base.say('depositMinerals', this.collectAmt);
        return this.say('finishedDropOff', base);
      },
      messages: {
        finishedDropOff: function(base) {
          return this.switchStateTo('approachResource');
        }
      }
    });

    return SimWorker;

  })(SCSim.SimActor);

}).call(this);
