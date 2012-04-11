class SimActor
  constructor: ->

  $ay: (msgName, args...) ->
    @['msg_'+msgName](args)


class EconSim extends SimActor
  constructor: (baseCount) ->
    @bases = (new Base for i in [1..baseCount])


class Base extends SimActor
  constructor: (workerCount, mineralPatchCount) ->
    @workers = (new Worker for i in [1..workerCount])
    @mins = (new MineralPatch for i in [1..mineralPatchCount])


class MineralPatch extends SimActor
  constructor: (startingAmt) ->
    @amt = startingAmt || 100
    @workers = []

  msg_attachWorker: (worker) ->
    @workers.push worker

  msg_mineralsHarvested: (amtHarvested) ->
    @amt -= amtHarvested


class Worker extends SimActor
  constructor: ->
    @t_toBase = 10
    @t_toPatch = 10
    @t_mine = 5
    @collectAmt = 5
    @state = @state_atBase()

  update: (t) ->
    @state(t)

  state_atBase: (t) ->


#exports
root = exports ? window  
root.Worker = Worker
root.EconSim = EconSim
root.Base = Base
root.MineralPatch = MineralPatch
root.SimActor = SimActor
