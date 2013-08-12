define(['backbone', './MassUpload/UploadCollection', './MassUpload/FileLister', './MassUpload/MultiUploader', './MassUpload/FileDeleter', './MassUpload/State'], function(Backbone, UploadCollection, FileLister, MultiUploader, FileDeleter, State) {
  return Backbone.Model.extend({
    defaults: function() {
      return {
        status: 'empty',
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
      var _ref, _ref1, _ref2, _ref3,
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
      this.uploader = (_ref2 = options != null ? options.uploader : void 0) != null ? _ref2 : new MultiUploader([], options.doUploadFile);
      this.uploader.callbacks = {
        onStart: function() {
          return _this._onUploaderStart();
        },
        onStop: function() {
          return _this._onUploaderStop();
        },
        onErrors: function() {
          return _this._onUploaderErrors();
        },
        onSuccess: function() {
          return _this._onUploaderSuccess();
        },
        onProgress: function(progressEvent) {
          return _this._onUploaderProgress(progressEvent);
        },
        onStartAbort: function() {
          return _this._onUploaderStartAbort();
        },
        onSingleStart: function(file) {
          return _this._onUploaderSingleStart(file);
        },
        onSingleStop: function(file) {
          return _this._onUploaderSingleStop(file);
        },
        onSingleSuccess: function(file) {
          return _this._onUploaderSingleSuccess(file);
        },
        onSingleError: function(file, errorDetail) {
          return _this._onUploaderSingleError(file, errorDetail);
        },
        onSingleProgress: function(file, progressEvent) {
          return _this._onUploaderSingleProgress(file, progressEvent);
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
      return this.uploads.on('remove', function(upload) {
        return _this._onUploadRemoved(upload);
      });
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
    _onUploaderStart: function() {
      return this.set('status', 'uploading');
    },
    _onUploaderStop: function() {
      return this._tick();
    },
    _onUploaderSingleStart: function(file) {
      var upload;
      upload = this.uploads.get(file.name);
      return upload.set({
        uploading: true,
        error: null
      });
    },
    _onUploaderSingleStop: function(file) {
      var upload;
      upload = this.uploads.get(file.name);
      return upload.set('uploading', false);
    },
    _onUploaderSingleProgress: function(file, progressEvent) {
      var upload;
      upload = this.uploads.get(file.name);
      return upload.updateWithProgress(progressEvent);
    },
    _onUploaderSingleError: function(file, errorDetail) {
      var upload;
      upload = this.uploads.get(file.name);
      return upload.set('error', errorDetail);
    },
    _onUploaderSingleSuccess: function(file) {},
    _onDeleterStart: function(upload) {},
    _onDeleterSuccess: function(upload) {
      return this.uploads.remove(upload);
    },
    _onDeleterError: function(upload, errorDetail) {
      return upload.set('error', errorDetail);
    },
    _onDeleterStop: function(upload) {
      return this._tick();
    },
    _tick: function() {
      var upload;
      if (this._removedUploads.length) {
        upload = this._removedUploads.pop();
        return this.deleter.run(upload);
      } else {
        return this.uploader.run(this.uploads.toJSON());
      }
    }
  });
});
