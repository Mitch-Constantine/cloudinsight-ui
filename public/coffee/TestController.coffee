angular.module('cloudInsightUI', ['ngResource']);

window.TestController = ($scope, $resource, $timeout)->

	Topologies = $resource('/apiproxy/topologies')
	refreshTopology = ()-> Topologies.get( {}, success, failure ) 

	success =  (data)->
		$scope.topologies = data
		$scope.failed = false
		reschedule()

	failure = ()->
		$scope.failed = true
		reschedule()

	reschedule = ()->$timeout(refreshTopology, 3000)
	refreshTopology()