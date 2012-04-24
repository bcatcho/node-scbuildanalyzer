root = exports ? this
SCSim = root.SCSim

runSim = (workerCount, simLength = 600) ->
  simTickLength = simLength / SCSim.config.secsPerTick
  tickToDate = (t) -> new Date(t * 1000)

  sim = new SCSim.Simulation
  sim.logger.fwatchFor 'mineralsCollected',
     (e) -> [e.time.sec, e.args[0]/(e.time.sec/60)]
     
  sim.logger.fwatchFor 'doneBuildUnit',
     (e) -> (tickToDate e.time.sec)

  base = sim.makeActor "nexus"
  sim.say 'start'
  base.say('buildUnit', 'probe') for i in [1..workerCount]
  sim.update() for i in [1..simTickLength]

  results =
     data: []
     markings: []

  dataFirstPass = []
  dataChunkTime = 4 * (2 + 2 + 1.57) # TODO make config setting, this just happens to look cool

  perChunkToPerMin = (amt) -> amt * (60/dataChunkTime)

  for e in sim.logger.event 'mineralsCollected'
    time = Math.floor(e[0] / dataChunkTime)
    if dataFirstPass[time] is undefined
      dataFirstPass[time] = {time: tickToDate(time * dataChunkTime),  amt: 0}
    dataFirstPass[time].amt += 5

  results.data = ([d.time, perChunkToPerMin(d.amt)] for n, d of dataFirstPass)

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
  results = runSim workerCount, 800
  series.push
    data: results.data
    shadowSize: 0
    lines:
      lineWidth: 2
  options.grid.markings = options.grid.markings.concat results.markings
  {series, options}

{series, options} = addSeries series, options, 14
{series, options} = addSeries series, options, 4

$.plot $("#placeholder"), series, options
