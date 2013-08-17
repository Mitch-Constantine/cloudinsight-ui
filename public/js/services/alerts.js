(function() {

  app.factory('manageAlerts', function() {
    return function(alertsArray) {
      var alertsModule;
      alertsModule = {
        closeAlert: function(index) {
          return this.splice(index, 1);
        },
        error: function(msg) {
          return this.push({
            type: 'error',
            msg: msg
          });
        },
        success: function(msg) {
          return this.push({
            type: 'success',
            msg: msg
          });
        },
        warn: function(msg) {
          return this.push({
            msg: msg
          });
        },
        hide: function(message) {
          var index;
          index = _.indexOf(this, message);
          if (index !== -1) return this.closeAlert(index);
        },
        display: function(message) {
          if (!this.isDisplayed(message)) return this.splice(0, 0, message);
        }
      };
      ({
        isDisplayed: function(message) {
          return _.indexOf(this, message) > 0;
        }
      });
      return _.extend(alertsArray, alertsModule);
    };
  });

}).call(this);
