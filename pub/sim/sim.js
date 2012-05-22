// Generated by CoffeeScript 1.3.3
(function() {
  var SCSim, addSeries, makeSmarts, options, root, runSim, series, _ref;

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  SCSim = root.SCSim;

  runSim = function(harvesterCount, simLength, smarts) {
    var d, dataChunkTime, dataFirstPass, e, i, logs, n, perChunkToPerMin, results, sim, simRun, simTickLength, tickToDate, time, _i, _j, _len, _ref,
      _this = this;
    if (simLength == null) {
      simLength = 600;
    }
    simTickLength = simLength / SCSim.config.secsPerTick;
    tickToDate = function(t) {
      return new Date(t * 1000);
    };
    logs = {
      mineralsCollected: []
    };
    simRun = new SCSim.SimRun(SCSim.data, smarts);
    sim = simRun.sim;
    simRun.emitter.observe('depositMinerals', function(e) {
      return logs.mineralsCollected.push([e.time.sec, e.args[0] / (e.time.sec / 60)]);
    });
    simRun.start();
    for (i = _i = 1; 1 <= simTickLength ? _i <= simTickLength : _i >= simTickLength; i = 1 <= simTickLength ? ++_i : --_i) {
      simRun.update();
    }
    console.log(sim.makeActor("pylon"));
    results = {
      data: [],
      markings: []
    };
    dataChunkTime = 25.;
    dataFirstPass = [];
    _ref = logs.mineralsCollected;
    for (_j = 0, _len = _ref.length; _j < _len; _j++) {
      e = _ref[_j];
      time = Math.floor(e[0] / dataChunkTime);
      if (dataFirstPass[time] === void 0) {
        dataFirstPass[time] = {
          time: tickToDate(time * dataChunkTime),
          amt: 0
        };
      }
      dataFirstPass[time].amt += 5;
    }
    perChunkToPerMin = function(amt) {
      return amt * (60 / dataChunkTime);
    };
    results.data = (function() {
      var _results;
      _results = [];
      for (n in dataFirstPass) {
        d = dataFirstPass[n];
        _results.push([d.time, perChunkToPerMin(d.amt)]);
      }
      return _results;
    })();
    return results;
  };

  makeSmarts = function(harvesterCount) {
    var helper, smarts;
    smarts = new SCSim.Smarts;
    helper = new SCSim.BuildHelper;
    helper.trainProbesConstantly(smarts, harvesterCount);
    return smarts;
  };

  addSeries = function(series, options, harvesterCount) {
    var results;
    results = runSim(harvesterCount, 600, makeSmarts(harvesterCount));
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

  _ref = addSeries(series, options, 14), series = _ref.series, options = _ref.options;

  $.plot($("#placeholder"), series, options);

}).call(this);
