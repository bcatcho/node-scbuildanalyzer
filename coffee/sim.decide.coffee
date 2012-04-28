root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim
_ = root._ #require underscore


class SCSim.Hud
  constructor: (emitter) ->
    @minerals = 0
    @gas = 0
    @supply = 0
    @supplyCap = 0
    @production = {}
    @alerts = [] # crono ready, etc
    @economy = {} # state of crono
    @units = {} # my units (Maybe?)
    @buildings = {} # my buildings (Maybe ?)
    @events = {}
    @emitter = emitter
    @setupEvents()

  exampleProduction: ->
    thing: "name"
    timeLeft: 0 #secs
    alertWhenDone: "name is done"

  addEvent: (eventName, filter, callBack) ->
    @emitter.observe eventName, (eventObj) -> callBack(filter(eventObj))

  setupEvents:  ->
    @addEvent "depositMinerals",
      (e) -> e.args[0],
      (minAmt) => @minerals += minAmt

    @addEvent "trainUnitComplete",
      (e) -> e.args[0],
      (unitName) =>
        u = SCSim.data.units[unitName]
        @supply += u.supply

    @addEvent "purchase",
      (e) -> e.args[0],
      (unitName) =>
        u = SCSim.data[unitName]
        @minerals -= u.min
        @gas -= u.gas


class SCSim.Smarts
  constructor: ->

class SCSim.SimRun
  constructor: (smarts) ->
    @smarts = smarts
    @emitter = new SCSim.EventEmitter
    @hud = new SCSim.Hud @emitter
    # what about configs?
    @sim = new SCSim.Simulation @emitter
    
  update: ->
    #commands = @smarts.decide @hud
    @sim.update()

  start: ->
    @sim.say "start"
