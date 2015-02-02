# Deletes files from the server.
#
# Usage:
#
#   fileDeleter = new FileDeleter(doDeleteFile, {
#     onStart: (fileInfo) ->
#     onSuccess: (fileInfo) ->
#     onError: (fileInfo, detail) ->
#     onStop: (fileInfo) ->
#   })
#   fileDeleter.run(fileInfo)
#
# FileDeleter calls doDeleteFile().
#
# FileDeleter can only delete one file at a time. If you wish to delete
# several files, loop over them asynchronously in `onStop`.
#
# Arguments:
#
# * doDeleteFile: a user-supplied function. (see README)
# * callbacks:
#     * onStart: called when starting
#     * onSuccess: called when the file is deleted from the server
#     * onError: called when the file cannot be deleted from the server
#     * onStop: called after either onSuccess or onError
module.exports = class FileDeleter
  constructor: (@doDeleteFile, @callbacks = {}) ->
    @running = false

  run: (fileInfo) ->
    throw 'already running' if @running
    @running = true

    @callbacks.onStart?(fileInfo)

    @doDeleteFile(
      fileInfo,
      (=> @_onSuccess(fileInfo))
      ((errorDetail) => @_onError(fileInfo, errorDetail))
    )

  _onSuccess: (fileInfo) ->
    @callbacks.onSuccess?(fileInfo)
    @_onStop(fileInfo)

  _onError: (fileInfo, errorDetail) ->
    @callbacks.onError?(fileInfo, errorDetail)
    @_onStop(fileInfo)

  _onStop: (fileInfo) ->
    @running = false
    @callbacks.onStop?(fileInfo)
    undefined
