root = exports ? this
_ = require 'underscore'

_.mixin rot: (arr, num=1) -> @rest(arr, num).concat @first(arr, num)

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

   watchFor: (eventNames) ->
      for e in eventNames
         @eventsToCollect[e] = true
         @events[e] = []

   log: (eventName, args...) ->
      @events[eventName].push(args) if @eventsToCollect[eventName]

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
       @currentState = @["state_#{@stateName}"] a,b,c,d
       @currentTransitions = @["state_#{@stateName}"].messages
       @["state_#{@stateName}"].enterState?.call @, a, b, c, d
   
   say: (msgName, a, b, c, d) ->
       @logger?.log msgName, @time.tick, a, b, c, d
       @currentTransitions[msgName]?.call @, a, b, c, d

   update: (t) ->
       @currentState(t)

   @state: (fn) ->
       parts = for n,v of fn when n isnt 'messages'
          v.messages = fn.messages
          v.enterState = fn.enterState
          @::["state_"+n] = v
   
   isExpired: (t) -> t <= 0

   sayAfter: (timeSpan, a, b, c, d) ->
      (t) -> @say(a,b,c,d) if @isExpired timeSpan--

root.SimSingletons = SimSingletons
root.SimEventLog = SimEventLog
root.SimActor = SimActor
root.SimTimer = SimTimer
