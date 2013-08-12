define(['backbone', './MassUpload/UploadCollection', './MassUpload/FileLister', './MassUpload/MultiUploader', './MassUpload/FileDeleter', './MassUpload/State'], function(Backbone, UploadCollection, FileLister, MultiUploader, FileDeleter, State) {
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
        onSingleStart: function(upload) {
          return this._onUploaderSingleStart(upload);
        },
        onSingleStop: function(upload) {
          return this._onUploaderSingleStop(upload);
        },
        onSingleSuccess: function(upload) {
          return this._onUploaderSingleSuccess(upload);
        },
        onSingleError: function(upload, errorDetail) {
          return this._onUploaderSingleError(upload, errorDetail);
        },
        onSingleProgress: function(upload, progressEvent) {
          return this._onUploaderSingleProgress(upload, progressEvent);
        }
      };
      this.deleter = (_ref3 = options != null ? options.deleter : void 0) != null ? _ref3 : new FileDeleter(options.doDeleteFile);
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
    }
  });
});
