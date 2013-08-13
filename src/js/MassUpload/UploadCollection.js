define(['backbone', './Upload'], function(Backbone, Upload) {
  return Backbone.Collection.extend({
    model: Upload,
    comparator: 'id',
    addFiles: function(files) {
      var file, uploads;
      uploads = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = files.length; _i < _len; _i++) {
          file = files[_i];
          _results.push(new Upload({
            file: file
          }));
        }
        return _results;
      })();
      return this._addWithMerge(uploads);
    },
    addFileInfos: function(fileInfos) {
      var fileInfo, uploads;
      uploads = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = fileInfos.length; _i < _len; _i++) {
          fileInfo = fileInfos[_i];
          _results.push(new Upload({
            fileInfo: fileInfo
          }));
        }
        return _results;
      })();
      return this._addWithMerge(uploads);
    },
    next: function() {
      var firstDeleting, firstUnfinished, firstUnstarted, firstUploading;
      firstDeleting = null;
      firstUploading = null;
      firstUnfinished = null;
      firstUnstarted = null;
      this.each(function(upload) {
        var file, fileInfo;
        file = upload.get('file');
        fileInfo = upload.get('fileInfo');
        if (upload.get('error') == null) {
          if (upload.get('deleting')) {
            firstDeleting || (firstDeleting = upload);
          }
          if (upload.get('uploading')) {
            firstUploading || (firstUploading = upload);
          }
          if (file && fileInfo && fileInfo.loaded < fileInfo.total) {
            firstUnfinished || (firstUnfinished = upload);
          }
          if (file && !fileInfo) {
            return firstUnstarted || (firstUnstarted = upload);
          }
        }
      });
      return firstDeleting || firstUploading || firstUnfinished || firstUnstarted;
    },
    _addWithMerge: function(uploads) {
      var existingUpload, file, fileInfo, toAdd, upload, _i, _len;
      toAdd = [];
      for (_i = 0, _len = uploads.length; _i < _len; _i++) {
        upload = uploads[_i];
        if ((existingUpload = this.get(upload.id)) != null) {
          file = upload.get('file');
          fileInfo = upload.get('fileInfo');
          if (file != null) {
            existingUpload.set({
              file: file
            });
          }
          if (fileInfo != null) {
            existingUpload.set({
              fileInfo: fileInfo
            });
          }
        } else {
          toAdd.push(upload);
        }
      }
      return this.add(toAdd);
    }
  });
});
