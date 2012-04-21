root = exports ? this
SCSim = root.SCSim

runSim = (workerCount, simLength = 600) ->
  simTickLength = simLength / SCSim.config.secsPerTick
  tickToDate = (t) -> new Date(t * 1000)

  sim = new SCSim.EconSim
  sim.logger.fwatchFor 'mineralsCollected',
     (e) -> [e.eventTime.sec, e.args[0]/(e.eventTime.sec/60)]
     
  sim.logger.fwatchFor 'doneBuildUnit',
     (e) -> (tickToDate e.eventTime.sec)

  base = sim.createActor SCSim.SimBase
  sim.say 'start'
  base.say('buildUnit', 'probe') for i in [1..workerCount]
  sim.update() for i in [1..simTickLength]

  results =
     data: []
     markings: []

  dataFirstPass = []
  dataChunkTime = 8 * (2 + 2 + 1.5)

  perChunkToPerMin = (amt) -> amt * (60/dataChunkTime)

  for e in sim.logger.event 'mineralsCollected'
    time = Math.floor(e[0] / dataChunkTime)
    if dataFirstPass[time] is undefined
      dataFirstPass[time] = {time: tickToDate(time * dataChunkTime),  amt: 0}
    dataFirstPass[time].amt += 5


  results.data = ([d.time, perChunkToPerMin(d.amt)] for n, d of dataFirstPass)

  for e in sim.logger.event('doneBuildUnit')
    results.markings.push
      xaxis:
        from: e
        to: e
      color: "#edebfb"

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
  results = runSim workerCount, 2000
  series.push
    data: results.data
    shadowSize: 0
    lines:
      lineWidth: 2
  options.grid.markings = options.grid.markings.concat results.markings
  {series, options}

{series, options} = addSeries series, options, 100
{series, options} = addSeries series, options, 4

$.plot $("#placeholder"), series, options
