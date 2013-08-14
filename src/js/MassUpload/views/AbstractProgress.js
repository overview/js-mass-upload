define(['backbone', 'underscore', 'humanReadableSize'], function(Backbone, _, humanReadableSize) {
  return Backbone.View.extend({
    className: 'list-files-progress',
    massUploadProperty: '',
    preamble: '',
    initialize: function() {
      var _this = this;
      if (this.model == null) {
        throw 'Must specify model, a MassUpload object';
      }
      this.listenTo(this.model, "change:" + this.massUploadProperty, function() {
        return _this._updateProgress();
      });
      return this.render();
    },
    template: _.template("<%= preamble %>\n<progress value=\"<%= progress.loaded %>\" max=\"<%= progress.total %>\"></progress>\n<span class=\"text\"><%= humanReadableSize(progress.loaded) %> / <%= humanReadableSize(progress.total) %></span>"),
    getProgress: function() {
      return this.model.get(this.massUploadProperty) || {
        loaded: 0,
        total: 0
      };
    },
    render: function() {
      var html, progress;
      progress = this.getProgress();
      html = this.template({
        preamble: this.preamble,
        progress: progress,
        humanReadableSize: humanReadableSize
      });
      this.$el.html(html);
      this.progressEl = this.$el.find('progress')[0];
      return this.textEl = this.$el.find('.text')[0];
    },
    _updateProgress: function() {
      var progress;
      progress = this.getProgress();
      this.progressEl.value = progress.loaded;
      this.progressEl.max = progress.total;
      Backbone.$(this.textEl).text("" + (humanReadableSize(progress.loaded)) + " / " + (humanReadableSize(progress.total)));
      return void 0;
    }
  });
});
