class SimActor
   constructor: ->
      @events = {}
      @currentState
      @currentTransitions

   switchStateTo: (sn,a,b,c,d,e,f) ->
      @stateName = sn
      @currentState = @["state_"+sn] a,b,c,d,e,f
      @currentTransitions = @["state_"+sn].messages

   say: (msgName, arg1, arg2, arg3, arg4) ->
      @currentTransitions[msgName]?.call @, arg1, arg2, arg3, arg4

   @state: (fn) ->
      parts = for n,v of fn when n isnt 'messages'
         v.messages = fn.messages
         @::["state_"+n] = v


class Worker extends SimActor
   constructor: ->
      @t_toBase = 10
      @t_toPatch = 10
      @t_mine = 5
      @collectAmt = 5
      @switchStateTo 'atBase' 

   update: (t) ->
      @currentState(t)

   # we could add transitions to each state
   @state
      atBase: -> (t) =>
      messages:
         arriveAtMineralPatch: (minPatch) ->
            @switchStateTo 'mining', minPatch

   # example of holding state
   @state 
      mining: (minPatch, secondsLeft = 10) -> (t) =>
         secondsLeft--
         if secondsLeft is 0
            @say 'doneMining'
      messages:
         doneMining: ->
            @switchStateTo 'atBase', 4

w = new Worker
w.say 'arriveAtMineralPatch', 4
w.update(i) for i in [0..10]
