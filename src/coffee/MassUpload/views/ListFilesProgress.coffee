define [ './AbstractProgress' ], (AbstractProgressView) ->
  # When listing files, shows a progress bar
  AbstractProgressView.extend
    className: 'list-files-progress'
    progressProperty: 'listFilesProgress'
    errorProperty: 'listFilesError'
    preamble: 'Checking for files on the server'
    retryText: 'Retry'
