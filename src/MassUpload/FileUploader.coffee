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
#       onError: (file, errorDetail) -> ...
#     })
#
#     fileUploader.run(file)
#
# When run, FileUploader:
#
# 1. Calls onStart().
# 2. Calls doUpload() with that File.
# 3. Calls onProgress() during upload, with { loaded: n, total: n }.
#    contain progress) when doUpload() calls its progress callback.
# 4. Calls onSuccess() or onError() with the File, followed by
#    onStop() with the File.
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
    @_file = null
    @_abortCallback = null
    @_aborting = false

  run: (file) ->
    throw 'already running' if @_file?

    @_file = file

    @callbacks.onStart?(@_file)

    @_abortCallback = @doUpload(
      file,
      ((progressEvent) => @_onProgress(file, progressEvent)),
      (() => @_onSuccess(file)),
      ((errorDetail) => @_onError(file, errorDetail))
    )

  abort: ->
    if @_file && !@_aborting
      @_aborting = true
      if typeof @_abortCallback == 'function'
        @_abortCallback()

  _onProgress: (file, progressEvent) ->
    @callbacks.onProgress?(file, progressEvent)

  _onSuccess: (file) ->
    @callbacks.onSuccess?(file)
    @_onStop(file)

  _onError: (file, errorDetail) ->
    @callbacks.onError?(file, errorDetail)
    @_onStop(file)

  _onStop: (file) ->
    @_file = null
    @_abortCallback = null
    @_aborting = false
    @callbacks.onStop?(file)
