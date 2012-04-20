// Generated by CoffeeScript 1.3.1
(function() {
  var SCSim, chai, root, should, _;

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  chai = root.chai;

  should = chai.should();

  SCSim = root.SCSim;

  _ = root._;

  _.mixin({
    containsInstanceOf: function(collection, theType) {
      if (_(collection).isObject()) {
        collection = _(collection).values();
      }
      return _(collection).any(function(i) {
        return i instanceof theType;
      });
    }
  });

  describe('EconSim with one base one worker', function() {
    var base, sim;
    sim = new SCSim.EconSim;
    base = null;
    describe('When told to create a new EconSim::Base', function() {
      base = sim.createActor(SCSim.SimBase);
      return it('should have a new EconSim::Base subActor', function() {
        return _(sim.subActors).containsInstanceOf(SCSim.SimBase).should.equal(true);
      });
    });
    describe('When told to start', function() {
      it('should change state to running', function() {
        sim.say('start');
        return sim.stateName.should.equal('running');
      });
      return it('should be at tick count = 0', function() {
        return sim.time.tick.should.equal(0);
      });
    });
    return describe('When the base creates a new worker', function() {
      base.say('buildNewWorker');
      it('should _not yet_ have another subActor that is a EconSim::Worker', function() {
        return _(sim.subActors).containsInstanceOf(SCSim.SimWorker).should.equal(false);
      });
      it('but after update(build time) it should have a Worker subActor', function() {
        var i, _i, _ref;
        for (i = _i = 1, _ref = base.t_buildWorker; 1 <= _ref ? _i <= _ref : _i >= _ref; i = 1 <= _ref ? ++_i : --_i) {
          sim.update();
        }
        return _(sim.subActors).containsInstanceOf(SCSim.SimWorker).should.equal(true);
      });
      return it('the base should receive minerals after some time', function() {
        var i, _i;
        for (i = _i = 1; _i <= 50; i = ++_i) {
          sim.update();
        }
        return base.mineralAmt.should.be.above(0);
      });
    });
  });

  describe('EconSim with one base and two workers', function() {
    var base, sim;
    sim = new SCSim.EconSim;
    sim.logger.fwatchFor('workerStartedMining', function(e) {
      return "" + e.simId;
    });
    sim.say('start');
    base = sim.createActor(SCSim.SimBase);
    it('should queue up two workers at base', function() {
      base.say('buildNewWorker');
      base.say('buildNewWorker');
      base.say('buildNewWorker');
      sim.update();
      return base.buildQueue.length.should.equal(3);
    });
    it('will make the first worker harvest while the 2nd builds', function() {
      while (base.buildQueue.length > 0) {
        sim.update();
      }
      return base.mineralAmt.should.be.above(0);
    });
    return it('will distribute the workers amongst two mineral patches', function() {
      var i, timeOut, _i;
      timeOut = 200;
      while (!sim.logger.eventOccurs('workerCanceledHarvest', timeOut--)) {
        sim.update();
      }
      for (i = _i = 1; _i <= 40; i = ++_i) {
        sim.update();
      }
      console.log(_(sim.logger.event('workerStartedMining')).unique());
      return _(sim.logger.event('workerStartedMining')).unique().length.should.be.above(1);
    });
  });

  describe('MineralPatch', function() {
    it('sets up', function() {
      var min;
      min = new SCSim.SimMineralPatch;
      return min.amt.should.be.a('number');
    });
    it('attaches new workers that target it via event', function() {
      var min;
      min = new SCSim.SimMineralPatch;
      min.say('workerArrived', new SCSim.SimWorker);
      return min.workers.length.should.equal(1);
    });
    return it('subtract minerals on mineralsHarvested event', function() {
      var expectedAmt, min;
      min = new SCSim.SimMineralPatch;
      expectedAmt = min.amt - 5;
      min.say('mineralsHarvested', 5);
      return min.amt.should.equal(expectedAmt);
    });
  });

  describe('Worker.gatherResource()', function() {
    var base, minPatch, minPatchOriginalAmt, sim, wrkr;
    sim = new SCSim.EconSim();
    sim.logger.watchFor(["depositMinerals"]);
    sim.say('start');
    wrkr = sim.createActor(SCSim.SimWorker);
    base = sim.createActor(SCSim.SimBase);
    minPatch = base.getMostAvailableMinPatch();
    minPatchOriginalAmt = minPatch.amt;
    wrkr.say('gatherMinerals', minPatch);
    describe('first', function() {
      it('will target the patch specificied by the base', function() {
        return wrkr.targetResource.should.equal(minPatch);
      });
      it('then should start traveling to said patch', function() {
        return wrkr.stateName.should.equal('approachResource');
      });
      it('and should take the right amount of time to get there', function() {
        var i, travelTime, _i;
        travelTime = wrkr.t_toPatch;
        for (i = _i = 0; 0 <= travelTime ? _i <= travelTime : _i >= travelTime; i = 0 <= travelTime ? ++_i : --_i) {
          sim.update();
        }
        return wrkr.stateName.should.not.equal('approachResource');
      });
      return it('it should immediately start to mine', function() {
        return wrkr.stateName.should.equal('harvest');
      });
    });
    describe('then once the mining time is up', function() {
      it('will start traveling back to base once the mining time is up', function() {
        var i, travelTime, _i;
        travelTime = wrkr.t_mine;
        for (i = _i = 0; 0 <= travelTime ? _i <= travelTime : _i >= travelTime; i = 0 <= travelTime ? ++_i : --_i) {
          sim.update();
        }
        return wrkr.stateName.should.equal('approachDropOff');
      });
      it('should have removed minerals from the mineral patch', function() {
        return minPatch.amt.should.equal(minPatchOriginalAmt - wrkr.collectAmt);
      });
      it('should be removed from the mineral\'s worker queueu', function() {
        return minPatch.workers.should.not.include(wrkr);
      });
      return it('should take the right amount of time to get there', function() {
        var i, _i, _ref;
        for (i = _i = 0, _ref = wrkr.t_toBase; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
          sim.update();
        }
        return wrkr.stateName.should.equal('approachResource');
      });
    });
    describe('when it arrives at the base', function() {
      it('will deposite the right amount of minerals to the base', function() {
        return minPatch.base.mineralAmt.should.equal(wrkr.collectAmt);
      });
      return it('then goes back to the same mineral patch', function() {
        wrkr.stateName.should.equal('approachResource');
        return wrkr.targetResource.should.equal(minPatch);
      });
    });
    return describe('all the while, the event logger', function() {
      return it("should have heard about the base's new minerals", function() {
        return sim.logger.event('depositMinerals').length.should.equal(1);
      });
    });
  });

}).call(this);