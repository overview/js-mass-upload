AbstractProgressView = require('./AbstractProgress')

# When listing files, shows a progress bar
module.exports = class ListFilesProgressView extends AbstractProgressView
  className: 'list-files-progress'
  progressProperty: 'listFilesProgress'
  errorProperty: 'listFilesError'
  preamble: 'Checking for files on the server'
  retryText: 'Retry'
