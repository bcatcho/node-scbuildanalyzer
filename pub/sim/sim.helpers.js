// Generated by CoffeeScript 1.3.3
(function() {
  var SCSim, root, _, _ref;

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  SCSim = (_ref = root.SCSim) != null ? _ref : {};

  root.SCSim = SCSim;

  _ = root._;

  SCSim.helpers = {
    setupMap: function(sim) {
      var nexus;
      nexus = sim.makeActor("nexus");
      return nexus.say("trainInstantly");
    }
  };

}).call(this);
