var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

define(['backbone', './Upload'], function(Backbone, Upload) {
  var UploadCollection, UploadPriorityQueue, _ref;
  UploadPriorityQueue = (function() {
    function UploadPriorityQueue() {
      this.deleting = [];
      this.uploading = [];
      this.unfinished = [];
      this.unstarted = [];
    }

    UploadPriorityQueue.prototype.uploadAttributesToState = function(uploadAttributes) {
      var ret;
      ret = uploadAttributes.error != null ? null : uploadAttributes.deleting ? 'deleting' : uploadAttributes.uploading ? 'uploading' : (uploadAttributes.file != null) && (uploadAttributes.fileInfo != null) && uploadAttributes.fileInfo.loaded < uploadAttributes.fileInfo.total ? 'unfinished' : (uploadAttributes.file != null) && (uploadAttributes.fileInfo == null) ? 'unstarted' : null;
      return ret;
    };

    UploadPriorityQueue.prototype.add = function(upload) {
      var state;
      state = this.uploadAttributesToState(upload.attributes);
      if (state != null) {
        return this[state].push(upload);
      }
    };

    UploadPriorityQueue.prototype._removeUploadFromArray = function(upload, array) {
      var idx;
      idx = array.indexOf(upload);
      if (idx >= 0) {
        return array.splice(idx, 1);
      }
    };

    UploadPriorityQueue.prototype.remove = function(upload) {
      var state;
      state = this.uploadAttributesToState(upload.attributes);
      if (state != null) {
        return this._removeUploadFromArray(upload.attributes, this[state]);
      }
    };

    UploadPriorityQueue.prototype.change = function(upload) {
      var newState, prevState;
      prevState = this.uploadAttributesToState(upload.previousAttributes());
      newState = this.uploadAttributesToState(upload.attributes);
      if (prevState !== newState) {
        if (prevState != null) {
          this._removeUploadFromArray(upload, this[prevState]);
        }
        if (newState != null) {
          return this[newState].push(upload);
        }
      }
    };

    UploadPriorityQueue.prototype.reset = function(collection) {
      return collection.each(this.add, this);
    };

    UploadPriorityQueue.prototype.next = function() {
      var _ref, _ref1, _ref2, _ref3;
      return (_ref = (_ref1 = (_ref2 = (_ref3 = this.deleting[0]) != null ? _ref3 : this.uploading[0]) != null ? _ref2 : this.unfinished[0]) != null ? _ref1 : this.unstarted[0]) != null ? _ref : null;
    };

    return UploadPriorityQueue;

  })();
  return UploadCollection = (function(_super) {
    __extends(UploadCollection, _super);

    function UploadCollection() {
      _ref = UploadCollection.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    UploadCollection.prototype.model = Upload;

    UploadCollection.prototype.initialize = function() {
      var event, _i, _len, _ref1;
      this._priorityQueue = new UploadPriorityQueue();
      _ref1 = ['change', 'add', 'remove', 'reset'];
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        event = _ref1[_i];
        this.on(event, this._priorityQueue[event], this._priorityQueue);
      }
      return this._priorityQueue.reset(this);
    };

    UploadCollection.prototype.addFiles = function(files) {
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
    };

    UploadCollection.prototype.addFileInfos = function(fileInfos) {
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
    };

    UploadCollection.prototype.next = function() {
      return this._priorityQueue.next();
    };

    UploadCollection.prototype._addWithMerge = function(uploads) {
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
      if (toAdd.length) {
        this.add(toAdd);
        return this.trigger('add-batch', toAdd);
      }
    };

    return UploadCollection;

  })(Backbone.Collection);
});
