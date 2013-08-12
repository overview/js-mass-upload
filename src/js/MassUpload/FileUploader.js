define(['./FileInfo'], function(FileInfo) {
  var FileUploader;
  return FileUploader = (function() {
    function FileUploader(doUpload, callbacks) {
      this.doUpload = doUpload;
      this.callbacks = callbacks;
      this._file = null;
      this._abortCallback = null;
      this._aborting = false;
    }

    FileUploader.prototype.run = function(file) {
      var _base,
        _this = this;
      if (this._file != null) {
        throw 'already running';
      }
      this._file = file;
      if (typeof (_base = this.callbacks).onStart === "function") {
        _base.onStart(this._file);
      }
      return this._abortCallback = this.doUpload(file, (function(progressEvent) {
        return _this._onProgress(file, progressEvent);
      }), (function() {
        return _this._onSuccess(file);
      }), (function(errorDetail) {
        return _this._onError(file, errorDetail);
      }));
    };

    FileUploader.prototype.abort = function() {
      if (this._file && !this._aborting) {
        this._aborting = true;
        if (typeof this._abortCallback === 'function') {
          return this._abortCallback();
        }
      }
    };

    FileUploader.prototype._onProgress = function(file, progressEvent) {
      var _base;
      return typeof (_base = this.callbacks).onProgress === "function" ? _base.onProgress(file, progressEvent) : void 0;
    };

    FileUploader.prototype._onSuccess = function(file) {
      var _base;
      if (typeof (_base = this.callbacks).onSuccess === "function") {
        _base.onSuccess(file);
      }
      return this._onStop(file);
    };

    FileUploader.prototype._onError = function(file, errorDetail) {
      var _base;
      if (typeof (_base = this.callbacks).onError === "function") {
        _base.onError(file, errorDetail);
      }
      return this._onStop(file);
    };

    FileUploader.prototype._onStop = function(file) {
      var _base;
      this._file = null;
      this._abortCallback = null;
      this._aborting = false;
      return typeof (_base = this.callbacks).onStop === "function" ? _base.onStop(file) : void 0;
    };

    return FileUploader;

  })();
});
