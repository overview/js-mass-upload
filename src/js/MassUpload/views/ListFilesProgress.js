define(['./AbstractProgress'], function(AbstractProgressView) {
  return AbstractProgressView.extend({
    className: 'list-files-progress',
    progressProperty: 'listFilesProgress',
    errorProperty: 'listFilesError',
    preamble: 'Checking for files on the server',
    retryText: 'Retry'
  });
});
