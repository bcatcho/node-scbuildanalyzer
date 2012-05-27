// Generated by CoffeeScript 1.3.3
(function() {
  var SCSim, SCe, enumFromList, root, _, _ref, _ref1,
    __slice = [].slice;

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  SCSim = (_ref = root.SCSim) != null ? _ref : {};

  root.SCSim = SCSim;

  if ((_ref1 = SCSim.Enums) == null) {
    SCSim.Enums = {};
  }

  SCe = SCSim.Enums;

  _ = root._;

  enumFromList = function() {
    var list, obj, str, _i, _len;
    list = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    obj = {};
    for (_i = 0, _len = list.length; _i < _len; _i++) {
      str = list[_i];
      obj[str] = str;
    }
    return obj;
  };

  SCe.Msg = enumFromList("depositMinerals", "trainingComplete", "trainUnit");

  SCSim.GameState = (function() {

    function GameState(emitter, rules) {
      this.resources = {
        minerals: 0,
        gas: 0
      };
      this.supply = {
        inUse: 0,
        cap: 0
      };
      this.units = {};
      this.structures = {};
      this.observeEvents(emitter, rules);
    }

    GameState.prototype.addUnit = function(unit) {
      if (!this.units[unit.actorName]) {
        this.units[unit.actorName] = [];
      }
      return this.units[unit.actorName].push(unit);
    };

    GameState.prototype.observeEvents = function(emitter, rules) {
      var obs,
        _this = this;
      obs = function(eventName, filter, callBack) {
        return emitter.observe(eventName, function(eventObj) {
          return callBack(filter(eventObj));
        });
      };
      obs(SCe.Msg.depositMinerals, function(e) {
        return e.args[0];
      }, function(minAmt) {
        return rules.applyCollectResources(_this, minAmt, 0);
      });
      obs(SCe.Msg.trainingComplete, function(e) {
        return e.args[0];
      }, function(actor) {
        var _base, _name, _ref2;
        if (SCSim.data.isStructure(actor.actorName)) {
          if ((_ref2 = (_base = _this.structures)[_name = actor.actorName]) == null) {
            _base[_name] = [];
          }
          return _this.structures[actor.actorName].push(actor);
        }
      });
      return obs("trainUnitComplete", function(e) {
        return e.args[0];
      }, function(unit) {
        var u, _base, _name, _ref2;
        u = SCSim.data.units[unit.actorName];
        _this.supply.inUse += u.supply;
        if ((_ref2 = (_base = _this.units)[_name = unit.actorName]) == null) {
          _base[_name] = [];
        }
        return _this.units[unit.actorName].push(unit);
      });
    };

    return GameState;

  })();

  SCSim.GameRules = (function() {

    function GameRules(gameData) {
      this.gameData = gameData;
    }

    GameRules.prototype.canTrainUnit = function(gameState, unitName) {
      var unit;
      unit = this.gameData.get(unitName);
      return this.meetsCriteria(unit, gameState, this.canAfford, this.hasEnoughSupply, this.hasTechPath);
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

    GameRules.prototype.applyCollectResources = function(gameState, minerals, gas) {
      gameState.resources.minerals += minerals;
      return gameState.resources.gas += gas;
    };

    GameRules.prototype.applyTrainUnit = function(gameState, unitName) {
      var unit;
      unit = this.gameData.get(unitName);
      gameState.resources.minerals -= unit.min;
      gameState.resources.gas -= unit.gas;
      return gameState.supply.inUse += unit.supply;
    };

    return GameRules;

  })();

  SCSim.GameCmdInterpreter = (function() {

    function GameCmdInterpreter(hud, rules) {
      this.hud = hud;
      this.rules = rules;
      this.testState = {
        resources: {
          minerals: 0,
          gas: 0
        },
        supply: {
          inUse: 0,
          cap: 0
        }
      };
      this.verbToRule = {
        train: "applyTrainUnit"
      };
    }

    GameCmdInterpreter.prototype.execute = function(gameState, rules, cmd) {
      var actor, actors;
      actors = gameState.units[cmd.subject] || gameState.structures[cmd.subject];
      actor = actors[0];
      this._applyRuleForAction(gameState, rules, cmd.verb, cmd.verbObject);
      return this._executeAction(actor, cmd.verb, cmd.verbObject);
    };

    GameCmdInterpreter.prototype.canExecute = function(gameState, rules, cmd) {
      this.testState.resources.minerals = gameState.resources.minerals;
      this.testState.resources.gas = gameState.resources.gas;
      this.testState.supply.inUse = gameState.supply.inUse;
      this.testState.supply.cap = gameState.supply.cap;
      this._applyRuleForAction(this.testState, rules, cmd.verb, cmd.verbObject);
      if (this.testState.resources.minerals < 0) {
        return false;
      }
      if (this.testState.resources.gas < 0) {
        return false;
      }
      if (this.testState.supply.inUse > this.testState.supply.cap) {
        return false;
      }
      return true;
    };

    GameCmdInterpreter.prototype._applyRuleForAction = function(gameState, rules, verb, verbObject) {
      return rules[this.verbToRule[verb]](gameState, verbObject);
    };

    GameCmdInterpreter.prototype._executeAction = function(actor, verb, verbObject) {
      return this._actions[verb](actor, verbObject);
    };

    GameCmdInterpreter.prototype._actions = {
      train: function(actor, verbObject) {
        return actor.say(SCe.Msg.trainUnit, verbObject);
      }
    };

    return GameCmdInterpreter;

  })();

  SCSim.GameCmd = (function() {

    function GameCmd(subject) {
      this.article = "any";
      this.subject = subject;
      this.verb;
      this.verbObject;
      this.and = this;
    }

    GameCmd.select = function(subject) {
      return new this(subject);
    };

    GameCmd.prototype.train = function(name) {
      var _ref2;
      _ref2 = ["train", name], this.verb = _ref2[0], this.verbObject = _ref2[1];
      return this;
    };

    return GameCmd;

  })();

}).call(this);
