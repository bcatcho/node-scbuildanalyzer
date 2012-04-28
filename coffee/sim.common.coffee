root = exports ? this

_ = root._ #require underscore
SCSim = root.SCSim ? {}
root.SCSim = SCSim

class SCSim.EventEmitter
  constructor: ->
    @events = {}

  observe: (eventName, callBack) ->
    @events[eventName] ?= []
    @events[eventName].push(callBack)

  fire: (eventName, eventObj) ->
    if @events[eventName] isnt undefined
      callBack(eventObj) for callBack in @events[eventName]


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
    @go defaultStateName

  update: (t) ->
    @currentState?(t)

  go: (sn,a,b,c,d) ->
    @stateName = sn
    @currentState = @states[@stateName].update?.call @, a,b,c,d
    @messages = @states[@stateName].messages
    @states[@stateName].enterState?.call @, a, b, c, d

  say: (msgName, a, b, c, d) ->
    @emitter.fire msgName, {name: msgName, @time, @simId, args: [a, b, c, d]}
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


class SCSim.Actor
  constructor: (behaviors, a, b, c, d) ->
    @behaviors = {}
    @addBehavior(bName, a, b, c, d) for bName in behaviors

  addBehavior: (bName, a, b, c, d) ->
    behavior = new SCSim[bName] a, b, c, d
    behavior.actor = @
    @behaviors[bName] = behavior
    # parse all properties that begin with "pub" or something
    # and place in a common thing?

  instantiate: ->
    for n, behavior of @behaviors
      behavior.simId = @simId
      behavior.emitter = @emitter
      behavior.time = @time
      behavior.sim = @sim
      behavior.instantiate?()

  update: (t) ->
    b.update(t) for n, b of @behaviors

  say: (msgName, a, b, c, d) ->
    @emitter?.fire msgName, {name: msgName, @time, @simId, args: [a, b, c, d]}
    for n, behavior of @behaviors
      behavior.messages[msgName]?.call behavior, a, b, c, d

  get: (name, a, b, c, d) ->
    for n, behavior of @behaviors
      if behavior[name] isnt undefined
        return behavior[name].call behavior, a, b, c, d

    console.warn("failed to get #{prop}")
