(function() {

  app.factory('topologies', function($resource, $cookieStore) {
    var Topologies, topologies;
    Topologies = $resource('/apiproxy/topologies');
    return topologies = {
      get: function(success, failure) {
        var processTopologies, setAppUrl, setRowStatus, setStartTime;
        processTopologies = function(data) {
          topologies = data.all;
          setRowStatus(topologies);
          setStartTime(topologies);
          setAppUrl(topologies);
          return success(topologies);
        };
        Topologies.get({}, processTopologies, failure);
        setRowStatus = function(topologies) {
          var topology, _i, _len, _ref, _results;
          _results = [];
          for (_i = 0, _len = topologies.length; _i < _len; _i++) {
            topology = topologies[_i];
            _results.push(topology.status = topology != null ? (_ref = topology.deployment) != null ? _ref.status : void 0 : void 0);
          }
          return _results;
        };
        setStartTime = function(topologies) {
          var cookieKey, currentTime, topology, _i, _len, _ref, _results;
          currentTime = (new XDate()).toString();
          _results = [];
          for (_i = 0, _len = topologies.length; _i < _len; _i++) {
            topology = topologies[_i];
            cookieKey = "startTime_" + topology.id;
            if ((topology != null ? (_ref = topology.deployment) != null ? _ref.status : void 0 : void 0) === 'deploying') {
              if (!$cookieStore.get(cookieKey)) {
                _results.push($cookieStore.put(cookieKey, currentTime));
              } else {
                _results.push(void 0);
              }
            } else {
              _results.push($cookieStore.remove(cookieKey));
            }
          }
          return _results;
        };
        return setAppUrl = function(topologies) {
          var appWithUrl, applications, topology, _i, _len, _ref, _results;
          _results = [];
          for (_i = 0, _len = topologies.length; _i < _len; _i++) {
            topology = topologies[_i];
            applications = topology != null ? (_ref = topology.deployment) != null ? _ref.applications : void 0 : void 0;
            if (applications) {
              appWithUrl = _.find(applications, function(app) {
                return app.url;
              });
              _results.push(topology.appUrl = appWithUrl != null ? appWithUrl.url : void 0);
            } else {
              _results.push(void 0);
            }
          }
          return _results;
        };
      },
      "delete": function(topologies) {
        var Topology, topology, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = topologies.length; _i < _len; _i++) {
          topology = topologies[_i];
          Topology = $resource('/apiproxy/topologies/:id', {
            id: topology.id
          });
          _results.push(Topology["delete"]());
        }
        return _results;
      },
      performMassOperation: function(topologies, operation, onStart, onFailure) {
        var Topology, topology, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = topologies.length; _i < _len; _i++) {
          topology = topologies[_i];
          Topology = $resource('/apiproxy/topologies/:id?operation=:operation', {
            id: topology.id,
            operation: operation
          }, {
            put: {
              method: "PUT"
            }
          });
          onStart(topology);
          _results.push(Topology.put(null, (function() {}), onFailure));
        }
        return _results;
      },
      save: function(topology, originalTopology, success, failure) {
        var createNew, update;
        update = function() {
          var Topology, operations;
          operations = [];
          if (originalTopology.name !== topologyToEdit.name) {
            Topology = $resource('/apiproxy/topologies/:id?operation=:operation&name=:name', {
              id: topologyToEdit.id,
              operation: "rename",
              name: $scope.topologyToEdit.name
            }, {
              put: {
                method: "PUT"
              }
            });
            operations.push(Topology.put(null).$promise);
          }
          if (originalTopology.description !== topologyToEdit.description) {
            Topology = $resource('/apiproxy/topologies/:id?operation=:operation&description=:description', {
              id: topologyToEdit.id,
              operation: "update_description",
              description: topologyToEdit.description
            }, {
              put: {
                method: "PUT"
              }
            });
            operations.push(Topology.put(null).$promise);
            return $q.all(operations).then(success, failure);
          }
        };
        createNew = function() {
          var _ref, _ref2;
          Topologies = $resource('/apiproxy/topologies?name=:name&description=:description', {
            name: (_ref = topologyToEdit.name) != null ? _ref : "",
            description: (_ref2 = topologyToEdit.description) != null ? _ref2 : ""
          });
          return Topologies.save({
            definition: topologyToEdit.pattern
          }, success, failure);
        };
        if (topology.id) {
          return update();
        } else {
          return createNew();
        }
      }
    };
  });

}).call(this);
