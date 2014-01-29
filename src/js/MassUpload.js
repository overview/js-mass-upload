var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

define(['backbone', 'underscore', 'MassUpload/UploadCollection', 'MassUpload/FileLister', 'MassUpload/FileUploader', 'MassUpload/FileDeleter', 'MassUpload/State', 'MassUpload/UploadProgress'], function(Backbone, _, UploadCollection, FileLister, FileUploader, FileDeleter, State, UploadProgress) {
  var MassUpload;
  return MassUpload = (function(_super) {
    __extends(MassUpload, _super);

    MassUpload.prototype.defaults = function() {
      return {
        status: 'waiting',
        listFilesProgress: null,
        listFilesError: null,
        uploadProgress: null,
        uploadErrors: []
      };
    };

    function MassUpload(options) {
      this._removedUploads = [];
      MassUpload.__super__.constructor.call(this, {}, options);
    }

    MassUpload.prototype.initialize = function(attributes, options) {
      var resetUploadProgress, _ref,
        _this = this;
      this._options = options;
      this.uploads = (_ref = options != null ? options.uploads : void 0) != null ? _ref : new UploadCollection();
      this._uploadProgress = new UploadProgress({
        uploadCollection: this.uploads
      });
      resetUploadProgress = function() {
        return _this.set({
          uploadProgress: _this._uploadProgress.pick('loaded', 'total')
        });
      };
      this.listenTo(this._uploadProgress, 'change', resetUploadProgress);
      resetUploadProgress();
      this.listenTo(this.uploads, 'add-batch', this._onUploadBatchAdded);
      this.listenTo(this.uploads, 'change', function(upload) {
        return _this._onUploadChanged(upload);
      });
      this.listenTo(this.uploads, 'reset', function() {
        return _this._onUploadsReset();
      });
      return this.prepare();
    };

    MassUpload.prototype.prepare = function() {
      var options, _ref, _ref1, _ref2,
        _this = this;
      options = this._options;
      this.lister = (_ref = options != null ? options.lister : void 0) != null ? _ref : new FileLister(options.doListFiles);
      this.lister.callbacks = {
        onStart: function() {
          return _this._onListerStart();
        },
        onProgress: function(progressEvent) {
          return _this._onListerProgress(progressEvent);
        },
        onSuccess: function(fileInfos) {
          return _this._onListerSuccess(fileInfos);
        },
        onError: function(errorDetail) {
          return _this._onListerError(errorDetail);
        },
        onStop: function() {
          return _this._onListerStop();
        }
      };
      this.uploader = (_ref1 = options != null ? options.uploader : void 0) != null ? _ref1 : new FileUploader(options.doUploadFile);
      this.uploader.callbacks = {
        onStart: function(file) {
          return _this._onUploaderStart(file);
        },
        onStop: function(file) {
          return _this._onUploaderStop(file);
        },
        onSuccess: function(file) {
          return _this._onUploaderSuccess(file);
        },
        onError: function(file, errorDetail) {
          return _this._onUploaderError(file, errorDetail);
        },
        onProgress: function(file, progressEvent) {
          return _this._onUploaderProgress(file, progressEvent);
        }
      };
      this.deleter = (_ref2 = options != null ? options.deleter : void 0) != null ? _ref2 : new FileDeleter(options.doDeleteFile);
      return this.deleter.callbacks = {
        onStart: function(fileInfo) {
          return _this._onDeleterStart(fileInfo);
        },
        onSuccess: function(fileInfo) {
          return _this._onDeleterSuccess(fileInfo);
        },
        onError: function(fileInfo, errorDetail) {
          return _this._onDeleterError(fileInfo, errorDetail);
        },
        onStop: function(fileInfo) {
          return _this._onDeleterStop(fileInfo);
        }
      };
    };

    MassUpload.prototype.fetchFileInfosFromServer = function() {
      return this.lister.run();
    };

    MassUpload.prototype.retryListFiles = function() {
      return this.fetchFileInfosFromServer();
    };

    MassUpload.prototype.retryUpload = function(upload) {
      return upload.set({
        error: null
      });
    };

    MassUpload.prototype.retryAllUploads = function() {
      return this.uploads.each(function(upload) {
        return upload.set({
          error: null
        });
      });
    };

    MassUpload.prototype.addFiles = function(files) {
      var _this = this;
      return this._uploadProgress.inBatch(function() {
        return _this.uploads.addFiles(files);
      });
    };

    MassUpload.prototype.removeUpload = function(upload) {
      return upload.set({
        deleting: true
      });
    };

    MassUpload.prototype.abort = function() {
      var _this = this;
      this.uploads.each(function(upload) {
        return _this.removeUpload(upload);
      });
      this.uploads.reset();
      return this.prepare();
    };

    MassUpload.prototype._onListerStart = function() {
      return this.set({
        status: 'listing-files',
        listFilesError: null
      });
    };

    MassUpload.prototype._onListerProgress = function(progressEvent) {
      return this.set({
        listFilesProgress: progressEvent
      });
    };

    MassUpload.prototype._onListerSuccess = function(fileInfos) {
      this.uploads.addFileInfos(fileInfos);
      return this._tick();
    };

    MassUpload.prototype._onListerError = function(errorDetail) {
      return this.set({
        listFilesError: errorDetail,
        status: 'listing-files-error'
      });
    };

    MassUpload.prototype._onListerStop = function() {};

    MassUpload.prototype._mergeUploadError = function(upload, prevError, curError) {
      var index, newErrors;
      newErrors = this.get('uploadErrors').slice(0);
      index = _.sortedIndex(newErrors, {
        upload: upload
      }, function(x) {
        return x.upload.id;
      });
      if (prevError == null) {
        newErrors.splice(index, 0, {
          upload: upload,
          error: curError
        });
      } else if (curError == null) {
        newErrors.splice(index, 1);
      } else {
        newErrors[index].error = curError;
      }
      return this.set({
        uploadErrors: newErrors
      });
    };

    MassUpload.prototype._onUploadBatchAdded = function(uploads) {
      var error, upload, _i, _len;
      for (_i = 0, _len = uploads.length; _i < _len; _i++) {
        upload = uploads[_i];
        error = upload.get('error');
        if (error != null) {
          this._mergeUploadError(upload, null, error);
        }
      }
      return this._forceBestTick();
    };

    MassUpload.prototype._onUploadChanged = function(upload) {
      var deleting1, deleting2, error1, error2;
      error1 = upload.previousAttributes().error;
      error2 = upload.get('error');
      if (error1 !== error2) {
        this._mergeUploadError(upload, error1, error2);
      }
      deleting1 = upload.previousAttributes().deleting;
      deleting2 = upload.get('deleting');
      if (deleting2 && !deleting1) {
        this._removedUploads.push(upload);
      }
      return this._forceBestTick();
    };

    MassUpload.prototype._onUploadsReset = function() {
      var newErrors;
      newErrors = [];
      this.uploads.each(function(upload) {
        var error;
        if ((error = upload.get('error'))) {
          return newErrors.push({
            upload: upload,
            error: error
          });
        }
      });
      this.set({
        uploadErrors: newErrors
      });
      return this._tick();
    };

    MassUpload.prototype._onUploaderStart = function(file) {
      var upload;
      upload = this.uploads.get(file.name);
      return upload.set({
        uploading: true,
        error: null
      });
    };

    MassUpload.prototype._onUploaderStop = function(file) {
      var upload;
      upload = this.uploads.get(file.name);
      upload.set({
        uploading: false
      });
      return this._tick();
    };

    MassUpload.prototype._onUploaderProgress = function(file, progressEvent) {
      var upload;
      upload = this.uploads.get(file.name);
      return upload.updateWithProgress(progressEvent);
    };

    MassUpload.prototype._onUploaderError = function(file, errorDetail) {
      var upload;
      upload = this.uploads.get(file.name);
      return upload.set({
        error: errorDetail
      });
    };

    MassUpload.prototype._onUploaderSuccess = function(file) {
      var upload;
      upload = this.uploads.get(file.name);
      return upload.updateWithProgress({
        loaded: upload.size(),
        total: upload.size()
      });
    };

    MassUpload.prototype._onDeleterStart = function(fileInfo) {
      return this.set({
        status: 'uploading'
      });
    };

    MassUpload.prototype._onDeleterSuccess = function(fileInfo) {
      var upload;
      upload = this.uploads.get(fileInfo.name);
      return this.uploads.remove(upload);
    };

    MassUpload.prototype._onDeleterError = function(fileInfo, errorDetail) {
      var upload;
      upload = this.uploads.get(fileInfo.name);
      return upload.set({
        error: errorDetail
      });
    };

    MassUpload.prototype._onDeleterStop = function(fileInfo) {
      return this._tick();
    };

    MassUpload.prototype._tick = function() {
      var progress, status, upload;
      upload = this.uploads.next();
      this._currentUpload = upload;
      if (upload != null) {
        if (upload.get('deleting')) {
          this.deleter.run(upload.get('fileInfo'));
        } else {
          this.uploader.run(upload.get('file'));
        }
      }
      status = this.get('uploadErrors').length ? 'uploading-error' : upload != null ? 'uploading' : (progress = this.get('uploadProgress'), progress.loaded === progress.total ? 'waiting' : 'waiting-error');
      return this.set({
        status: status
      });
    };

    MassUpload.prototype._forceBestTick = function() {
      var upload;
      upload = this.uploads.next();
      if (upload !== this._currentUpload) {
        if (this._currentUpload) {
          return this.uploader.abort();
        } else {
          return this._tick();
        }
      }
    };

    return MassUpload;

  })(Backbone.Model);
});
