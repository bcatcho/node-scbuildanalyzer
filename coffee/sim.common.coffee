root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim
_ = root._ #require underscore

# common methods
SCSim.GetClass = (obj) -> obj.constructor.name


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
  constructor: ->
    @currentState
    @messages

  instantiate: (defaultStateName = "default") ->
    @go defaultStateName

  update: (t) ->
    @currentState?(t)

  go: (sn,a,b,c,d) ->
    @stateName = sn
    @currentState = @states[@stateName].update?.call @, a,b,c,d
    @messages = @states[@stateName].messages ? {}
    @states[@stateName].enterState?.call @, a, b, c, d

  say: (msgName, a, b, c, d) ->
    @actor.say msgName, a, b, c, d

  get: (msgName, a, b, c, d) ->
    @actor.get msgName, a, b, c, d

  @state: (name, stateObj) ->
    if not @::states
      @::states = {}
    @::states[name] = stateObj

  @defaultState: (stateObj) ->
    if not @::states
      @::states = {}
    @::states["default"] = stateObj

  blockActor: ->
    @actor.startBlockingWithBehavior @

  unblockActor: ->
    @actor.stopBlockingWithBehavior()

  isExpired: (t) -> t <= 0

  sayAfter: (timeSpan, a, b, c, d) ->
    endTime = @time.sec + timeSpan
    (t) -> @say(a,b,c,d) if @isExpired endTime-@time.sec


class SCSim.Actor
  constructor: (behaviors) ->
    @behaviorConfiguration = behaviors
    @behaviors = {}
    @blockingBehavior = undefined

  instantiate: ->
    for b in @behaviorConfiguration
      behavior = new SCSim[b.name]
      behavior.actor = @
      behavior.simId = @simId
      behavior.emitter = @emitter
      behavior.time = @time
      behavior.sim = @sim
      behavior.instantiate?.apply behavior, b.args
      @behaviors[b.name] = behavior

  startBlockingWithBehavior: (behavior) ->
    if @blockingBehavior isnt undefined
      console.error "behavior already set
                      to #{SCSim.GetClass(@blockingBehavior)}"
    @blockingBehavior = behavior

  stopBlockingWithBehavior: ->
    @blockingBehavior = undefined

  update: (t) ->
    if @blockingBehavior isnt undefined
      @blockingBehavior.update(t)
    else
      b.update(t) for n, b of @behaviors

  say: (msgName, a, b, c, d) ->
    @emitter?.fire msgName, {name: msgName, @time, @simId, args: [a, b, c, d]}
    if @blockingBehavior isnt undefined
      @blockingBehavior.messages[msgName]?.call @blockingBehavior, a, b, c, d
    else
      for n, behavior of @behaviors
        behavior.messages[msgName]?.call behavior, a, b, c, d

  get: (name, a, b, c, d) ->
    for n, behavior of @behaviors
      if behavior[name] isnt undefined
        return behavior[name].call behavior, a, b, c, d

    console.warn("failed to get #{prop}")
