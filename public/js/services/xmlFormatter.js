(function() {

  this.app.factory('formatXml', function() {
    return function(xml) {
      var formatted, pad, reg;
      formatted = '';
      xml = xml.replace(/\r\n/g, " ");
      reg = /(>)(\s*)(<)(\/*)/g;
      xml = xml.replace(reg, '$1\r\n$3$4');
      pad = 0;
      jQuery.each(xml.split('\r\n'), function(index, node) {
        var i, indent, padding;
        indent = 0;
        if (node.match(/.+<\/\w[^>]*>$/)) {
          indent = 0;
        } else if (node.match(/^<\/\w/)) {
          if (pad !== 0) pad -= 1;
        } else if (node.match(/^<\w[^>]*[^\/]>.*$/)) {
          indent = 1;
        } else {
          indent = 0;
        }
        padding = '';
        if (pad > 0) {
          for (i = 1; 1 <= pad ? i <= pad : i >= pad; 1 <= pad ? i++ : i--) {
            padding += '    ';
          }
        }
        formatted += padding + node + '\r\n';
        return pad += indent;
      });
      return formatted;
    };
  });

}).call(this);
