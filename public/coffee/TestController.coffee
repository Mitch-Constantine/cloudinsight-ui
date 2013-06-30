angular.module('cloudInsightUI', ['ngResource']);

window.TestController = ($scope, $resource)->
	topologies = $resource('/apiproxy/topologies')
	$scope.topologies = topologies.get()
