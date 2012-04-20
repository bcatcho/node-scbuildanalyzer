root = exports ? this
SCSim = root.SCSim

runSim = (workerCount, simLength = 600) ->
  tickToDate = (t) -> new Date(t * 1000)

  sim = new SCSim.EconSim
  sim.logger.fwatchFor 'mineralsCollected',
     (e) -> [(tickToDate e.eventTime), e.args[0]/(e.eventTime/60)]
     
  sim.logger.fwatchFor 'doneBuildingWorker',
     (e) -> (tickToDate e.eventTime)

  base = sim.createActor SCSim.SimBase
  sim.say 'start'
  base.say 'buildNewWorker' for i in [1..workerCount]
  sim.update() for i in [0..simLength]

  results =
     data: [[0,0]]
     markings: []
  
  results.data.push(e) for e in sim.logger.event 'mineralsCollected'
  lastWorkerEvent  = _(sim.logger.event('doneBuildingWorker')).last()
  results.markings.push
    xaxis:
      from: lastWorkerEvent
      to: lastWorkerEvent
    color: "#fdbbdb"

  return results


options =
  grid:
    borderWidth: 0
    markings: []
  xaxis:
    mode: "time"
    timeformat: "%M:%S"

series = []

addSeries = (series, options, workerCount) ->
  results = runSim workerCount
  series.push
    data: results.data
    shadowSize: 0
    lines:
      lineWidth: 2
  options.grid.markings = options.grid.markings.concat results.markings
  {series, options}

{series, options} = addSeries series, options, 10
{series, options} = addSeries series, options, 5

$.plot $("#placeholder"), series, options
