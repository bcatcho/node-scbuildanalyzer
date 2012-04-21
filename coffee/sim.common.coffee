root = exports ? this

_ = root._ #require underscore
SCSim = root.SCSim ? {}
root.SCSim = SCSim

SCSim.SimEventLog = class SimEventLog
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
    formatter = @eventsToCollect[e.eventName]
    @events[e.eventName].push(formatter(e)) if formatter

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


SCSim.SimTimer = class SimTimer
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

SCSim.SimActor = class SimActor
  constructor: (defaultStateName = "default") ->
    @currentState
    @currentTransitions
    @switchStateTo defaultStateName

  switchStateTo: (sn,a,b,c,d) ->
    @stateName = sn
    @currentState = @["state_#{@stateName}"].update.call @, a,b,c,d
    @currentTransitions = @["state_#{@stateName}"].messages
    @["state_#{@stateName}"].enterState?.call @, a, b, c, d

  say: (msgName, a, b, c, d) ->
    @logger?.log
      eventName: msgName
      eventTime: @time
      simId: @simId
      args: [a, b, c, d]
    @currentTransitions[msgName]?.call @, a, b, c, d

  update: (t) ->
    @currentState(t)

  @state: (args...) ->
    @::["state_#{args[0]}"] = args[1]

  @defaultState: (obj) ->
    @::["state_default"] = obj

  isExpired: (t) -> t <= 0

  sayAfter: (timeSpan, a, b, c, d) ->
    endTime = @time.sec + timeSpan
    (t) -> @say(a,b,c,d) if @isExpired endTime-@time.sec

  # convienience method for states with no update loop
  @noopUpdate: -> ->
