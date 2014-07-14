define(function() {
  var FileInfo;
  FileInfo = (function() {
    function FileInfo(name, lastModifiedDate, total, loaded) {
      this.name = name;
      this.lastModifiedDate = lastModifiedDate;
      this.total = total;
      this.loaded = loaded;
    }

    return FileInfo;

  })();
  FileInfo.fromJson = function(obj) {
    return new FileInfo(obj.name, new Date(obj.lastModifiedDate), obj.total, obj.loaded);
  };
  FileInfo.fromFile = function(obj) {
    return new FileInfo(obj.webkitRelativePath || obj.name, obj.lastModifiedDate, obj.size, 0);
  };
  return FileInfo;
});
