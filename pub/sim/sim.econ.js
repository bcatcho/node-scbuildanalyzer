// Generated by CoffeeScript 1.3.3
(function() {
  var SCSim, root, _, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  SCSim = (_ref = root.SCSim) != null ? _ref : {};

  root.SCSim = SCSim;

  _ = root._;

  SCSim.PrimaryStructure = (function(_super) {

    __extends(PrimaryStructure, _super);

    function PrimaryStructure() {
      this.mineralAmt = 0;
      this._mins = [];
      this._rallyResource;
      PrimaryStructure.__super__.constructor.call(this);
    }

    PrimaryStructure.prototype.rallyResource = function() {
      return this._rallyResource;
    };

    PrimaryStructure.prototype.mins = function() {
      return this._mins;
    };

    PrimaryStructure.prototype.instantiate = function() {
      var i, min, _i;
      PrimaryStructure.__super__.instantiate.call(this);
      for (i = _i = 1; _i <= 8; i = ++_i) {
        min = this.sim.makeActor("minPatch");
        min.say("setBase", this);
        this._mins.push(min);
      }
      return this._rallyResource = this._mins[0];
    };

    PrimaryStructure.prototype.getMostAvailableMinPatch = function() {
      return _(this._mins).min(function(m) {
        return m.get("targetedBy");
      });
    };

    PrimaryStructure.defaultState({
      messages: {
        depositMinerals: function(minAmt) {
          return this.mineralAmt += minAmt;
        },
        trainUnitComplete: function(unit) {
          return unit.say("gatherFromResource", this._rallyResource);
        }
      }
    });

    return PrimaryStructure;

  })(SCSim.Behavior);

  SCSim.SupplyStructure = (function(_super) {

    __extends(SupplyStructure, _super);

    function SupplyStructure() {
      SupplyStructure.__super__.constructor.call(this);
    }

    SupplyStructure.prototype.instantiate = function(supply) {
      this.supplyAmt = supply;
      return SupplyStructure.__super__.instantiate.call(this);
    };

    SupplyStructure.defaultState({
      messages: {
        trainingComplete: function() {
          return this.say("supplyCapIncreased", this.supplyAmt);
        }
      }
    });

    return SupplyStructure;

  })(SCSim.Behavior);

  SCSim.MinPatch = (function(_super) {

    __extends(MinPatch, _super);

    function MinPatch() {
      this.amt = 100;
      this._base;
      this._targetedBy = 0;
      this.harvesters = [];
      this.harvesterMining = null;
      this.harvesterOverlapThreshold = SCSim.config.harvesterOverlapThreshold;
      MinPatch.__super__.constructor.call(this);
    }

    MinPatch.prototype.base = function() {
      return this._base;
    };

    MinPatch.prototype.targetedBy = function() {
      return this._targetedBy;
    };

    MinPatch.prototype.getClosestAvailableResource = function() {
      return this._base.get("getMostAvailableMinPatch");
    };

    MinPatch.prototype.isAvailable = function() {
      return this.harvesterMining === null;
    };

    MinPatch.prototype.isAvailableSoon = function(harvester) {
      return this.harvesterMiningTimeDone - this.time.sec < this.harvesterOverlapThreshold;
    };

    MinPatch.defaultState({
      messages: {
        setBase: function(base) {
          return this._base = base;
        },
        harvesterArrived: function(harvester) {
          return this.harvesters.push(harvester);
        },
        mineralsHarvested: function(amtHarvested) {
          return this.amt -= amtHarvested;
        },
        harvestBegan: function(harvester, timeMiningDone) {
          this.harvesterMiningTimeDone = timeMiningDone;
          return this.harvesterMining = harvester;
        },
        harvestComplete: function(harvester, amtMined) {
          this.harvesterMining = null;
          this.harvesters = _(this.harvesters).rest();
          return this.amt -= amtMined;
        },
        harvestAborted: function(harvester) {
          this.harvesters = _(this.harvesters).without(harvester);
          if (this.harvesterMining === harvester) {
            return this.harvesterMining = null;
          }
        },
        targetedByHarvester: function() {
          return this._targetedBy += 1;
        },
        untargetedByHarvester: function() {
          return this._targetedBy -= 1;
        }
      }
    });

    return MinPatch;

  })(SCSim.Behavior);

  SCSim.Harvester = (function(_super) {

    __extends(Harvester, _super);

    function Harvester() {
      this.t_toBase = 2;
      this.t_toPatch = 2;
      this.t_mine = 1.5;
      this.targetResource;
      this.collectAmt = 5;
      Harvester.__super__.constructor.call(this);
    }

    Harvester.defaultState({
      messages: {
        gatherFromResource: function(resource) {
          this.targetResource = resource;
          this.targetResource.say("targetedByHarvester");
          return this.go("approachResource");
        }
      }
    });

    Harvester.state("approachResource", {
      update: function() {
        return this.sayAfter(this.t_toBase, "resourceReached");
      },
      messages: {
        resourceReached: function() {
          this.targetResource.say("harvesterArrived", this);
          return this.go("waitAtResource");
        }
      }
    });

    Harvester.state("waitAtResource", {
      update: function() {
        return function() {
          if (this.targetResource.get("isAvailable")) {
            return this.go("harvest");
          }
        };
      },
      enterState: function() {
        var nextResource;
        if (this.targetResource.get("isAvailable")) {
          return this.go("harvest");
        } else if (!this.targetResource.get("isAvailableSoon")) {
          nextResource = this.targetResource.get("getClosestAvailableResource");
          if (nextResource) {
            return this.say("changeTargetResource", nextResource);
          }
        }
      },
      messages: {
        changeTargetResource: function(newResource) {
          this.targetResource.say("harvestAborted", this);
          this.targetResource.say("untargetedByHarvester");
          this.targetResource = newResource;
          this.targetResource.say("targetedByHarvester");
          return this.go("approachResource");
        }
      }
    });

    Harvester.state("harvest", {
      update: function() {
        return this.sayAfter(this.t_mine, "harvestComplete");
      },
      enterState: function() {
        return this.targetResource.say("harvestBegan", this, this.time.sec + this.t_mine);
      },
      messages: {
        harvestComplete: function() {
          this.targetResource.say("harvestComplete", this, this.collectAmt);
          return this.go("approachDropOff", this.targetResource.get("base"));
        }
      }
    });

    Harvester.state("approachDropOff", {
      update: function(dropOff) {
        return this.sayAfter(this.t_toBase, "dropOffReached", dropOff);
      },
      messages: {
        dropOffReached: function(dropOff) {
          return this.go("dropOff", dropOff);
        }
      }
    });

    Harvester.state("dropOff", {
      enterState: function(dropOff) {
        dropOff.say("depositMinerals", this.collectAmt);
        return this.say("dropOffComplete", dropOff);
      },
      messages: {
        dropOffComplete: function(dropOff) {
          return this.go("approachResource");
        }
      }
    });

    return Harvester;

  })(SCSim.Behavior);

}).call(this);
