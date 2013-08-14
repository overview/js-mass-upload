define [ './AbstractProgressView' ], (AbstractProgressView) ->
  # When listing files, shows a progress bar
  AbstractProgressView.extend
    className: 'list-files-progress'
    massUploadProperty: 'listFilesProgress'
    preamble: 'Checking for files on the server'
