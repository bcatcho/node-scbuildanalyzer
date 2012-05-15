// Generated by CoffeeScript 1.3.1
(function() {
  var SCSim, root, _, _ref;

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  SCSim = (_ref = root.SCSim) != null ? _ref : {};

  root.SCSim = SCSim;

  _ = root._;

  SCSim.GetClass = function(obj) {
    return obj.constructor.name;
  };

  SCSim.EventEmitter = (function() {

    EventEmitter.name = 'EventEmitter';

    function EventEmitter() {
      this.events = {};
    }

    EventEmitter.prototype.observe = function(eventName, callBack) {
      var _base;
      if ((_base = this.events)[eventName] == null) {
        _base[eventName] = [];
      }
      return this.events[eventName].push(callBack);
    };

    EventEmitter.prototype.fire = function(eventName, eventObj) {
      var callBack, _i, _len, _ref1, _results;
      if (this.events[eventName] !== void 0) {
        _ref1 = this.events[eventName];
        _results = [];
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          callBack = _ref1[_i];
          _results.push(callBack(eventObj));
        }
        return _results;
      }
    };

    return EventEmitter;

  })();

  SCSim.SimTime = (function() {

    SimTime.name = 'SimTime';

    function SimTime(seconds) {
      if (seconds == null) {
        seconds = 0;
      }
      this.secPerTick = SCSim.config.secsPerTick;
      this.tick = parseInt(seconds / this.secPerTick);
      this.sec = seconds;
    }

    SimTime.prototype.step = function(steps) {
      if (steps == null) {
        steps = 1;
      }
      this.tick += steps;
      return this.sec += steps * this.secPerTick;
    };

    SimTime.prototype.reset = function() {
      this.tick = 0;
      return this.sec = 0;
    };

    return SimTime;

  })();

  SCSim.Behavior = (function() {

    Behavior.name = 'Behavior';

    function Behavior() {
      this.currentState;
      this.messages;
    }

    Behavior.prototype.instantiate = function(defaultStateName) {
      if (defaultStateName == null) {
        defaultStateName = "default";
      }
      return this.go(defaultStateName);
    };

    Behavior.prototype.update = function(t) {
      return typeof this.currentState === "function" ? this.currentState(t) : void 0;
    };

    Behavior.prototype.go = function(sn, a, b, c, d) {
      var _ref1, _ref2, _ref3;
      this.stateName = sn;
      this.currentState = (_ref1 = this.states[this.stateName].update) != null ? _ref1.call(this, a, b, c, d) : void 0;
      this.messages = (_ref2 = this.states[this.stateName].messages) != null ? _ref2 : {};
      return (_ref3 = this.states[this.stateName].enterState) != null ? _ref3.call(this, a, b, c, d) : void 0;
    };

    Behavior.prototype.say = function(msgName, a, b, c, d) {
      return this.actor.say(msgName, a, b, c, d);
    };

    Behavior.prototype.get = function(msgName, a, b, c, d) {
      return this.actor.get(msgName, a, b, c, d);
    };

    Behavior.state = function(name, stateObj) {
      if (!this.prototype.states) {
        this.prototype.states = {};
      }
      return this.prototype.states[name] = stateObj;
    };

    Behavior.defaultState = function(stateObj) {
      if (!this.prototype.states) {
        this.prototype.states = {};
      }
      return this.prototype.states["default"] = stateObj;
    };

    Behavior.prototype.blockActor = function() {
      return this.actor.startBlockingWithBehavior(this);
    };

    Behavior.prototype.unblockActor = function() {
      return this.actor.stopBlockingWithBehavior();
    };

    Behavior.prototype.isExpired = function(t) {
      return t <= 0;
    };

    Behavior.prototype.sayAfter = function(timeSpan, a, b, c, d) {
      var endTime;
      endTime = this.time.sec + timeSpan;
      return function(t) {
        if (this.isExpired(endTime - this.time.sec)) {
          return this.say(a, b, c, d);
        }
      };
    };

    return Behavior;

  })();

  SCSim.Actor = (function() {

    Actor.name = 'Actor';

    function Actor(behaviors) {
      this.behaviorConfiguration = behaviors;
      this.behaviors = {};
      this.blockingBehavior = void 0;
    }

    Actor.prototype.instantiate = function() {
      var b, behavior, _i, _len, _ref1, _ref2, _results;
      _ref1 = this.behaviorConfiguration;
      _results = [];
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        b = _ref1[_i];
        behavior = new SCSim[b.name];
        behavior.actor = this;
        behavior.simId = this.simId;
        behavior.emitter = this.emitter;
        behavior.time = this.time;
        behavior.sim = this.sim;
        if ((_ref2 = behavior.instantiate) != null) {
          _ref2.apply(behavior, b.args);
        }
        _results.push(this.behaviors[b.name] = behavior);
      }
      return _results;
    };

    Actor.prototype.startBlockingWithBehavior = function(behavior) {
      if (this.blockingBehavior !== void 0) {
        console.error("behavior already set                      to " + (SCSim.GetClass(this.blockingBehavior)));
      }
      return this.blockingBehavior = behavior;
    };

    Actor.prototype.stopBlockingWithBehavior = function() {
      return this.blockingBehavior = void 0;
    };

    Actor.prototype.update = function(t) {
      var b, n, _ref1, _results;
      if (this.blockingBehavior !== void 0) {
        return this.blockingBehavior.update(t);
      } else {
        _ref1 = this.behaviors;
        _results = [];
        for (n in _ref1) {
          b = _ref1[n];
          _results.push(b.update(t));
        }
        return _results;
      }
    };

    Actor.prototype.say = function(msgName, a, b, c, d) {
      var behavior, n, _ref1, _ref2, _ref3, _ref4, _results;
      if ((_ref1 = this.emitter) != null) {
        _ref1.fire(msgName, {
          name: msgName,
          time: this.time,
          simId: this.simId,
          args: [a, b, c, d]
        });
      }
      if (this.blockingBehavior !== void 0) {
        return (_ref2 = this.blockingBehavior.messages[msgName]) != null ? _ref2.call(this.blockingBehavior, a, b, c, d) : void 0;
      } else {
        _ref3 = this.behaviors;
        _results = [];
        for (n in _ref3) {
          behavior = _ref3[n];
          _results.push((_ref4 = behavior.messages[msgName]) != null ? _ref4.call(behavior, a, b, c, d) : void 0);
        }
        return _results;
      }
    };

    Actor.prototype.get = function(name, a, b, c, d) {
      var behavior, n, _ref1;
      _ref1 = this.behaviors;
      for (n in _ref1) {
        behavior = _ref1[n];
        if (behavior[name] !== void 0) {
          return behavior[name].call(behavior, a, b, c, d);
        }
      }
      return console.warn("failed to get " + prop);
    };

    return Actor;

  })();

}).call(this);
