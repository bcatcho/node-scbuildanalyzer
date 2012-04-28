root = exports ? this

_ = root._ #require underscore
SCSim = root.SCSim ? {}
root.SCSim = SCSim


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

    @addEvent "purchaseUnit",
      (e) -> e.args[0],
      (unitName) =>
        u = SCSim.data.units[unitName]
        @minerals -= u.min
        @gas -= u.gas


class SCSim.Smarts
  constructor: ->
    @strategies = {}
    @path = {} # a linked list of your build order
    # OR:
    @goals = {} # maybe a list of goals that you will need to meet

  decide: (hud) ->
    # for things in hud, apply strats, decide and return oommands
  
  applyStrategy: (inputName, methodThatDecidesWhatToDo) ->
    # define strategies to decide outcomes on certain input/alerts/etc


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


