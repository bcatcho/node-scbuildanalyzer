root = exports ? this

_ = root._ #require underscore
SCSim = root.SCSim ? {}
root.SCSim = SCSim

class SCSim.EventLog
  constructor: ->
    @events = {}
    @eventsToCollect = {}

  defaultFormatter: (e) -> e

  event: (eventName, filter) ->
    # TODO impliment filter
    @events[eventName] ? []

  watchFor: (events) ->
    for e in events
      @eventsToCollect[e] = @defaultFormatter
      @events[e] = []

  fwatchFor: (eventName, formatter) ->
    @eventsToCollect[eventName] = formatter ? @defaultFormatter
    @events[eventName] ?= []

  isTrackingEvent: (eventName) ->
    @eventsToCollect[eventName] isnt undefined

  log: (e) ->
    formatter = @eventsToCollect[e.name]
    @events[e.name].push(formatter(e)) if formatter

  clear: ->
    @events = {}
    @watchFor _(@eventsToCollect).keys()

  eventOccurs: (eventName, timeOut, condition) ->
    # eg. do.Something() until logger.eventOccurs()
    # TODO : condition
    @fwatchFor eventName unless @isTrackingEvent(eventName)
    if @event(eventName).length > 0
      if condition isnt undefined
        condition(@event(eventName)) or timeOut <= 0
      else
        true
    else
      timeOut <= 0


class SCSim.SimTime
  constructor: ->
    @tick = 0
    @sec = 0
    @secPerTick = SCSim.config.secsPerTick

  step: (steps = 1) ->
    @tick += steps
    @sec += steps * @secPerTick

  reset: ->
    @tick = 0
    @sec = 0


class SCSim.Behavior
  constructor: (defaultStateName = "default") ->
    @currentState
    @messages
    @switchStateTo defaultStateName

  update: (t) -> @currentState(t)

  switchStateTo: (sn,a,b,c,d) ->
    @stateName = sn
    @currentState = @states[@stateName].update.call @, a,b,c,d
    @messages = @states[@stateName].messages
    @states[@stateName].enterState?.call @, a, b, c, d

  say: (msgName, a, b, c, d) ->
    @logger?.log {name: msgName, @time, @simId, args: [a, b, c, d]}
    @messages[msgName]?.call @, a, b, c, d

  @state: (name, stateObj) ->
    if not @::states
      @::states = {}
    @::states[name] = stateObj

  @defaultState: (stateObj) ->
    if not @::states
      @::states = {}
    @::states["default"] = stateObj

  isExpired: (t) -> t <= 0

  sayAfter: (timeSpan, a, b, c, d) ->
    endTime = @time.sec + timeSpan
    (t) -> @say(a,b,c,d) if @isExpired endTime-@time.sec

  # convienience method for states with no update loop
  @noopUpdate: -> -> ->


class SCSim.Actor
  constructor: (behaviors, a, b, c, d) ->
    @behaviors = {}
    for bName in behaviors
      behavior = new SCSim[bName] a, b, c, d
      behavior.actor = @
      @behaviors[bName] = behavior

  instantiate: ->
    for n, behavior of @behaviors
      behavior.simId = @simId
      behavior.logger = @logger
      behavior.time = @time
      behavior.sim = @sim
      behavior.instantiate?()

  update: (t) ->
    b.update(t) for n, b of @behaviors

  say: (msgName, a, b, c, d) ->
    @logger?.log {name: msgName, @time, @simId, args: [a, b, c, d]}
    for n, behavior of @behaviors
      behavior.messages[msgName]?.call behavior, a, b, c, d

  get: (name, a, b, c, d) ->
    for n, behavior of @behaviors
      if behavior[name] isnt undefined
        return behavior[name].call behavior, a, b, c, d
    
    console.warn("failed to get #{prop}")
