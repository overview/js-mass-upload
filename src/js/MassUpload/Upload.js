define(['backbone', './FileInfo'], function(Backbone, FileInfo) {
  var Upload;
  return Upload = (function() {
    Upload.prototype = Object.create(Backbone.Events);

    Upload.prototype.defaults = {
      file: null,
      fileInfo: null,
      error: null,
      uploading: false,
      deleting: false
    };

    function Upload(attributes) {
      var _ref, _ref1, _ref2, _ref3;
      this.file = (_ref = attributes.file) != null ? _ref : null;
      this.fileInfo = (_ref1 = attributes.fileInfo) != null ? _ref1 : null;
      this.error = (_ref2 = attributes.error) != null ? _ref2 : null;
      this.uploading = attributes.uploading || false;
      this.deleting = attributes.deleting || false;
      this.id = ((_ref3 = this.fileInfo) != null ? _ref3 : this.file).name;
      this.attributes = this;
    }

    Upload.prototype.get = function(attr) {
      return this[attr];
    };

    Upload.prototype.set = function(attrs) {
      var k, v;
      this._previousAttributes = new Upload(this);
      for (k in attrs) {
        v = attrs[k];
        this[k] = v;
      }
      this.trigger('change', this);
      return this._previousAttributes = null;
    };

    Upload.prototype.previousAttributes = function() {
      return this._previousAttributes;
    };

    Upload.prototype.size = function() {
      var _ref;
      return this._size != null ? this._size : this._size = (_ref = this.file) != null ? _ref.size : void 0;
    };

    Upload.prototype.lastModifiedDate = function() {
      var _ref;
      return this._lastModifiedDate != null ? this._lastModifiedDate : this._lastModifiedDate = (_ref = this.file) != null ? _ref.lastModifiedDate : void 0;
    };

    Upload.prototype.updateWithProgress = function(progressEvent) {
      var fileInfo;
      fileInfo = new FileInfo(this.id, this.lastModifiedDate(), progressEvent.total, progressEvent.loaded);
      return this.set({
        fileInfo: fileInfo
      });
    };

    Upload.prototype.getProgress = function() {
      if ((this.fileInfo != null) && !this.hasConflict()) {
        return {
          loaded: this.fileInfo.loaded,
          total: this.fileInfo.total
        };
      } else if (this.file != null) {
        return {
          loaded: 0,
          total: this.size()
        };
      }
    };

    Upload.prototype.isFullyUploaded = function() {
      return (this.fileInfo != null) && (this.error == null) && !this.uploading && !this.deleting && this.fileInfo.loaded === this.fileInfo.total;
    };

    Upload.prototype.hasConflict = function() {
      return (this.fileInfo != null) && (this.file != null) && (this.fileInfo.name !== this.id || this.fileInfo.total !== this.size() || this.fileInfo.lastModifiedDate.getTime() !== this.lastModifiedDate().getTime());
    };

    return Upload;

  })();
});
