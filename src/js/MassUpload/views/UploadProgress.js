define(['./AbstractProgress'], function(AbstractProgressView) {
  return AbstractProgressView.extend({
    className: 'upload-progress',
    massUploadProperty: 'uploadProgress',
    preamble: 'Uploading'
  });
});
