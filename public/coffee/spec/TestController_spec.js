(function() {

  describe("Test Controller", function() {
    var httpBackend, scope;
    scope = null;
    httpBackend = null;
    beforeEach(inject(function($rootScope, $controller, $httpBackend, $resource) {
      scope = $rootScope.$new();
      httpBackend = $httpBackend;
      httpBackend.when("GET", "/apiproxy/technologies").respond([
        {
          all: [
            {
              name: 'Technology 1'
            }
          ]
        }
      ]);
      return $controller('TestController', {
        $scope: scope,
        $resource: $resource
      });
    }));
    return it("Loads data from $resource", function() {
      return it("should have 3 movies", function() {
        httpBackend.flush();
        return expect(scope.technologies.all[0].name).toBe('Technology 1');
      });
    });
  });

}).call(this);
