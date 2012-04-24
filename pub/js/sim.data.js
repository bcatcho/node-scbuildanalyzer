// Generated by CoffeeScript 1.3.1
(function() {
  var SCSim, b, n, root, u, _ref,
    __slice = [].slice;

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  SCSim = (_ref = root.SCSim) != null ? _ref : {};

  root.SCSim = SCSim;

  u = function() {
    var behaviors, buildTime, gas, min, supply;
    min = arguments[0], gas = arguments[1], buildTime = arguments[2], supply = arguments[3], behaviors = 5 <= arguments.length ? __slice.call(arguments, 4) : [];
    return {
      min: min,
      gas: gas,
      buildTime: buildTime,
      supply: supply,
      behaviors: behaviors
    };
  };

  b = function() {
    var behaviors, buildTime, gas, min;
    min = arguments[0], gas = arguments[1], buildTime = arguments[2], behaviors = 4 <= arguments.length ? __slice.call(arguments, 3) : [];
    return {
      min: min,
      gas: gas,
      buildTime: buildTime,
      behaviors: behaviors
    };
  };

  n = function() {
    var behaviors;
    behaviors = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return {
      behaviors: behaviors
    };
  };

  SCSim.config = {
    secsPerTick: .1,
    workerOverlapThreshold: .3
  };

  SCSim.data = {
    units: {
      probe: u(50, 0, 17, 1, "Harvester")
    },
    buildings: {
      pylon: b(100, 0, 25),
      nexus: b(400, 0, 100, "PrimaryStructure", "Trainer")
    },
    neutral: {
      minPatch: n("MinPatch")
    }
  };

}).call(this);
