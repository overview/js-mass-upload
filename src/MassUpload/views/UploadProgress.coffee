AbstractProgressView = require('./AbstractProgress')

# When listing files, shows a progress bar
module.exports = class UploadProgressView extends AbstractProgressView
  className: 'upload-progress'
  progressProperty: 'uploadProgress'
  errorProperty: 'uploadErrors'
  preamble: 'Synchronization progress'

  getError: -> @model.get('uploadErrors')?[0]?.error || null
