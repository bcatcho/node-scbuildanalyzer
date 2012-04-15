root = exports ? this
_ = require 'underscore'

_.mixin rot: (arr, num=1) -> @rest(arr, num).concat @first(arr, num)

class SimSingletons
   @dependency = {}

   @register: (proto, instance) ->
      @dependency[proto.name] = instance

   @get: (proto) ->
      if @dependency[proto.name] is undefined
         console.error("dependency not found: #{proto.name}")
      @dependency[proto.name]


class SimEventLog
   constructor: ->
      @events = {}
      @eventsToCollect = {}

   watchFor: (eventNames...) ->
      for e in eventNames
         @eventsToCollect[e] = true
         @events[e] = []

   log: (eventName, args...) ->
      @events[eventName].push(args) if @eventsToCollect[eventName]


class SimActor
   constructor: ->
      @events = {}
      @currentState
      @logger = SimSingletons.get(SimEventLog)
      @currentTransitions

   switchStateTo: (sn,a,b,c,d) ->
       @stateName = sn
       @currentState = @["state_"+sn] a,b,c,d
       @currentTransitions = @["state_"+sn].messages

   say: (msgName, a, b, c, d) ->
       @logger?.log msgName, a, b, c, d
       @currentTransitions[msgName]?.call @, a, b, c, d

   update: (t) ->
       @currentState(t)

   @state: (fn) ->
       parts = for n,v of fn when n isnt 'messages'
          v.messages = fn.messages
          @::["state_"+n] = v
   
   isExpired: (t) -> t <= 0

   sayAfter: (timeSpan, a, b, c, d) ->
      (t) -> @say(a,b,c,d) if @isExpired timeSpan--

root.SimSingletons = SimSingletons
root.SimEventLog = SimEventLog
root.SimActor = SimActor
