define [ 'backbone', './FileInfo' ], (Backbone, FileInfo) ->
  # Represents an upload of a local file to the server.
  #
  # This can have several states:
  #
  # * It can be a locally-selected file that is not yet on the server. In this
  #   case, `file` is non-null and `fileInfo` is null.
  # * It can be an already-uploaded file that was not selected locally. In this
  #   case, `fileInfo` is non-null and `file` is null.
  # * It can be a locally-selected file that is already on the server, either
  #   partially-uploaded or fully-uploaded. In this case, both `fileInfo` and
  #   `file` are non-null.
  #
  # In all cases, use `fileInfo.loaded` and `fileInfo.total` to determine what
  # is on the server, and use `error` to determine whether there is an error.
  #
  # There are two additional status properties that are related but distinct:
  #
  # * `uploading`, true if the upload is currently in progress.
  # * `deleting`, true if a delete is currently in progress.
  #
  # A file is entirely on the server if:
  #
  #     !uploading && !error && fileInfo.loaded == fileInfo.total
  #
  # There is no way to tell, from looking at an Upload, whether it is fully
  # deleted: instead, do something when the Upload with `deleting=true` has
  # been removed from its UploadCollection.
  class Upload extends Backbone.Model
    defaults:
      file: null
      fileInfo: null
      error: null
      uploading: false
      deleting: false

    initialize: (attributes) ->
      fileLike = attributes.file ? attributes.fileInfo
      id = fileLike.name
      @set({ id: id })

    # Updates the `fileInfo` object with the given `progressEvent`.
    #
    # `progressEvent` must have `loaded` and `total` properties.
    updateWithProgress: (progressEvent) ->
      # Always create a new FileInfo object, whether one exists or not.
      fstat = @fstatSync()
      fileInfo = new FileInfo(@id, fstat.lastModifiedDate, progressEvent.total, progressEvent.loaded)
      @set('fileInfo', fileInfo)

    # Returns a progress object with `loaded` and `total` properties.
    getProgress: ->
      if (fileInfo = @get('fileInfo'))? && !@hasConflict()
        { loaded: fileInfo.loaded, total: fileInfo.total }
      else if (file = @get('file'))?
        { loaded: 0, total: @fstatSync().size }

    # Memoizes file.size and file.lastModifiedDate, to avoid hitting disk.
    #
    # This call is synchronous: it may take milliseconds on a slow system, but
    # only the first time (per file).
    fstatSync: ->
      file = @get('file')
      if file?
        @_fstat ?= { size: file.size, lastModifiedDate: file.lastModifiedDate }

    # True iff the file has been successfully uploaded.
    isFullyUploaded: ->
      fileInfo = @get('fileInfo')
      error = @get('error')
      !@get('uploading') &&
        !@get('deleting') &&
        !@get('error')? &&
        fileInfo? && fileInfo.loaded == fileInfo.total

    # True iff the file matches up with the fileInfo.
    #
    # This is false if, say, the user has selected a newer version of a file to
    # upload after already uploading a previous version of the same file.
    hasConflict: ->
      fileInfo = @get('fileInfo')
      file = @get('file')
      fileInfo? && file? && (
        fileInfo.name != file.name ||
        fileInfo.lastModifiedDate.getTime() != @fstatSync().lastModifiedDate.getTime() ||
        fileInfo.total != @fstatSync().size
      )
