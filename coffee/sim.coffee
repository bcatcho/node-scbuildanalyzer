root = exports ? this

SCSim = root.SCSim


runSim = (harvesterCount, simLength = 600, smarts) ->
  # helper methods
  simTickLength = simLength / SCSim.config.secsPerTick
  tickToDate = (t) -> new Date(t * 1000)

  # a bucket to collect data
  logs =
    mineralsCollected: []

  simRun = new SCSim.SimRun SCSim.data, smarts
  sim = simRun.sim
  simRun.emitter.observe 'depositMinerals',
     (e) => logs.mineralsCollected.push [e.time.sec, e.args[0]/(e.time.sec/60)]

  # run the simulation
  simRun.start()
  simRun.update() for i in [1..simTickLength]

  # testing grounds
  console.log sim.makeActor("pylon")

  # process the logs
  results =
    data: []
    markings: []

  # TODO make config setting, this just happens to look cool
  dataChunkTime = (25)

  dataFirstPass = []
  for e in logs.mineralsCollected
    time = Math.floor(e[0] / dataChunkTime)
    if dataFirstPass[time] is undefined
      dataFirstPass[time] = {time: tickToDate(time * dataChunkTime),  amt: 0}
    dataFirstPass[time].amt += 5

  perChunkToPerMin = (amt) -> amt * (60/dataChunkTime)
  results.data = ([d.time, perChunkToPerMin(d.amt)] for n, d of dataFirstPass)
  return results


makeSmarts = (harvesterCount) ->
  smarts = new SCSim.BuildOrder
  helper = new SCSim.BuildHelper
  helper.trainProbesConstantly smarts, harvesterCount
  smarts

addSeries = (series, options, harvesterCount) ->
  results = runSim harvesterCount, 600, makeSmarts(harvesterCount)
  series.push
    data: results.data
    shadowSize: 0
    lines:
      lineWidth: 2
  options.grid.markings = options.grid.markings.concat results.markings
  {series, options}


options =
  grid:
    borderWidth: 0
    markings: []
  xaxis:
    mode: "time"
    timeformat: "%M:%S"


series = []
{series, options} = addSeries series, options, 14
$.plot $("#placeholder"), series, options
