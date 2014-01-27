define(['backbone'], function(Backbone) {
  return Backbone.Model.extend({
    defaults: {
      loaded: 0,
      total: 0
    },
    initialize: function() {
      var collection;
      collection = this.get('collection');
      if (collection == null) {
        throw 'Must initialize UploadProgress with `collection`, an UploadCollection';
      }
      return this._updateAndStartListening();
    },
    _updateAndStartListening: function() {
      var add, adjust, callback, change, cidToLastKnownProgress, collection, eventName, events, remove, reset,
        _this = this;
      collection = this.get('collection');
      adjust = function(dLoaded, dTotal) {
        _this.set({
          loaded: _this.get('loaded') + dLoaded,
          total: _this.get('total') + dTotal
        });
        return void 0;
      };
      cidToLastKnownProgress = {};
      add = function(model) {
        var progress;
        progress = model.getProgress();
        adjust(progress.loaded, progress.total);
        return cidToLastKnownProgress[model.cid] = progress;
      };
      remove = function(model) {
        var progress;
        progress = cidToLastKnownProgress[model.cid];
        adjust(-progress.loaded, -progress.total);
        return delete cidToLastKnownProgress[model.cid];
      };
      change = function(model) {
        var newProgress, oldProgress;
        oldProgress = cidToLastKnownProgress[model.cid];
        if (oldProgress != null) {
          newProgress = model.getProgress();
          adjust(newProgress.loaded - oldProgress.loaded, newProgress.total - oldProgress.total);
          return cidToLastKnownProgress[model.cid] = newProgress;
        }
      };
      reset = function() {
        var progress;
        cidToLastKnownProgress = {};
        progress = {
          loaded: 0,
          total: 0
        };
        _this.get('collection').each(function(model) {
          var modelProgress;
          modelProgress = model.getProgress();
          cidToLastKnownProgress[model.cid] = modelProgress;
          progress.loaded += modelProgress.loaded;
          return progress.total += modelProgress.total;
        });
        return _this.set(progress);
      };
      events = {
        add: add,
        remove: remove,
        change: change,
        reset: reset
      };
      for (eventName in events) {
        callback = events[eventName];
        this.listenTo(collection, eventName, callback);
      }
      reset();
      return void 0;
    },
    inBatch: function(callback) {
      this.stopListening(this.get('collection'));
      try {
        return callback();
      } finally {
        this._updateAndStartListening();
      }
    }
  });
});
