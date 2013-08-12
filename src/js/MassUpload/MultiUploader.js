define(['./FileInfo'], function(FileInfo) {
  var Cursor, MultiUploader;
  Cursor = (function() {
    function Cursor(uploads) {
      this.uploads = uploads;
      this.i = -1;
    }

    Cursor.prototype.next = function() {
      var fileInfo, upload;
      while (this.i < this.uploads.length - 1) {
        this.i += 1;
        upload = this.uploads[this.i];
        if (upload.fileInfo == null) {
          return upload;
        }
        fileInfo = upload.fileInfo;
        if (fileInfo.loaded < fileInfo.total) {
          return upload;
        }
      }
      return null;
    };

    return Cursor;

  })();
  return MultiUploader = (function() {
    function MultiUploader(doUpload, callbacks) {
      this.doUpload = doUpload;
      this.callbacks = callbacks;
      this._reset();
    }

    MultiUploader.prototype._reset = function() {
      this._aborting = false;
      this._cursor = null;
      this._errors = null;
      return this._progress = {
        loaded: 0,
        total: 0
      };
    };

    MultiUploader.prototype._refreshProgress = function(uploads) {
      var file, fileInfo, loaded, total, upload, _i, _len;
      total = 0;
      loaded = 0;
      for (_i = 0, _len = uploads.length; _i < _len; _i++) {
        upload = uploads[_i];
        file = upload.file;
        fileInfo = upload.fileInfo;
        if (file != null) {
          total += file.size;
        } else if (fileInfo != null) {
          total += fileInfo.total;
        }
        if (fileInfo != null) {
          loaded += fileInfo.loaded;
        }
      }
      return this._progress = {
        total: total,
        loaded: loaded
      };
    };

    MultiUploader.prototype.run = function(uploads) {
      var _base;
      if (this._cursor != null) {
        throw 'already running';
      }
      this._refreshProgress(uploads);
      if (typeof (_base = this.callbacks).onStart === "function") {
        _base.onStart();
      }
      this._cursor = new Cursor(uploads);
      this._errors = [];
      return this._tick();
    };

    MultiUploader.prototype.abort = function() {
      var _base;
      if (!this._aborting) {
        this._aborting = true;
        if (typeof (_base = this.callbacks).onAbort === "function") {
          _base.onAbort();
        }
        if (typeof this._abortCallback === 'function') {
          return this._abortCallback();
        }
      }
    };

    MultiUploader.prototype._tick = function() {
      var upload;
      if (!this._aborting && ((upload = this._cursor.next()) != null)) {
        return this._startSingleUpload(upload);
      } else {
        return this._finish();
      }
    };

    MultiUploader.prototype._startSingleUpload = function(upload) {
      var _base,
        _this = this;
      this._upload = upload;
      if (typeof (_base = this.callbacks).onSingleStart === "function") {
        _base.onSingleStart(upload);
      }
      return this._abortCallback = this.doUpload(upload.file, (function(progressEvent) {
        return _this._onSingleProgress(upload, progressEvent);
      }), (function() {
        return _this._onSingleSuccess(upload);
      }), (function(errorDetail) {
        return _this._onSingleError(upload, errorDetail);
      }));
    };

    MultiUploader.prototype._onSingleProgress = function(upload, progressEvent) {
      var progress, _base, _base1;
      if (upload !== this._upload) {
        return;
      }
      progress = this._progress;
      if (upload.fileInfo != null) {
        progress.loaded -= upload.fileInfo.loaded;
      }
      progress.loaded += progressEvent.loaded;
      if (typeof (_base = this.callbacks).onSingleProgress === "function") {
        _base.onSingleProgress(upload, progressEvent);
      }
      return typeof (_base1 = this.callbacks).onProgress === "function" ? _base1.onProgress(progress) : void 0;
    };

    MultiUploader.prototype._onSingleSuccess = function(upload) {
      var _base;
      if (upload !== this._upload) {
        return;
      }
      if (typeof (_base = this.callbacks).onSingleSuccess === "function") {
        _base.onSingleSuccess(upload);
      }
      return this._onSingleStop(upload);
    };

    MultiUploader.prototype._onSingleError = function(upload, errorDetail) {
      var _base;
      if (upload !== this._upload) {
        return;
      }
      this._errors.push({
        upload: upload,
        detail: errorDetail
      });
      if (typeof (_base = this.callbacks).onSingleError === "function") {
        _base.onSingleError(upload, errorDetail);
      }
      return this._onSingleStop(upload);
    };

    MultiUploader.prototype._onSingleStop = function(upload) {
      var _base;
      if (typeof (_base = this.callbacks).onSingleStop === "function") {
        _base.onSingleStop(upload);
      }
      return this._tick();
    };

    MultiUploader.prototype._finish = function() {
      var errors, _base, _base1, _base2;
      errors = this._errors;
      this._reset();
      if (errors.length) {
        if (typeof (_base = this.callbacks).onErrors === "function") {
          _base.onErrors(errors);
        }
      } else {
        if (typeof (_base1 = this.callbacks).onSuccess === "function") {
          _base1.onSuccess();
        }
      }
      return typeof (_base2 = this.callbacks).onStop === "function" ? _base2.onStop() : void 0;
    };

    return MultiUploader;

  })();
});
