define(['backbone', 'MassUpload/UploadCollection', 'MassUpload/FileLister', 'MassUpload/FileUploader', 'MassUpload/FileDeleter', 'MassUpload/State', 'MassUpload/UploadProgress'], function(Backbone, UploadCollection, FileLister, FileUploader, FileDeleter, State, UploadProgress) {
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
      var resetUploadProgress, uploadProgress, _ref, _ref1, _ref2, _ref3,
        _this = this;
      this.uploads = (_ref = options != null ? options.uploads : void 0) != null ? _ref : new UploadCollection();
      this.lister = (_ref1 = options != null ? options.lister : void 0) != null ? _ref1 : new FileLister(options.doListFiles);
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
      this.uploader = (_ref2 = options != null ? options.uploader : void 0) != null ? _ref2 : new FileUploader(options.doUploadFile);
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
      this.deleter = (_ref3 = options != null ? options.deleter : void 0) != null ? _ref3 : new FileDeleter(options.doDeleteFile);
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
      this.uploads.on('add change:file', function(upload) {
        return _this._onUploadAdded(upload);
      });
      this.uploads.on('change:deleting', function(upload) {
        return _this._onUploadDeleted(upload);
      });
      this.uploads.on('remove', function(upload) {
        return _this._onUploadRemoved(upload);
      });
      uploadProgress = new UploadProgress({
        collection: this.uploads
      });
      resetUploadProgress = function() {
        return _this.set({
          uploadProgress: uploadProgress.pick('loaded', 'total')
        });
      };
      uploadProgress.on('change', resetUploadProgress);
      return resetUploadProgress();
    },
    fetchFileInfosFromServer: function() {
      return this.lister.run();
    },
    retryListFiles: function() {
      return this.fetchFileInfosFromServer();
    },
    addFiles: function(files) {
      return this.uploads.addFiles(files);
    },
    removeUpload: function(upload) {
      return upload.set('deleting', true);
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
      var status;
      status = this.get('status');
      if (status === 'uploading' || status === 'uploading-error') {
        return this.uploader.abort();
      } else {
        return this._tick();
      }
    },
    _onUploadRemoved: function(upload) {
      return this.uploads.remove(upload);
    },
    _onUploadDeleted: function(upload) {
      var status;
      this._removedUploads.push(upload);
      status = this.get('status');
      if (status === 'uploading' || status === 'uploading-error') {
        return this.uploader.abort();
      } else {
        return this._tick();
      }
    },
    _onUploaderStart: function(file) {
      var upload;
      this.set('status', 'uploading');
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
    _onUploaderSuccess: function(file) {},
    _onDeleterStart: function(fileInfo) {
      return this.set('status', 'uploading');
    },
    _onDeleterSuccess: function(fileInfo) {
      return this.uploads.remove(fileInfo);
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
      var upload;
      upload = this.uploads.next();
      if (upload != null) {
        if (upload.get('deleting')) {
          return this.deleter.run(upload.get('fileInfo'));
        } else {
          return this.uploader.run(upload.get('file'));
        }
      } else {
        return this.set('status', 'waiting');
      }
    }
  });
});
