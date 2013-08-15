define(['backbone', 'underscore', './humanReadableSize'], function(Backbone, _, humanReadableSize) {
  return Backbone.View.extend({
    className: 'list-files-progress',
    preamble: '',
    progressProperty: '',
    errorProperty: '',
    retryText: 'Retry',
    events: {
      'click .retry': '_onRetry'
    },
    initialize: function() {
      var _this = this;
      if (this.model == null) {
        throw 'Must specify model, a MassUpload object';
      }
      this.listenTo(this.model, "change:" + this.progressProperty, function() {
        return _this._updateProgress();
      });
      this.listenTo(this.model, "change:" + this.errorProperty, function() {
        return _this._updateError();
      });
      return this.render();
    },
    template: _.template("<div class=\"error\">\n  <span class=\"message\"><%- error ? error : '' %></span>\n  <a href=\"#\" class=\"retry\"><%- retryText %></a>\n</div>\n<div class=\"preamble\">\n  <%- preamble %>\n</div>\n<div class=\"progress\">\n  <progress value=\"<%= progress.loaded %>\" max=\"<%= progress.total %>\"></progress>\n  <span class=\"text\"><%= humanReadableSize(progress.loaded) %> / <%= humanReadableSize(progress.total) %></span>\n</div>"),
    getProgress: function() {
      return this.model.get(this.progressProperty) || {
        loaded: 0,
        total: 0
      };
    },
    getError: function() {
      return this.model.get(this.errorProperty) || null;
    },
    render: function() {
      var error, html, progress;
      progress = this.getProgress();
      error = this.getError();
      html = this.template({
        error: error,
        preamble: this.preamble,
        retryText: this.retryText,
        progress: progress,
        humanReadableSize: humanReadableSize
      });
      this.$el.html(html);
      this.progressEl = this.$el.find('progress')[0];
      this.textEl = this.$el.find('.text')[0];
      return this.errorEl = this.$el.find('.message')[0];
    },
    _updateProgress: function() {
      var progress;
      progress = this.getProgress();
      this.progressEl.value = progress.loaded;
      this.progressEl.max = progress.total;
      Backbone.$(this.textEl).text("" + (humanReadableSize(progress.loaded)) + " / " + (humanReadableSize(progress.total)));
      return void 0;
    },
    _updateError: function() {
      var error;
      error = this.getError();
      Backbone.$(this.errorEl).text(error || '');
      return void 0;
    },
    _onRetry: function(e) {
      e.preventDefault();
      return this.trigger('retry');
    }
  });
});
