define(['backbone', './Upload'], function(Backbone, Upload) {
  var UploadCollection, UploadPriorityQueue;
  UploadPriorityQueue = (function() {
    function UploadPriorityQueue() {
      this._clear();
    }

    UploadPriorityQueue.prototype._clear = function() {
      this.deleting = [];
      this.uploading = [];
      this.unfinished = [];
      return this.unstarted = [];
    };

    UploadPriorityQueue.prototype.uploadAttributesToState = function(uploadAttributes) {
      var ret;
      ret = uploadAttributes.error != null ? null : uploadAttributes.deleting ? 'deleting' : uploadAttributes.uploading ? 'uploading' : (uploadAttributes.file != null) && (uploadAttributes.fileInfo != null) && uploadAttributes.fileInfo.loaded < uploadAttributes.fileInfo.total ? 'unfinished' : (uploadAttributes.file != null) && (uploadAttributes.fileInfo == null) ? 'unstarted' : null;
      return ret;
    };

    UploadPriorityQueue.prototype.addBatch = function(uploads) {
      var state, upload, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = uploads.length; _i < _len; _i++) {
        upload = uploads[_i];
        state = this.uploadAttributesToState(upload.attributes);
        if (state != null) {
          _results.push(this[state].push(upload));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
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

    UploadPriorityQueue.prototype.reset = function(uploads) {
      this._clear();
      return this.addBatch(uploads);
    };

    UploadPriorityQueue.prototype.next = function() {
      var _ref, _ref1, _ref2, _ref3;
      return (_ref = (_ref1 = (_ref2 = (_ref3 = this.deleting[0]) != null ? _ref3 : this.uploading[0]) != null ? _ref2 : this.unfinished[0]) != null ? _ref1 : this.unstarted[0]) != null ? _ref : null;
    };

    return UploadPriorityQueue;

  })();
  return UploadCollection = (function() {
    UploadCollection.prototype = Object.create(Backbone.Events);

    function UploadCollection() {
      this.models = [];
      this._priorityQueue = new UploadPriorityQueue();
      this.reset([]);
    }

    UploadCollection.prototype.each = function(func, context) {
      return this.models.forEach(func, context);
    };

    UploadCollection.prototype._prepareModel = function(upload) {
      if (upload instanceof Upload) {
        return upload;
      } else {
        return new Upload(upload);
      }
    };

    UploadCollection.prototype.reset = function(uploads) {
      var upload, _i, _j, _len, _len1, _ref, _ref1;
      _ref = this.models;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        upload = _ref[_i];
        upload.off('all', this._onUploadEvent, this);
      }
      this.models = (function() {
        var _j, _len1, _results;
        _results = [];
        for (_j = 0, _len1 = uploads.length; _j < _len1; _j++) {
          upload = uploads[_j];
          _results.push(this._prepareModel(upload));
        }
        return _results;
      }).call(this);
      this.length = this.models.length;
      this._idToModel = {};
      _ref1 = this.models;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        upload = _ref1[_j];
        upload.on('all', this._onUploadEvent, this);
        this._idToModel[upload.id] = upload;
      }
      this._priorityQueue.reset(this.models);
      return this.trigger('reset', uploads);
    };

    UploadCollection.prototype.get = function(id) {
      var _ref;
      return (_ref = this._idToModel[id]) != null ? _ref : null;
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

    UploadCollection.prototype.add = function(uploadOrUploads) {
      if (uploadOrUploads.length != null) {
        return this.addBatch(uploadOrUploads);
      } else {
        return this.addBatch([uploadOrUploads]);
      }
    };

    UploadCollection.prototype.addBatch = function(uploads) {
      var upload, _i, _j, _len, _len1;
      for (_i = 0, _len = uploads.length; _i < _len; _i++) {
        upload = uploads[_i];
        this._idToModel[upload.id] = upload;
        upload.on('all', this._onUploadEvent, this);
        this.models.push(upload);
      }
      this.length += uploads.length;
      this._priorityQueue.addBatch(uploads);
      for (_j = 0, _len1 = uploads.length; _j < _len1; _j++) {
        upload = uploads[_j];
        this.trigger('add', upload);
      }
      return this.trigger('add-batch', uploads);
    };

    UploadCollection.prototype._onUploadEvent = function(event, model, collection, options) {
      if (event !== 'add' && event !== 'remove') {
        this.trigger.apply(this, arguments);
      }
      if (event === 'change') {
        return this._priorityQueue.change(model);
      }
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
        return this._priorityQueue.addBatch(toAdd);
      }
    };

    return UploadCollection;

  })();
});
