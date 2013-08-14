define(function() {
  var humanReadableSize;
  return humanReadableSize = function(size) {
    var s, unit, units, _i, _len;
    units = ['kB', 'MB', 'GB', 'TB'];
    s = "" + size + " B";
    for (_i = 0, _len = units.length; _i < _len; _i++) {
      unit = units[_i];
      size /= 1024;
      if (size <= 512) {
        s = "" + (size.toFixed(1)) + " " + unit;
        break;
      }
    }
    return s;
  };
});
