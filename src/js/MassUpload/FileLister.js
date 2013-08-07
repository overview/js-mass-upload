define(function() {
  var FileLister;
  return FileLister = (function() {
    function FileLister(doListFiles, callbacks) {
      this.doListFiles = doListFiles;
      this.callbacks = callbacks;
      this.running = false;
    }

    FileLister.prototype.run = function() {
      var _base,
        _this = this;
      if (this.running) {
        throw 'already running';
      }
      this.running = true;
      if (typeof (_base = this.callbacks).onStart === "function") {
        _base.onStart();
      }
      return this.doListFiles((function(progressEvent) {
        var _base1;
        return typeof (_base1 = _this.callbacks).onProgress === "function" ? _base1.onProgress(progressEvent) : void 0;
      }), (function(fileInfos) {
        return _this._onSuccess(fileInfos);
      }), (function(errorDetail) {
        return _this._onError(errorDetail);
      }));
    };

    FileLister.prototype._onSuccess = function(fileInfos) {
      var _base;
      if (typeof (_base = this.callbacks).onSuccess === "function") {
        _base.onSuccess(fileInfos);
      }
      return this._onStop();
    };

    FileLister.prototype._onError = function(errorDetail) {
      this.callbacks.onError(errorDetail);
      return this._onStop();
    };

    FileLister.prototype._onStop = function() {
      var _base;
      this.running = false;
      return typeof (_base = this.callbacks).onStop === "function" ? _base.onStop() : void 0;
    };

    return FileLister;

  })();
});
