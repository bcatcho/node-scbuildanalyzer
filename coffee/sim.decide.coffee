root = exports ? this

_ = root._ #require underscore
SCSim = root.SCSim ? {}
root.SCSim = SCSim


class SCSim.Hud
  constructor: (eventLog) ->
    @minerals = 0
    @gas = 0
    @supply = 0
    @supplyCap = 0
    @production = {}
    @productionPotential = {} # how much could we do next
    @alerts = [] # crono ready, etc
    @economy = {} # state of crono
    @units = {} # my units (Maybe?)
    @buildings = {} # my buildings (Maybe ?)
    @techTree = {} # the tech that has been opened up (Maybe?)
    
    @setupEvents eventLog

  exampleProduction: ->
    thing: "name"
    timeLeft: 0 #secs
    alertWhenDone: "name is done"

  updateWithEventLog: (eventLog) ->
    # roll through logs and fix up all the numbers

  setupEvents: (eventLog) ->
    # set up all the events it needs to be able to update


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
    @eventLog = new SCSim.EventLog
    @hud = new SCSim.Hud @eventLog
    # what about configs?
    @sim = new SCSim.Simulation @eventLog
    
  mainLoop: ->
    @hud.updateWithEventLog @eventLog
    commands = @smarts.decide @hud
    @sim.update(commands)


