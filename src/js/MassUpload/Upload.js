define(['backbone', './FileInfo'], function(Backbone, FileInfo) {
  return Backbone.Model.extend({
    defaults: {
      file: null,
      fileInfo: null,
      error: null,
      uploading: false,
      deleting: false
    },
    updateWithProgress: function(progressEvent) {
      var fileInfo;
      fileInfo = FileInfo.fromFile(this.get('file'));
      fileInfo.loaded = progressEvent.loaded;
      fileInfo.total = progressEvent.total;
      return this.set('fileInfo', fileInfo);
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