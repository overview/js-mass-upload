Backbone = require('backbone')
_ = require('underscore')
UploadCollection = require('./MassUpload/UploadCollection')
FileLister = require('./MassUpload/FileLister')
FileUploader = require('./MassUpload/FileUploader')
FileDeleter = require('./MassUpload/FileDeleter')
State = require('./MassUpload/State')
UploadProgress = require('./MassUpload/UploadProgress')

# a Mass Upload controller.
#
# All its properties are to be read, not written. The usage, from the
# controller's perspective, is:
#
#     options = { doListFiles: ..., ... }
#     massUpload = new MassUpload(options)
#     massUpload.fetchFileInfosFromServer() # must be called before upload
#                                           # can begin
#     massUpload.addFiles([ ... ]) # from a <input type="file">
#     # Uploading is implicit: once the fetch is complete and files have been
#     # added, the uploading will begin
#
#     massUpload.removeUpload(...) # from user action
#
#     massUpload.on('change:status', => ...)
#     # When status is 'waiting', the server is in sync with what the user
#     # selected (barring race conditions). The form may be submitted as
#     # long as there are no errors in the uploads collection.
#
#     massUpload.abort()
#     # Abort the current upload entirely. Wire this to your cancel button.
#
# From the view's perspective, rendering is straightforward:
#
#     massUpload.uploads # a Backbone.Collection of Upload objects
#     massUpload.get('status') # listing-files, listing-files-error,
#                              # uploading, uploading-error
#                              # waiting, waiting-error (e.g. conflicts).
#                              # uploading-error trumps waiting-error.
#
#     massUpload.get('listFilesProgress') # { loaded: 30, total: 100 }
#
#     massUpload.get('listFilesError') # user-supplied doListFiles() error
#
#     massUpload.get('uploadProgress') # { loaded: 30, total: 100 } for all
#                                      # files
#
#     massUpload.get('uploadErrors') # Array of { upload: upload,
#                                    # error: error } objects.
#                                    # Generally, errors should be rendered
#                                    # alongside their uploads so this array
#                                    # is redundant; but it's useful if you
#                                    # want to present an index of all
#                                    # errors or test if there are >0 errors.
#
# There are a few general rules:
#
# * Do not call any setters on any variables you access from MassUpload.
#   Only use MassUpload methods.
# * addFiles() and removeUpload() may be called at any time. MassUpload will
#   gracefully adjust itself to the new settings. (Any time you change what
#   should be sent to the server, MassUpload aborts uploading, deletes
#   unwanted files, and uploads un-uploaded files.)
# * If stuck in `listing-files-error` status, call retryListFiles().
# * To remove upload/delete errors, call retryUpload(upload) or
#   retryAllUploads().
module.exports = class MassUpload extends Backbone.Model
  defaults: ->
    status: 'waiting'
    listFilesProgress: null
    listFilesError: null
    uploadProgress: null
    uploadErrors: []

  # We never pass attributes to the constructor
  constructor: (options) ->
    @_removedUploads = [] # uploads removed by the user, still on the server
    super({}, options)

  initialize: (attributes, options) ->
    @_options = options
    @uploads = options?.uploads ? new UploadCollection()

    # Make @get('uploadProgress') a flat object, not a Backbone.Model
    @_uploadProgress = new UploadProgress({ uploadCollection: @uploads })
    resetUploadProgress = =>
      @set(uploadProgress: @_uploadProgress.pick('loaded', 'total'))
    @listenTo(@_uploadProgress, 'change', resetUploadProgress)
    resetUploadProgress()

    @listenTo(@uploads, 'add-batch', @_onUploadBatchAdded)
    @listenTo(@uploads, 'change', (upload) => @_onUploadChanged(upload))
    @listenTo(@uploads, 'reset', => @_onUploadsReset())

    @prepare()

  prepare: ->
    options = @_options
    @lister = options?.lister ? new FileLister(options.doListFiles)
    @lister.callbacks =
      onStart: => @set(status: 'listing-files', listFilesError: null)
      onProgress: (progressEvent) => @set(listFilesProgress: progressEvent)
      onSuccess: (fileInfos) =>
        @uploads.addFileInfos(fileInfos)
        @_tick()
      onError: (error) => @set(listFilesError: error, status: 'listing-files-error')
      onStop: => # nothing: @_tick() on success, stall on error

    @uploader = options?.uploader ? new FileUploader(options.doUploadFile)
    @uploader.callbacks =
      onStart: (upload) => upload.set(uploading: true, error: null)
      onStop: (upload) =>
        upload.set(uploading: false)
        @_tick()
      onSuccess: (upload) => upload.updateWithProgress(loaded: upload.size(), total: upload.size())
      onError: (upload, error) => upload.set(error: error)
      onProgress: (upload, progressEvent) => upload.updateWithProgress(progressEvent)

    @deleter = options?.deleter ? new FileDeleter(options.doDeleteFile)
    @deleter.callbacks =
      onStart: (upload) => @set(status: 'uploading')
      onSuccess: (upload) => @uploads.remove(upload)
      onError: (upload, error) => upload.set(error: error)
      onStop: (upload) => @_tick()

  fetchFileInfosFromServer: ->
    @lister.run()

  retryListFiles: ->
    @fetchFileInfosFromServer()

  retryUpload: (upload) ->
    upload.set(error: null)

  retryAllUploads: ->
    # Set error=null from first to last. That way, _forceBestTick() will
    # only abort at most once, since uploads.next() will return the same
    # Upload every call.
    @uploads.each (upload) ->
      upload.set(error: null)

  addFiles: (files) ->
    @_uploadProgress.inBatch =>
      @uploads.addFiles(files)

  removeUpload: (upload) ->
    upload.set(deleting: true)

  abort: ->
    @uploads.each (upload) =>
      @removeUpload(upload)
    @uploads.reset()
    @prepare()

  _mergeUploadError: (upload, prevError, curError) ->
    # Update the uploadErrors attribute

    newErrors = @get('uploadErrors').slice(0) # shallow copy
    index = _.sortedIndex(newErrors, { upload: upload }, (x) -> x.upload.id)

    if !prevError? # new error: insert curError
      newErrors.splice(index, 0, { upload: upload, error: curError })
    else if !curError? # old error: remove prevError
      newErrors.splice(index, 1)
    else # replace prevError with curError
      newErrors[index].error = curError

    @set(uploadErrors: newErrors)

  _onUploadBatchAdded: (uploads) ->
    for upload in uploads
      error = upload.get('error')
      if error?
        @_mergeUploadError(upload, null, error)

    @_forceBestTick()

  _onUploadChanged: (upload) ->
    error1 = upload.previousAttributes().error
    error2 = upload.get('error')
    if error1 != error2
      @_mergeUploadError(upload, error1, error2)

    deleting1 = upload.previousAttributes().deleting
    deleting2 = upload.get('deleting')

    if deleting2 && !deleting1
      @_removedUploads.push(upload)

    @_forceBestTick()

  _onUploadsReset: () ->
    newErrors = []

    @uploads.each (upload) ->
      if (error = upload.get('error'))
        newErrors.push({ upload: upload, error: error })

    @set
      uploadErrors: newErrors

    @_tick()

  # Looks for a task
  _tick: ->
    upload = @uploads.next()
    @_currentUpload = upload

    if upload?
      if upload.get('deleting')
        @deleter.run(upload)
      else
        @uploader.run(upload)

    status = if @get('uploadErrors').length
      'uploading-error'
    else if upload?
      'uploading'
    else
      progress = @get('uploadProgress')
      if progress.loaded == progress.total
        'waiting'
      else
        'waiting-error'

    @set(status: status)

  # If ticking, aborts and ticks again to work on the highest-priority task
  _forceBestTick: ->
    upload = @uploads.next()
    if upload != @_currentUpload
      if @_currentUpload
        # Either @uploader or @deleter is working. We want them to stop as
        # soon as possible so we can adjust to new priorities.
        @uploader.abort()
      else
        @_tick()
