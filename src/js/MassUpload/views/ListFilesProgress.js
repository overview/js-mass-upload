define(['./AbstractProgress'], function(AbstractProgressView) {
  return AbstractProgressView.extend({
    className: 'list-files-progress',
    massUploadProperty: 'listFilesProgress',
    preamble: 'Checking for files on the server'
  });
});
