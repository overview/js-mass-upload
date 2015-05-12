FileInfo = require('./FileInfo')

# Uploads files to the server.
#
# Usage:
#
#     fileUploader = new FileUploader(doUpload, {
#       onStart: (file) -> ...
#       onStop: (file) -> ...
#       onProgress: (file) -> ...
#       onSuccess: (file) -> ...
#       onError: (file, error) -> ...
#     })
#
#     fileUploader.run(upload)
#
# When run, FileUploader:
#
# 1. Calls onStart().
# 2. Calls doUpload() with the Upload.
# 3. Calls onProgress() during upload, with { loaded: n, total: n }.
#    contain progress) when doUpload() calls its progress callback.
# 4. Calls onSuccess() or onError() with the Upload, followed by
#    onStop() with the Upload.
#
# Only one file can be uploaded at a time.
#
# Aborting:
#
#     fileUploader.abort()
#
# To abort, FileUploader:
#
# 1. Calls the abort callback that was returned by doUpload.
# 2. Waits; the abort callback will lead to either success or error (it's a
#    race).
# 3. Calls onSuccess() or onError(), and finally onStop().
#
# Note: handle onStop(), not onError(), if you want to chain something to
# aborts. First of all, this protects you from a faulty abort method (if
# abort does nothing, the file upload will actually succeed). Second, in a
# race condition abort() may cause success, not error.
module.exports = class FileUploader
  constructor: (@doUpload, @callbacks) ->
    @_upload = null
    @_abortCallback = null
    @_aborting = false

  run: (upload) ->
    throw 'already running' if @_upload?

    @_upload = upload

    @callbacks.onStart?(upload)

    @_abortCallback = @doUpload(
      upload,
      ((progressEvent) => @_onProgress(upload, progressEvent)),
      ((error) => if error then @_onError(upload, error) else @_onSuccess(upload))
    )

  abort: ->
    if @_upload && !@_aborting
      @_aborting = true
      if typeof @_abortCallback == 'function'
        @_abortCallback()

  _onProgress: (upload, progressEvent) ->
    @callbacks.onProgress?(upload, progressEvent)

  _onSuccess: (upload) ->
    @callbacks.onSuccess?(upload)
    @_onStop(upload)

  _onError: (upload, error) ->
    @callbacks.onError?(upload, error)
    @_onStop(upload)

  _onStop: (upload) ->
    @_upload = null
    @_abortCallback = null
    @_aborting = false
    @callbacks.onStop?(upload)
