var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

define(['backbone', './FileInfo'], function(Backbone, FileInfo) {
  var Upload, _ref;
  return Upload = (function(_super) {
    __extends(Upload, _super);

    function Upload() {
      _ref = Upload.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Upload.prototype.defaults = {
      file: null,
      fileInfo: null,
      error: null,
      uploading: false,
      deleting: false
    };

    Upload.prototype.initialize = function(attributes) {
      var fileLike, id, _ref1;
      fileLike = (_ref1 = attributes.file) != null ? _ref1 : attributes.fileInfo;
      id = fileLike.name;
      return this.set({
        id: id
      });
    };

    Upload.prototype.updateWithProgress = function(progressEvent) {
      var fileInfo, fstat;
      fstat = this.fstatSync();
      fileInfo = new FileInfo(this.id, fstat.lastModifiedDate, progressEvent.total, progressEvent.loaded);
      return this.set('fileInfo', fileInfo);
    };

    Upload.prototype.getProgress = function() {
      var file, fileInfo;
      if (((fileInfo = this.get('fileInfo')) != null) && !this.hasConflict()) {
        return {
          loaded: fileInfo.loaded,
          total: fileInfo.total
        };
      } else if ((file = this.get('file')) != null) {
        return {
          loaded: 0,
          total: this.fstatSync().size
        };
      }
    };

    Upload.prototype.fstatSync = function() {
      var file;
      file = this.get('file');
      if (file != null) {
        return this._fstat != null ? this._fstat : this._fstat = {
          size: file.size,
          lastModifiedDate: file.lastModifiedDate
        };
      }
    };

    Upload.prototype.isFullyUploaded = function() {
      var error, fileInfo;
      fileInfo = this.get('fileInfo');
      error = this.get('error');
      return !this.get('uploading') && !this.get('deleting') && (this.get('error') == null) && (fileInfo != null) && fileInfo.loaded === fileInfo.total;
    };

    Upload.prototype.hasConflict = function() {
      var file, fileInfo;
      fileInfo = this.get('fileInfo');
      file = this.get('file');
      return (fileInfo != null) && (file != null) && (fileInfo.name !== file.name || fileInfo.lastModifiedDate.getTime() !== this.fstatSync().lastModifiedDate.getTime() || fileInfo.total !== this.fstatSync().size);
    };

    return Upload;

  })(Backbone.Model);
});
