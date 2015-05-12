Backbone = require('backbone')
Upload = require('./Upload')

# Helper for use with UploadCollection.next()
class UploadPriorityQueue
  constructor: ->
    @_clear()

  _clear: ->
    @deleting = []
    @uploading = []
    @unfinished = []
    @unstarted = []

  uploadAttributesToState: (uploadAttributes) ->
    ret = if uploadAttributes.error?
      null # can't do anything
    else if uploadAttributes.deleting
      'deleting'
    else if uploadAttributes.uploading
      'uploading'
    else if uploadAttributes.file? && uploadAttributes.fileInfo? && uploadAttributes.fileInfo.loaded < uploadAttributes.fileInfo.total
      'unfinished'
    else if uploadAttributes.file? && !uploadAttributes.fileInfo?
      'unstarted'
    else
      null

    ret

  addBatch: (uploads) ->
    for upload in uploads
      state = @uploadAttributesToState(upload.attributes)
      if state?
        @[state].push(upload)
    undefined

  # Removes upload from the array, if it's there; otherwise does nothing
  _removeUploadFromArray: (upload, array) ->
    idx = array.indexOf(upload)
    if idx >= 0
      array.splice(idx, 1)

  remove: (upload) ->
    state = @uploadAttributesToState(upload.attributes)
    if state?
      @_removeUploadFromArray(upload.attributes, @[state])

  change: (upload) ->
    prevState = @uploadAttributesToState(upload.previousAttributes())
    newState = @uploadAttributesToState(upload.attributes)
    if prevState != newState
      if prevState?
        @_removeUploadFromArray(upload, @[prevState])
      if newState?
        @[newState].push(upload)

  reset: (uploads = []) ->
    @_clear()
    @addBatch(uploads)

  # Returns the most important pending Upload, or `null`.
  next: ->
    @deleting[0] ? @uploading[0] ? @unfinished[0] ? @unstarted[0] ? null

# A collection of Upload objects, in the spirit of Backbone.Collection.
#
# Here's how to modify this collection:
#
# * Call addFiles(), to specify what the user wants to upload;
# * Call addFileInfos(), to specify what is already on the server;
# * Call upload.updateWithProgress() to set a new FileInfo object on it;
# * Call upload.set() to set error and other status.
#
# The upload code needs to iterate over all desired updates. The way to do
# this is to repeatedly call `next()` on this object. In synchronous terms:
#
#     while ((upload = uploadCollection.next()) != null)
#       uploader.run(upload)
#     # Of course, uploading is async, so this can't be a `while` loop.
#
# Callers may listen for the 'add-batch' event. It will be called with an
# Array of Upload elements. (This is much faster than listening to the 'add'
# event. Callers can assume 'add-batch' will be called for all additions.)
#
# To mock this collection, just use a Backbone.Collection, and have it
# trigger "add-batch" after each add.
module.exports = class UploadCollection
  @:: = Object.create(Backbone.Events)

  constructor: ->
    @models = []
    @_priorityQueue = new UploadPriorityQueue()
    @reset([])

  each: (func, context) ->
    @models.forEach(func, context)

  map: (func, context) ->
    @models.map(func, context)

  remove: (upload) ->
    index = @models.indexOf(upload)
    throw 'Upload not found' if index == -1

    upload.off('all', @_onUploadEvent, this)
    delete @_idToModel[upload.id]
    @_priorityQueue.remove(upload)
    @trigger('remove', upload, @)
    @models.splice(index, 1)
    @length = @models.length

  _prepareModel: (upload) ->
    if upload instanceof Upload
      upload
    else
      new Upload(upload)

  reset: (uploads) ->
    for upload in @models
      upload.off('all', @_onUploadEvent, this)

    @models = (@_prepareModel(upload) for upload in (uploads ? []))
    @length = @models.length

    @_idToModel = {}
    for upload in @models
      upload.on('all', @_onUploadEvent, this)
      @_idToModel[upload.id] = upload

    @_priorityQueue.reset(@models)
    @trigger('reset', @)

  # Finds the model with the given ID in the collection, or null. O(1).
  get: (id) ->
    @_idToModel[id] ? null

  forFile: (file) -> @get(file.webkitRelativePath || file.name)
  forFileInfo: (fileInfo) -> @get(fileInfo.name)

  # Adds some user-selected files to the collection.
  #
  # Files of the same name will be matched up to their server-side fileInfo
  # objects. This may lead to conflict which must be resolved by the
  # developer or user.
  addFiles: (files) ->
    uploads = (new Upload({ file: file }) for file in files)
    @_addWithMerge(uploads)

  # Adds server-side fileInfo objects to the collection.
  #
  # These will be used to populate the collection initially. Later the user
  # will specify files through `addFiles()` which may be new or may be
  # joined through their filenames to these fileInfo objects.
  addFileInfos: (fileInfos) ->
    uploads = (new Upload({ fileInfo: fileInfo }) for fileInfo in fileInfos)
    @_addWithMerge(uploads)

  # Finds the next upload to handle.
  #
  # If any deletions are pending (uploads have deleting=true), those come
  # first (because they cause user-visible lag and potentially the user is
  # feeling panicky if the deletion takes too long). Next, if we are in the
  # process of uploading we do not cancel that upload. Next, we finish any
  # incomplete uploads (alphabetically). Next, we upload files
  # alphabetically. Finally, we return `null` if there is nothing left to do.
  #
  # The intent is for the caller to upload files one at a time; it can
  # intermittently run logic like this:
  #
  #     maybeTransitionToNewUpload = () ->
  #       currentUpload = ...
  #       nextUpload = uploadCollection.next()
  #       if nextUpload !== currentUpload
  #         abortCurrentUploadAndThenTick()
  #
  #     tick = () ->
  #       upload = uploadCollection.next()
  #       if upload
  #         deleteOrUpload(upload)
  #       else
  #         doWhateverWeDoWhenThereIsNothingToSync()
  next: ->
    @_priorityQueue.next()

  # Adds an Upload or array of Uploads.
  add: (uploadOrUploads) ->
    if uploadOrUploads.length?
      @addBatch(uploadOrUploads)
    else
      @addBatch([uploadOrUploads])

  addBatch: (uploads) ->
    for upload in uploads
      @_idToModel[upload.id] = upload
      upload.on('all', @_onUploadEvent, this)
      @models.push(upload)

    @length += uploads.length

    @_priorityQueue.addBatch(uploads)
    for upload in uploads
      @trigger('add', upload)
    @trigger('add-batch', uploads)

  _onUploadEvent: (event, model, collection, options) ->
    if event != 'add' && event != 'remove'
      @trigger.apply(this, arguments)

    if event == 'change'
      @_priorityQueue.change(model)

  # Like add([...], merge: true), but it never subtracts attributes.
  #
  # In other words, _addWithMerge() will _set_ file or fileInfo on models,
  # but it will never _unset_ either property.
  _addWithMerge: (uploads) ->
    toAdd = []

    for upload in uploads
      if (existingUpload = @get(upload.id))?
        file = upload.get('file')
        fileInfo = upload.get('fileInfo')
        existingUpload.set({ file: file }) if file?
        existingUpload.set({ fileInfo: fileInfo }) if fileInfo?
      else
        toAdd.push(upload)

    if toAdd.length
      @add(toAdd)

    undefined
