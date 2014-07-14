define [ 'underscore', 'backbone', './FileInfo' ], (_, Backbone, FileInfo) ->
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
  class Upload
    @:: = Object.create(Backbone.Events)

    defaults:
      file: null
      fileInfo: null
      error: null
      uploading: false
      deleting: false

    constructor: (attributes) ->
      @file = attributes.file ? null
      @fileInfo = attributes.fileInfo ? null
      @error = attributes.error ? null
      @uploading = attributes.uploading || false
      @deleting = attributes.deleting || false
      @id = if @file?
        @file.webkitRelativePath || @file.name
      else
        @fileInfo.name

      # Backbone.Model compatibility
      @attributes = this

    # Backbone.Model compatibility
    get: (attr) -> @[attr]

    # Backbone.Model compatibility
    set: (attrs) ->
      @_previousAttributes = new Upload(this)

      for k, v of attrs
        @[k] = v

      @trigger('change', this)

      @_previousAttributes = null

    # Backbone.Model compatibility
    previousAttributes: -> @_previousAttributes

    # Returns the memoized file size
    #
    # Use this, not @file.size, to avoid repeated synchronous filesystem calls.
    size: -> @_size ?= @file?.size

    # Returns the memoized lastModifiedDate
    #
    # Use this, not @file.lastModifiedDate, to avoid repeated synchronous filesystem calls.
    lastModifiedDate: -> @_lastModifiedDate ?= @file?.lastModifiedDate

    # Updates the `fileInfo` object with the given `progressEvent`.
    #
    # `progressEvent` must have `loaded` and `total` properties.
    updateWithProgress: (progressEvent) ->
      # Always create a new FileInfo object, whether one exists or not.
      fileInfo = new FileInfo(@id, @lastModifiedDate(), progressEvent.total, progressEvent.loaded)
      @set(fileInfo: fileInfo)

    # Returns a progress object with `loaded` and `total` properties.
    getProgress: ->
      if @fileInfo? && !@hasConflict()
        { loaded: @fileInfo.loaded, total: @fileInfo.total }
      else if @file?
        { loaded: 0, total: @size() }

    # True iff the file has been successfully uploaded.
    isFullyUploaded: ->
      @fileInfo? &&
        !@error? &&
        !@uploading &&
        !@deleting &&
        @fileInfo.loaded == @fileInfo.total

    # True iff the file matches up with the fileInfo.
    #
    # This is false if, say, the user has selected a newer version of a file to
    # upload after already uploading a previous version of the same file.
    hasConflict: ->
      @fileInfo? && @file? && (
        @fileInfo.name != @id ||
        @fileInfo.total != @size() ||
        @fileInfo.lastModifiedDate.getTime() != @lastModifiedDate().getTime()
      )
