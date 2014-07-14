define(['backbone', 'underscore', './humanReadableSize'], function(Backbone, _, humanReadableSize) {
  var liToEls, progressToText, uploadToStatusAndMessage;
  progressToText = function(progress) {
    return "" + (humanReadableSize(progress.loaded)) + " / " + (humanReadableSize(progress.total));
  };
  uploadToStatusAndMessage = function(upload) {
    if (upload.get('deleting')) {
      return {
        status: 'deleting',
        message: 'Deleting…'
      };
    } else if ((upload.get('file') == null) && !upload.isFullyUploaded()) {
      return {
        status: 'must-reselect',
        message: 'Drag the file here again or delete it'
      };
    } else if (upload.get('error')) {
      return {
        status: 'error',
        message: 'Retry this file or delete it'
      };
    } else if (upload.get('uploading')) {
      return {
        status: 'uploading',
        message: 'Uploading…'
      };
    } else if (upload.isFullyUploaded()) {
      return {
        status: 'uploaded',
        message: ''
      };
    } else {
      return {
        status: 'waiting',
        message: ''
      };
    }
  };
  liToEls = function(li) {
    var $li;
    $li = Backbone.$(li);
    return {
      li: $li[0],
      progress: $li.find('progress')[0],
      text: $li.find('.text')[0],
      message: $li.find('.message')[0],
      size: $li.find('.size')[0]
    };
  };
  return Backbone.View.extend({
    className: 'upload-collection',
    events: {
      'click .retry': '_onRetry',
      'click .delete': '_onDelete',
      'change input': '_onSelectFiles',
      'dragover': '_onDragover',
      'drop': '_onDrop'
    },
    template: _.template("<ul class=\"uploads\">\n  <%= collection.map(renderUpload).join('') %>\n</ul>\n<div class=\"upload-prompt\">\n  <button>\n    <h3>Select files to upload</h3>\n    <h4>Or drag and drop files here</h4>\n  </button>\n  <input type=\"file\" class=\"invisible-file-input\" multiple=\"multiple\" />\n</div>"),
    uploadTemplate: _.template("<li class=\"<%= status %>\" data-id=\"<%- upload.id %>\">\n  <a href=\"#\" class=\"delete\">Delete</a>\n  <a href=\"#\" class=\"retry\">Retry</a>\n  <h3><%- upload.id %></h3>\n  <div class=\"status\">\n    <progress value=\"<%= progress.loaded %>\" max=\"<%= progress.total %>\"></progress>\n    <span class=\"text\"><%= humanReadableSize(progress.loaded) %> / <%= humanReadableSize(progress.total) %></span>\n    <span class=\"size\"><%= humanReadableSize(progress.total) %></span>\n    <span class=\"message\"><%- message %></span>\n  </div>\n</li>"),
    initialize: function() {
      if (this.collection == null) {
        throw 'Must specify collection, an UploadCollection';
      }
      this.listenTo(this.collection, 'change', this._onChange);
      this.listenTo(this.collection, 'add', this._onAdd);
      this.listenTo(this.collection, 'remove', this._onRemove);
      this.listenTo(this.collection, 'reset', this.render);
      return this.render();
    },
    _renderUpload: function(upload) {
      var statusAndMessage;
      statusAndMessage = uploadToStatusAndMessage(upload);
      return this.uploadTemplate({
        upload: upload,
        status: statusAndMessage.status,
        message: statusAndMessage.message,
        error: upload.get('error'),
        progress: upload.getProgress(),
        humanReadableSize: humanReadableSize
      });
    },
    _onAdd: function(upload, collection, options) {
      var $li, html, index, laterElement, lis;
      html = this._renderUpload(upload);
      $li = Backbone.$(html);
      this.els[upload.id] = liToEls($li);
      lis = this.ul.childNodes;
      index = (options != null ? options.index : void 0) || lis.length;
      if (index >= lis.length) {
        this.ul.appendChild($li[0]);
      } else {
        laterElement = this.ul.childNodes[index];
        this.ul.insertBefore($li[0], laterElement);
      }
      return void 0;
    },
    _onRemove: function(upload) {
      var els, id;
      id = upload.id;
      els = this.els[id];
      if (els == null) {
        throw 'Element does not exist';
      }
      this.ul.removeChild(els.li);
      delete this.els[id];
      return void 0;
    },
    _onChange: function(upload) {
      var els, id, progress, statusAndMessage;
      id = upload.id;
      els = this.els[id];
      if (els != null) {
        progress = upload.getProgress();
        statusAndMessage = uploadToStatusAndMessage(upload);
        els.progress.value = progress.loaded;
        els.progress.max = progress.total;
        els.text.firstChild.data = progressToText(progress);
        els.size.firstChild.data = humanReadableSize(progress.total);
        Backbone.$(els.message).text(statusAndMessage.message);
        return els.li.className = statusAndMessage.status;
      }
    },
    render: function() {
      var els, html,
        _this = this;
      html = this.template({
        collection: this.collection,
        renderUpload: function(upload) {
          return _this._renderUpload(upload);
        },
        humanReadableSize: humanReadableSize
      });
      this.$el.html(html);
      this.ul = this.$el.children('ul.uploads')[0];
      els = this.els = {};
      this.$el.find('ul.uploads>li').each(function(li) {
        var id;
        id = li.getAttribute('data-id');
        return els[id] = liToEls(li);
      });
      return this;
    },
    _onDragover: function(e) {
      return e.preventDefault();
    },
    _onDrop: function(e) {
      var files, _ref, _ref1;
      e.preventDefault();
      files = (_ref = e.originalEvent) != null ? (_ref1 = _ref.dataTransfer) != null ? _ref1.files : void 0 : void 0;
      if (files != null ? files.length : void 0) {
        return this.trigger('add-files', files);
      }
    },
    _eventToUpload: function(e) {
      var id;
      id = Backbone.$(e.target).closest('[data-id]').attr('data-id');
      return this.collection.get(id);
    },
    _onRetry: function(e) {
      var upload;
      e.preventDefault();
      upload = this._eventToUpload(e);
      return this.trigger('retry-upload', upload);
    },
    _onDelete: function(e) {
      var upload;
      e.preventDefault();
      upload = this._eventToUpload(e);
      return this.trigger('remove-upload', upload);
    },
    _onSelectFiles: function(e) {
      var files, input;
      e.preventDefault();
      input = e.target;
      files = input.files;
      this.trigger('add-files', files);
      return input.value = '';
    }
  });
});
