(function() {

  app.factory('config', function($resource) {
    return $resource('/config').get();
  });

}).call(this);
