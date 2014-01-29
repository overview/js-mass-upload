define(['backbone'], function(Backbone) {
  return Backbone.Model.extend({
    defaults: {
      loaded: 0,
      total: 0
    },
    initialize: function() {
      var collection;
      collection = this.get('uploadCollection');
      if (collection == null) {
        throw 'Must initialize UploadProgress with `uploadCollection`, an UploadCollection';
      }
      this._idToLastKnownProgress = {};
      return this._updateAndStartListening();
    },
    _adjust: function(dLoaded, dTotal) {
      return this.set({
        loaded: this.get('loaded') + dLoaded,
        total: this.get('total') + dTotal
      });
    },
    add: function(model) {
      var progress;
      progress = model.getProgress();
      this._adjust(progress.loaded, progress.total);
      return this._idToLastKnownProgress[model.id] = progress;
    },
    reset: function(collection) {
      var idToLastKnownProgress, loaded, model, progress, total, _i, _len, _ref;
      idToLastKnownProgress = this._idToLastKnownProgress = {};
      loaded = 0;
      total = 0;
      _ref = collection.models;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        model = _ref[_i];
        progress = model.getProgress();
        idToLastKnownProgress[model.id] = progress;
        loaded += progress.loaded;
        total += progress.total;
      }
      return this.set({
        loaded: loaded,
        total: total
      });
    },
    remove: function(model) {
      var progress;
      progress = model.getProgress();
      this._adjust(-progress.loaded, -progress.total);
      return this._idToLastKnownProgress[model.id] = progress;
    },
    change: function(model) {
      var newProgress, oldProgress;
      oldProgress = this._idToLastKnownProgress[model.id];
      if (oldProgress != null) {
        newProgress = model.getProgress();
        this._adjust(newProgress.loaded - oldProgress.loaded, newProgress.total - oldProgress.total);
        return this._idToLastKnownProgress[model.id] = newProgress;
      }
    },
    _updateAndStartListening: function() {
      var collection, event, _i, _len, _ref;
      collection = this.get('uploadCollection');
      _ref = ['add', 'remove', 'change', 'reset'];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        event = _ref[_i];
        this.listenTo(collection, event, this[event]);
      }
      this.reset(collection);
      return void 0;
    },
    inBatch: function(callback) {
      this.stopListening(this.get('uploadCollection'));
      try {
        return callback();
      } finally {
        this._updateAndStartListening();
      }
    }
  });
});
