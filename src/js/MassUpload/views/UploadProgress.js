define(['./AbstractProgress'], function(AbstractProgressView) {
  return AbstractProgressView.extend({
    className: 'upload-progress',
    progressProperty: 'uploadProgress',
    errorProperty: 'uploadErrors',
    preamble: 'Synchronization progress',
    getError: function() {
      var _ref, _ref1;
      return ((_ref = this.model.get('uploadErrors')) != null ? (_ref1 = _ref[0]) != null ? _ref1.error : void 0 : void 0) || null;
    }
  });
});
