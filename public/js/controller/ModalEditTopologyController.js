(function() {

  app.controller('ModalEditTopologyController', function($scope, $window, topologies, formatXml, manageAlerts) {
    $scope.alerts = [];
    manageAlerts($scope.main_alerts);
    $scope.close = function() {
      return $window.location.reload();
    };
    $scope.save = function() {
      return topologies.save($scope.topologyToEdit, $scope.originalTopology, function() {
        return $scope.close();
      }, function(response) {
        var _ref;
        return $scope.alerts.error((response != null ? (_ref = response.data) != null ? _ref.error_message : void 0 : void 0) || "Operation failed - no error message available");
      });
    };
    $scope.$watch('topologyToEdit', function() {
      if ($scope.topologyToEdit) {
        $scope.topologyToEdit.pattern = formatXml($scope.topologyToEdit.pattern);
        if ($scope.aceEditor) {
          return $scope.aceEditor.setReadOnly(!topologyToEdit.isNew);
        }
      }
    });
    return $scope.uploadComplete = function(response, isComplete) {
      if (!isComplete) {
        $scope.alerts.warn('Upload started');
        return;
      }
      if (response.id) {
        return $scope.alerts.success("File was successfully uploaded");
      } else {
        return $scope.alerts.error((response != null ? response.error_message : void 0) || "Upload failed - no error message available");
      }
    };
  });

}).call(this);
