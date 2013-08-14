define(['./ListFilesProgress', './UploadCollection', './UploadProgress'], function(ListFilesProgressView, UploadCollectionView, UploadProgressView) {
  return Backbone.View.extend({
    className: 'mass-upload',
    initialize: function() {
      var listFilesProgressView, uploadCollectionView, uploadProgressView,
        _this = this;
      listFilesProgressView = new ListFilesProgressView({
        model: this.model
      });
      this.$el.append(listFilesProgressView.el);
      uploadCollectionView = new UploadCollectionView({
        collection: this.model.uploads
      });
      this.$el.append(uploadCollectionView.el);
      this.listenTo(uploadCollectionView, 'add-files', function(files) {
        return _this.model.addFiles(files);
      });
      this.listenTo(uploadCollectionView, 'remove-upload', function(upload) {
        return _this.model.removeUpload(upload);
      });
      this.listenTo(uploadCollectionView, 'retry-upload', function(upload) {
        return _this.model.retryUpload(upload);
      });
      uploadProgressView = new UploadProgressView({
        model: this.model
      });
      this.$el.append(uploadProgressView.el);
      this.listenTo(this.model, 'change:status', function() {
        return _this.render();
      });
      return this.render();
    },
    render: function() {
      var status;
      status = this.model.get('status');
      return this.$el.attr('data-status', status);
    }
  });
});
