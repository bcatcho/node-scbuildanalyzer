
data = []
data.push [0,0]
data.push [0,0]

data[0].push [i, i + Math.sin(i/3.14) * 20] for i in [0..100]
data[1].push [i, i + Math.cos(i/3.14)] for i in [0..100]


markings = []
obj =
  xaxis:
    from: 10
    to: 10
  color: "#f4bfbd"

markings.push obj

series = []
series.push
  data: data[0]
  shadowSize: 0
  lines:
    lineWidth: 1

series.push
  data: data[1]
  shadowSize: 0
  lines:
    lineWidth: 1

options = 
  grid:
    borderWidth: 0 
    markings: markings
  xaxis:
    mode: "time"
    timeformat: "%M:%S"

$.plot $("#placeholder"), series, options
