// Generated by CoffeeScript 1.3.1
(function() {
  var SCSim, addSeries, options, root, runSim, series, _ref;

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  SCSim = root.SCSim;

  runSim = function(workerCount, simLength) {
    var base, d, dataChunkTime, dataFirstPass, e, i, n, perChunkToPerMin, results, sim, simTickLength, tickToDate, time, _i, _j, _k, _len, _ref;
    if (simLength == null) {
      simLength = 600;
    }
    console.profile();
    simTickLength = simLength / SCSim.config.secsPerTick;
    tickToDate = function(t) {
      return new Date(t * 1000);
    };
    sim = new SCSim.Simulation;
    sim.logger.fwatchFor('mineralsCollected', function(e) {
      return [e.time.sec, e.args[0] / (e.time.sec / 60)];
    });
    sim.logger.fwatchFor('doneBuildUnit', function(e) {
      return tickToDate(e.time.sec);
    });
    base = sim.makeActor("nexus");
    sim.say('start');
    for (i = _i = 1; 1 <= workerCount ? _i <= workerCount : _i >= workerCount; i = 1 <= workerCount ? ++_i : --_i) {
      base.say("trainUnit", 'probe');
    }
    for (i = _j = 1; 1 <= simTickLength ? _j <= simTickLength : _j >= simTickLength; i = 1 <= simTickLength ? ++_j : --_j) {
      sim.update();
    }
    results = {
      data: [],
      markings: []
    };
    dataFirstPass = [];
    dataChunkTime = 4 * (2 + 2 + 1.57);
    perChunkToPerMin = function(amt) {
      return amt * (60 / dataChunkTime);
    };
    _ref = sim.logger.event('mineralsCollected');
    for (_k = 0, _len = _ref.length; _k < _len; _k++) {
      e = _ref[_k];
      time = Math.floor(e[0] / dataChunkTime);
      if (dataFirstPass[time] === void 0) {
        dataFirstPass[time] = {
          time: tickToDate(time * dataChunkTime),
          amt: 0
        };
      }
      dataFirstPass[time].amt += 5;
    }
    results.data = (function() {
      var _results;
      _results = [];
      for (n in dataFirstPass) {
        d = dataFirstPass[n];
        _results.push([d.time, perChunkToPerMin(d.amt)]);
      }
      return _results;
    })();
    console.profileEnd();
    return results;
  };

  options = {
    grid: {
      borderWidth: 0,
      markings: []
    },
    xaxis: {
      mode: "time",
      timeformat: "%M:%S"
    }
  };

  series = [];

  addSeries = function(series, options, workerCount) {
    var results;
    results = runSim(workerCount, 800);
    series.push({
      data: results.data,
      shadowSize: 0,
      lines: {
        lineWidth: 2
      }
    });
    options.grid.markings = options.grid.markings.concat(results.markings);
    return {
      series: series,
      options: options
    };
  };

  _ref = addSeries(series, options, 14), series = _ref.series, options = _ref.options;

  $.plot($("#placeholder"), series, options);

}).call(this);
