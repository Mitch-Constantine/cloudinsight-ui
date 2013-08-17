(function() {

  this.app.config(function($routeProvider) {
    return $routeProvider.when('/topologies', {
      templateUrl: 'partials/topologies/index.html',
      controller: TopologyGridController
    }).otherwise({
      templateUrl: 'partials/workInProgress.html'
    });
  });

}).call(this);
