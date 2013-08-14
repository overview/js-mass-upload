define(['backbone', './FileInfo'], function(Backbone, FileInfo) {
  return Backbone.Model.extend({
    defaults: {
      file: null,
      fileInfo: null,
      error: null,
      uploading: false,
      deleting: false
    },
    initialize: function(attributes) {
      var fileLike, id, _ref;
      fileLike = (_ref = attributes.file) != null ? _ref : attributes.fileInfo;
      id = fileLike.name;
      return this.set({
        id: id
      });
    },
    updateWithProgress: function(progressEvent) {
      var fileInfo;
      fileInfo = FileInfo.fromFile(this.get('file'));
      fileInfo.loaded = progressEvent.loaded;
      fileInfo.total = progressEvent.total;
      return this.set('fileInfo', fileInfo);
    },
    getProgress: function() {
      var file, fileInfo;
      if (((fileInfo = this.get('fileInfo')) != null) && !this.hasConflict()) {
        return {
          loaded: fileInfo.loaded,
          total: fileInfo.total
        };
      } else if ((file = this.get('file')) != null) {
        return {
          loaded: 0,
          total: file.size
        };
      }
    },
    isFullyUploaded: function() {
      var error, fileInfo;
      fileInfo = this.get('fileInfo');
      error = this.get('error');
      return !this.get('uploading') && !this.get('deleting') && (this.get('error') == null) && (fileInfo != null) && fileInfo.loaded === fileInfo.total;
    },
    hasConflict: function() {
      var file, fileInfo;
      fileInfo = this.get('fileInfo');
      file = this.get('file');
      return (fileInfo != null) && (file != null) && (fileInfo.name !== file.name || fileInfo.lastModifiedDate.getTime() !== file.lastModifiedDate.getTime() || fileInfo.total !== file.size);
    }
  });
});
