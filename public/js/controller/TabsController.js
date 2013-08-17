(function() {

  app.controller('TabsController', function($scope, $location) {
    return $scope.navigate = function(path) {
      return $location.path(path).replace();
    };
  });

}).call(this);
