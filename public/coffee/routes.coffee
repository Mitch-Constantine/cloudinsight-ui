@app.config ($routeProvider)->
	$routeProvider
		.when('/topologies', {templateUrl: 'partials/topologies/index.html', controller: TopologyGridController})
		.otherwise({templateUrl: 'partials/workInProgress.html'})
