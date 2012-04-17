root = exports ? this
_ = require 'underscore'

_.mixin
  rot: (arr, num=1) ->
    @rest(arr, num).concat @first(arr, num)

  containsInstanceOf: (collection, theType) ->
    if _(collection).isObject() then collection = _(collection).values()
    _(collection).any (i) -> i instanceof(theType)

class SimSingletons
  @dependency = {}
  @register: (proto, instance) ->
    @dependency[proto.name] = instance ? new proto
    @dependency[proto.name]
  @get: (proto) ->
    if @dependency[proto.name] is undefined
      console.error("dependency not found: #{proto.name}")
    @dependency[proto.name]


class SimEventLog
  constructor: ->
    @events = {}
    @eventsToCollect = {}

  event: (eventName, filter) ->
    # TODO impliment filter
    @events[eventName] ? []

  watchFor: (eventNames) ->
    for e in eventNames
      @eventsToCollect[e] = (args) -> args
      @events[e] = []

  fwatchFor: (event, formatter) ->
    @eventsToCollect[event] = formatter ? (args) -> args
    @events[event] ?= []

  log: (eventName, args...) ->
    formatter = @eventsToCollect[eventName]
    @events[eventName].push(formatter(args)) if formatter

  clear: ->
    @events = {}
    @watchFor _(@eventsToCollect).keys()


class SimTimer
  constructor: ->
    @tick = 0
    @seconds = 0

  step: (steps = 1) ->
    @tick += steps
    @seconds += steps

  reset: ->
    @tick = 0
    @seconds = 0

class SimActor
  constructor: (defaultStateName = "default") ->
    @currentState
    @logger = SimSingletons.get SimEventLog
    @time = SimSingletons.get SimTimer
    @currentTransitions
    @switchStateTo defaultStateName

  switchStateTo: (sn,a,b,c,d) ->
    @stateName = sn
    @currentState = @["state_#{@stateName}"].update.call @, a,b,c,d
    @currentTransitions = @["state_#{@stateName}"].messages
    @["state_#{@stateName}"].enterState?.call @, a, b, c, d

  say: (msgName, a, b, c, d) ->
    @logger?.log msgName, @time.tick, a, b, c, d
    @currentTransitions[msgName]?.call @, a, b, c, d

  update: (t) ->
    @currentState(t)

  @state: (args...) ->
    @::["state_#{args[0]}"] = args[1]

  @defaultState: (obj) ->
    @::["state_default"] = obj

  isExpired: (t) -> t <= 0

  sayAfter: (timeSpan, a, b, c, d) ->
    (t) -> @say(a,b,c,d) if @isExpired timeSpan--

  # convienience method for states with no update loop
  @noopUpdate: -> ->


root.SimSingletons = SimSingletons
root.SimEventLog = SimEventLog
root.SimActor = SimActor
root.SimTimer = SimTimer
