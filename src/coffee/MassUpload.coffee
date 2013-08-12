define [
  'backbone'
  './MassUpload/UploadCollection'
  './MassUpload/FileLister'
  './MassUpload/MultiUploader'
  './MassUpload/FileDeleter'
  './MassUpload/State'
], (
  Backbone
  UploadCollection
  FileLister
  MultiUploader
  FileDeleter
  State
) ->
  # a Mass Upload controller.
  #
  # All its properties are to be read, not written. The usage, from the view's
  # perspective, is:
  #
  #     options = { doListFiles: ..., ... }
  #     massUpload = new MassUpload(options)
  Backbone.Model.extend
    defaults: ->
      status: 'waiting'
      listFilesProgress: null
      listFilesError: null
      uploadProgress: null
      uploadErrors: []

    # We never pass attributes to the constructor
    constructor: (options) ->
      Backbone.Model.call(this, {}, options)

    initialize: (attributes, options) ->
      @uploads = options?.uploads ? new UploadCollection()
      @lister = options?.lister ? new FileLister(options.doListFiles)
      @lister.callbacks =
        onStart: => @_onListerStart()
        onSuccess: (fileInfos) => @_onListerSuccess(fileInfos)
        onError: (errorDetail) => @_onListerError(errorDetail)
        onStop: => @_onListerStop()

      @uploader = options?.uploader ? new MultiUploader([], options.doUploadFile)
      @uploader.callbacks =
        onStart: => @_onUploaderStart()
        onStop: => @_onUploaderStop()
        onErrors: => @_onUploaderErrors()
        onSuccess: => @_onUploaderSuccess()
        onProgress: (progressEvent) => @_onUploaderProgress(progressEvent)
        onStartAbort: => @_onUploaderStartAbort()
        onSingleStart: (upload) -> @_onUploaderSingleStart(upload)
        onSingleStop: (upload) -> @_onUploaderSingleStop(upload)
        onSingleSuccess: (upload) -> @_onUploaderSingleSuccess(upload)
        onSingleError: (upload, errorDetail) -> @_onUploaderSingleError(upload, errorDetail)
        onSingleProgress: (upload, progressEvent) -> @_onUploaderSingleProgress(upload, progressEvent)

      @deleter = options?.deleter ? new FileDeleter(options.doDeleteFile)
      @deleter.callbacks =
        onStart: (fileInfo) => @_onDeleterStart(fileInfo)
        onSuccess: (fileInfo) => @_onDeleterSuccess(fileInfo)
        onError: (fileInfo, errorDetail) => @_onDeleterError(fileInfo, errorDetail)
        onStop: (fileInfo) => @_onDeleterStop(fileInfo)
