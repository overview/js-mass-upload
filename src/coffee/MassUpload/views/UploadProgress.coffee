define [ './AbstractProgress' ], (AbstractProgressView) ->
  # When listing files, shows a progress bar
  AbstractProgressView.extend
    className: 'upload-progress'
    massUploadProperty: 'uploadProgress'
    preamble: 'Uploading'
