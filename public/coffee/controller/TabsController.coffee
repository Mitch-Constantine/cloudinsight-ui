app.controller 'TabsController', ($scope, $location)->

    $scope.navigate = (path)->$location.path(path).replace()