(function() {
  var timeFunctions;

  app.factory('timeFunctions', [
    "$timeout", timeFunctions = function($timeout) {
      var functions, _intervalUID, _intervals;
      _intervals = [];
      _intervalUID = 1;
      functions = {
        setInterval: function(operation, interval, $scope) {
          var intervalOperation, _internalId;
          _internalId = _intervalUID++;
          intervalOperation = function() {
            operation($scope || void 0);
            return _intervals[_internalId] = $timeout(intervalOperation, interval);
          };
          _intervals[_internalId] = $timeout(intervalOperation, interval);
          return _internalId;
        },
        clearInterval: function(id) {
          return $timeout.cancel(_intervals[id]);
        }
      };
      return functions;
    }
  ]);

}).call(this);
