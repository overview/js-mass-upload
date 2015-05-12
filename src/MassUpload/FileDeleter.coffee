# Deletes files from the server.
#
# Usage:
#
#   fileDeleter = new FileDeleter(doDeleteFile, {
#     onStart: (upload) ->
#     onSuccess: (upload) ->
#     onError: (upload, error) ->
#     onStop: (upload) ->
#   })
#   fileDeleter.run(upload)
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

  run: (upload) ->
    throw 'already running' if @running
    @running = true

    @callbacks.onStart?(upload)

    @doDeleteFile(
      upload,
      ((error) => if error then @_onError(upload, error) else @_onSuccess(upload))
    )

  _onSuccess: (upload) ->
    @callbacks.onSuccess?(upload)
    @_onStop(upload)

  _onError: (upload, error) ->
    @callbacks.onError?(upload, error)
    @_onStop(upload)

  _onStop: (upload) ->
    @running = false
    @callbacks.onStop?(upload)
    undefined
