define(['backbone', 'underscore', 'MassUpload/UploadCollection', 'MassUpload/FileLister', 'MassUpload/FileUploader', 'MassUpload/FileDeleter', 'MassUpload/State', 'MassUpload/UploadProgress'], function(Backbone, _, UploadCollection, FileLister, FileUploader, FileDeleter, State, UploadProgress) {
  return Backbone.Model.extend({
    defaults: function() {
      return {
        status: 'waiting',
        listFilesProgress: null,
        listFilesError: null,
        uploadProgress: null,
        uploadErrors: []
      };
    },
    constructor: function(options) {
      this._removedUploads = [];
      return Backbone.Model.call(this, {}, options);
    },
    initialize: function(attributes, options) {
      var _ref,
        _this = this;
      this._options = options;
      this.uploads = (_ref = options != null ? options.uploads : void 0) != null ? _ref : new UploadCollection();
      this.listenTo(this.uploads, 'add change:file change:error', function(upload) {
        return _this._onUploadAdded(upload);
      });
      this.listenTo(this.uploads, 'change:deleting', function(upload) {
        return _this._onUploadDeleted(upload);
      });
      this.listenTo(this.uploads, 'remove', function(upload) {
        return _this._onUploadRemoved(upload);
      });
      this.listenTo(this.uploads, 'reset', function() {
        return _this._onUploadsReset();
      });
      return this.prepare();
    },
    prepare: function() {
      var options, resetUploadProgress, _ref, _ref1, _ref2,
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
      this.deleter.callbacks = {
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
      this._uploadProgress = new UploadProgress({
        collection: this.uploads
      });
      resetUploadProgress = function() {
        return _this.set({
          uploadProgress: _this._uploadProgress.pick('loaded', 'total')
        });
      };
      this.listenTo(this._uploadProgress, 'change', resetUploadProgress);
      return resetUploadProgress();
    },
    fetchFileInfosFromServer: function() {
      return this.lister.run();
    },
    retryListFiles: function() {
      return this.fetchFileInfosFromServer();
    },
    retryUpload: function(upload) {
      return upload.set('error', null);
    },
    retryAllUploads: function() {
      return this.uploads.each(function(upload) {
        return upload.set('error', null);
      });
    },
    addFiles: function(files) {
      var _this = this;
      return this._uploadProgress.inBatch(function() {
        return _this.uploads.addFiles(files);
      });
    },
    removeUpload: function(upload) {
      return upload.set('deleting', true);
    },
    abort: function() {
      var _this = this;
      this.uploads.each(function(upload) {
        return _this.removeUpload(upload);
      });
      this.uploads.reset();
      return this.prepare();
    },
    _onListerStart: function() {
      this.set('status', 'listing-files');
      return this.set('listFilesError', null);
    },
    _onListerProgress: function(progressEvent) {
      return this.set('listFilesProgress', progressEvent);
    },
    _onListerSuccess: function(fileInfos) {
      this.uploads.addFileInfos(fileInfos);
      return this._tick();
    },
    _onListerError: function(errorDetail) {
      this.set('listFilesError', errorDetail);
      return this.set('status', 'listing-files-error');
    },
    _onListerStop: function() {},
    _onUploadAdded: function(upload) {
      var error1, error2, index, newErrors;
      error1 = upload.previous('error');
      error2 = upload.get('error');
      if (error1 !== error2) {
        newErrors = this.get('uploadErrors').slice(0);
        index = _.sortedIndex(newErrors, {
          upload: upload
        }, function(x) {
          return x.upload.id;
        });
        if (!error1) {
          newErrors.splice(index, 0, {
            upload: upload,
            error: error2
          });
        } else if (!error2) {
          newErrors.splice(index, 1);
        } else {
          newErrors[index].error = error2;
        }
        this.set('uploadErrors', newErrors);
      }
      return this._forceBestTick();
    },
    _onUploadRemoved: function(upload) {},
    _onUploadDeleted: function(upload) {
      this._removedUploads.push(upload);
      return this._forceBestTick();
    },
    _onUploadsReset: function() {
      var newErrors, progress;
      newErrors = [];
      progress = {
        loaded: 0,
        total: 0
      };
      this.uploads.each(function(upload) {
        var error, uploadProgress;
        if ((error = upload.get('error'))) {
          newErrors.push({
            upload: upload,
            error: error
          });
        }
        uploadProgress = upload.getProgress();
        progress.loaded += uploadProgress.loaded;
        return progress.total += uploadProgress.total;
      });
      this.set({
        uploadErrors: newErrors,
        uploadProgress: progress
      });
      return this._tick();
    },
    _onUploaderStart: function(file) {
      var upload;
      upload = this.uploads.get(file.name);
      return upload.set({
        uploading: true,
        error: null
      });
    },
    _onUploaderStop: function(file) {
      var upload;
      upload = this.uploads.get(file.name);
      upload.set('uploading', false);
      return this._tick();
    },
    _onUploaderProgress: function(file, progressEvent) {
      var upload;
      upload = this.uploads.get(file.name);
      return upload.updateWithProgress(progressEvent);
    },
    _onUploaderError: function(file, errorDetail) {
      var upload;
      upload = this.uploads.get(file.name);
      return upload.set('error', errorDetail);
    },
    _onUploaderSuccess: function(file) {
      var upload;
      upload = this.uploads.get(file.name);
      return upload.updateWithProgress({
        loaded: upload.fstatSync().size,
        total: upload.fstatSync().size
      });
    },
    _onDeleterStart: function(fileInfo) {
      return this.set('status', 'uploading');
    },
    _onDeleterSuccess: function(fileInfo) {
      var upload;
      upload = this.uploads.get(fileInfo.name);
      return this.uploads.remove(upload);
    },
    _onDeleterError: function(fileInfo, errorDetail) {
      var upload;
      upload = this.uploads.get(fileInfo.name);
      return upload.set('error', errorDetail);
    },
    _onDeleterStop: function(fileInfo) {
      return this._tick();
    },
    _tick: function() {
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
      return this.set('status', status);
    },
    _forceBestTick: function() {
      var upload;
      upload = this.uploads.next();
      if (upload !== this._currentUpload) {
        if (this._currentUpload) {
          return this.uploader.abort();
        } else {
          return this._tick();
        }
      }
    }
  });
});
