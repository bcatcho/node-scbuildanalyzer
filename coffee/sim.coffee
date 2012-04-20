root = exports ? this
SCSim = root.SCSim

runSim = (workerCount) ->
  sim = new SCSim.EconSim
  sim.logger.fwatchFor [
    'mineralsCollected'
    (e) -> [new Date(e.eventTime * 1000), +e.args[0]]
  ]

  base = sim.createActor SCSim.SimBase
  sim.say 'start'
  base.say 'buildNewWorker' for i in [1..workerCount]

  sim.update() for i in [0..400]

  data = []
  data.push(e) for e in sim.logger.event 'mineralsCollected'
  data

series = []
series.push
  data: runSim 10
  shadowSize: 0
  lines:
    lineWidth: 1

series.push
  data: runSim 5
  shadowSize: 0
  lines:
    lineWidth: 1

options =
  grid:
    borderWidth: 0
  xaxis:
    mode: "time"
    timeformat: "%M:%S"

$.plot $("#placeholder"), series, options
