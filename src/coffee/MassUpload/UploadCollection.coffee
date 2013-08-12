define [ 'backbone', './Upload' ], (Backbone, Upload) ->
  Backbone.Collection.extend
    model: Upload

    addFiles: (files) ->
      uploads = (new Upload({ file: file }) for file in files)
      @_addWithMerge(uploads)

    addFileInfos: (fileInfos) ->
      uploads = (new Upload({ fileInfo: fileInfo }) for fileInfo in fileInfos)
      @_addWithMerge(uploads)

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
