function RunSim() {

	function unit(min, gas, supply, buildTime) {
		return {
			cost: cost(min, gas),
			supply: supply,
			buildTime: buildTime,
		};
	}
	function cost(min, gas) {
		return {
			m: min,
			g: gas
		};
	}

	function addWorker(time) {
		state.workers += 1;
		state.nextWorkerBuildTime = time + stats.probe.buildTime;
		state.totalMin -= stats.probe.cost.m;
		state.supply += stats.probe.supply;
	}

	function remainingSupply() {
		return state.supplyCap - state.supply;
	}

	function buildSupply(time) {
		state.buildingSupply = true;
		state.supplyBuildTime = time + stats.pylon.buildTime;
		state.totalMin -= stats.pylon.cost.m;
	}

	function updateBuildSupply(time) {
		if (state.buildingSupply && time >= state.supplyBuildTime) {
			state.buildingSupply = false;
			state.supplyCap += stats.pylon.supply;
		}
	}

	function canAfford(unit) {
		return state.totalMin >= unit.cost.m
	}

	var stats = {
		probe: unit(50, 0, 1, 17),
		pylon: unit(100, 0, 10, 17)
	};

	var state = {
		nextWorkerBuildTime: stats.probe.buildTime,
		workers: 6,
		patches: 8,
		totalMin: 0,
		supply: 6,
		supplyCap: 10,
		supplyBuildTime: 0,
		buildingSupply: false
	}

	var data = [];
	var markings = [];

	data.push([0, 0]);
	data.push([0, 0]);
	for (var t = 1; t < 800; ++t) {
		var currentTime = new Date(t * 1000);
		updateBuildSupply(t);

		if (remainingSupply() < 3 && ! state.buildingSupply && canAfford(stats.pylon)) {
			buildSupply(t);
		}

		if (t >= state.nextWorkerBuildTime && canAfford(stats.probe) && remainingSupply() > 0) {
			// show a bad player. increas the first number to add a chance to miss a probe
			if (Math.floor((Math.random() * 1) + 1) == 1) {
				addWorker(t);
			}
			// add a marker every 28 workers
			if (state.workers % 26 == 0) {
				markings.push({
					xaxis: {
						from: currentTime,
						to: currentTime
					},
					color: '#f4bfbd'
				});
			}
		}

		var twoWorkerRate = Math.min(state.workers, state.patches * 2) * (40 / 60);
		var thirdWorkerRate = 0;
		if (state.workers > state.patches * 2) {
			thirdWorkerRate = Math.min(state.workers - (state.patches * 2), state.patches) * (20 / 60);
		}

		var minPerSec = twoWorkerRate + thirdWorkerRate;
		state.totalMin += minPerSec;

		data[1].push([currentTime, state.totalMin]);
		data[0].push([currentTime, minPerSec * 200]);
	}

	var options = {
		zoom: {
			interactive: false
		},
		pan: {
			interactive: false
		},
		grid: {
			borderWidth: 0,
			markings: markings
		},
		xaxis: {
			mode: 'time',
			timeformat: '%M:%S'
		}
	};

	var series = [{
		data: data[0],
		shadowSize: 0,
		lines: {
			lineWidth: 1,
		}
	},
	{
		data: data[1],
		shadowSize: 0,
		lines: {
			lineWidth: 1,
		}
	},
	];

	$.plot($("#placeholder"), series, options);
}

$(function() {
	RunSim();
})

