# Lists files from the server.
#
# Usage:
#
#   fileLister = new FileLister(doListFiles, {
#     onStart: () -> ...
#     onProgress: (progressEvent) -> ...
#     onSuccess: (fileInfos) -> ...
#     onError: (massUploadError) -> ...
#     onStop: () -> ...
#   })
#   fileLister.run()
#
# In a nutshell, FileLister is a proxy for doListFiles().
#
# Arguments:
#
# * doListFiles: a user-supplied function. (see README)
# * callbacks:
#     * onStart: called when starting
#     * onProgress: a function accepting a ProgressEvent
#     * onSuccess: called with an Array of FileInfo objects
#     * onError: called with a user-supplied error
#     * onStop: called after either onSuccess or onError
module.exports = class FileLister
  constructor: (@doListFiles, @callbacks) ->
    @running = false

  run: ->
    throw 'already running' if @running
    @running = true

    @callbacks.onStart?()

    @doListFiles(
      ((progressEvent) => @callbacks.onProgress?(progressEvent)),
      ((fileInfos) => @_onSuccess(fileInfos)),
      ((errorDetail) => @_onError(errorDetail))
    )

  _onSuccess: (fileInfos) ->
    @callbacks.onSuccess?(fileInfos)
    @_onStop()

  _onError: (errorDetail) ->
    @callbacks.onError(errorDetail)
    @_onStop()

  _onStop: ->
    @running = false
    @callbacks.onStop?()
