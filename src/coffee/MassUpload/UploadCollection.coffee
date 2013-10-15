define [ 'backbone', './Upload' ], (Backbone, Upload) ->
  # A collection of Upload objects.
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
  Backbone.Collection.extend
    model: Upload

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

    # Finds the next operation.
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
      firstDeleting = null
      firstUploading = null
      firstUnfinished = null
      firstUnstarted = null

      @each (upload) ->
        file = upload.get('file')
        fileInfo = upload.get('fileInfo')

        if !upload.get('error')?
          if upload.get('deleting')
            firstDeleting ||= upload
          if upload.get('uploading')
            firstUploading ||= upload
          if file && fileInfo && fileInfo.loaded < fileInfo.total
            firstUnfinished ||= upload
          if file && !fileInfo
            firstUnstarted ||= upload

      firstDeleting || firstUploading || firstUnfinished || firstUnstarted

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

      @add(toAdd)
