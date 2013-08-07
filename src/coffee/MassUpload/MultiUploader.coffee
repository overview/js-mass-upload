define [ './FileInfo' ], (FileInfo) ->
  # Iterates through all uploads, returning the ones worth uploading.
  #
  # Usage:
  #
  #     cursor = new Cursor(uploads)
  #     while (upload = cursor.next())
  #       ... upload the upload ...
  #
  # The Cursor will skip uploads that have already completed. And next() will
  # always increment, so if an upload causes an error, it won't be retried
  # until a new Cursor is created.
  class Cursor
    constructor: (@uploads) ->
      @i = -1

    # Returns the next Upload to handle. Returns `null` if there are none left.
    next: ->
      # Increment @i until we return something useful
      while @i < @uploads.length - 1
        @i += 1

        upload = @uploads[@i]
        return upload if !upload.fileInfo? # we've never tried uploading
        fileInfo = upload.fileInfo
        return upload if fileInfo.loaded < fileInfo.total # we're resuming

      null

  # Uploads files to the server.
  #
  # Usage:
  #
  #     multiUploader = new MultiUploader(uploads, doUpload, {
  #       onSingleStart: (upload) -> ...
  #       onSingleStop: (upload) -> ...
  #       onSingleProgress: (upload) -> ...
  #       onSingleSuccess: (upload) -> ...
  #       onSingleError: (upload, errorDetail) -> ...
  #       onStart: () -> ...
  #       onStop: () -> ...
  #       onProgress: (progressEvent) -> ...
  #       onSuccess: () -> ...
  #       onErrors: ([ { upload: upload, errorDetail: errorDetail }, ... ])
  #     })
  #
  #     multiUploader.run()
  #
  # When run, MultiUploader:
  #
  # 1. Calls onStart().
  # 2. Chooses an Upload that is not yet on the server.
  # 3. Calls onSingleStart() with that Upload.
  # 4. Calls doUpload() with that Upload's File.
  # 5. Calls onSingleProgress() with that Upload (its FileInfo will exist and
  #    contain progress) when doUpload() calls its progress callback.
  # 6. Calls onProgress({ total: totalBytes, loaded: totalLoadedBytes }) when
  #    doUpload() calls its progress callback.
  # 7. Calls onSingleSuccess() or onSingleError() with the Upload, followed by
  #    onSingleStop() with the Upload.
  # 8. Calls onSuccess() with no arguments or onErrors() with an Array of
  #    { upload: Upload, detail: errorDetail } Objects.
  # 9. Calls onStop()
  #
  # If doUpload() calls its error callback, that only stops the current upload,
  # not all of them. onSingleError() will be called right away for that upload;
  # onErrors() will only be called after all uploads have completed or errored.
  #
  # Only one file is uploaded at a time.
  class MultiUploader
    constructor: (@uploads, @doUpload, @callbacks) ->
      @_cursor = null
      @_errors = null
      @_upload = null

      @_refreshProgress()

    # Sets @_progress = { total: ?, loaded: ? } by iterating over @uploads
    _refreshProgress: ->
      total = 0
      loaded = 0

      for upload in @uploads
        file = upload.file
        fileInfo = upload.fileInfo
        if file?
          total += file.size
        else if fileInfo?
          total += fileInfo.total

        if fileInfo?
          loaded += fileInfo.loaded

      @_progress = { total: total, loaded: loaded }

    run: ->
      throw 'already running' if @_cursor?

      @callbacks.onStart?()
      
      @_cursor = new Cursor(@uploads)
      @_errors = []

      @_tick()

    # Finds another upload and begins uploading it
    _tick: ->
      upload = @_cursor.next()
      if upload?
        @_startSingleUpload(upload)
      else
        @_finish()

    # Kicks off a single upload
    _startSingleUpload: (upload) ->
      @_upload = upload

      @callbacks.onSingleStart?(upload)

      @doUpload(
        upload.file,
        ((progressEvent) => @_onSingleProgress(upload, progressEvent)),
        (() => @_onSingleSuccess(upload)),
        ((errorDetail) => @_onSingleError(upload, errorDetail))
      )

    _onSingleProgress: (upload, progressEvent) ->
      return if upload != @_upload
      progress = @_progress

      if upload.fileInfo?
        progress.loaded -= upload.fileInfo.loaded
      else
        upload.fileInfo = FileInfo.fromFile(upload.file)

      upload.fileInfo.loaded = progressEvent.loaded
      progress.loaded += progressEvent.loaded

      @callbacks.onSingleProgress?(upload, progressEvent)
      @callbacks.onProgress?(progress)

    _onSingleSuccess: (upload) ->
      return if upload != @_upload
      @callbacks.onSingleSuccess?(upload)
      @_onSingleStop(upload)

    _onSingleError: (upload, errorDetail) ->
      return if upload != @_upload
      @_errors.push({ upload: upload, detail: errorDetail })
      @callbacks.onSingleError?(upload, errorDetail)
      @_onSingleStop(upload)

    _onSingleStop: (upload) ->
      @callbacks.onSingleStop?(upload)
      @_tick()

    # Fires onSuccess()/onErrors() and onStop()
    _finish: ->
      errors = @_errors
      @_cursor = null
      @_errors = null
      @_upload = null

      if errors.length
        @callbacks.onErrors?(errors)
      else
        @callbacks.onSuccess?()

      @callbacks.onStop?()
