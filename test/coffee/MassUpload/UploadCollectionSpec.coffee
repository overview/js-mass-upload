define [ 'MassUpload/UploadCollection', 'underscore' ], (UploadCollection) ->
  describe 'MassUpload/UploadCollection', ->
    date1 = new Date('Mon, 12 Aug 2013 10:02:54 -0400')
    date2 = new Date('Mon, 12 Aug 2013 11:02:54 -0400')

    file1 = { name: 'file1.txt', lastModifiedDate: date1, size: 10000 }
    file2 = { name: 'file2.txt', lastModifiedDate: date1, size: 20000 }

    fileInfo1 = { name: 'file1.txt', lastModifiedDate: date1, loaded: 2000, total: 10000 }
    fileInfo2 = { name: 'file2.txt', lastModifiedDate: date1, loaded: 3000, total: 20000 }

    subject = undefined
    beforeEach -> subject = new UploadCollection([])
    afterEach -> subject?.off()

    describe 'reset', ->
      it 'should reset to empty list without params', ->
        subject.reset()
        expect(subject.length).toEqual(0)

      it 'should return the collection', ->
        resetSpy = jasmine.createSpy('reset')
        subject.on('reset', resetSpy)
        subject.reset()
        expect(resetSpy).toHaveBeenCalledWith(subject)

    describe 'addFiles() when file does not exist', ->
      addBatchArgs = null

      beforeEach ->
        addBatchArgs = []
        subject.on('add-batch', (uploads) -> addBatchArgs.push(uploads))
        subject.addFiles([ file1, file2 ])

      afterEach ->
        subject.off('add-batch')

      it 'should create Upload objects', ->
        expect(subject.length).toEqual(2)
        upload1 = subject.models[0]
        upload2 = subject.models[1]
        expect(upload1.attributes.file).toBe(file1)
        expect(upload1.attributes.fileInfo).toBe(null)
        expect(upload1.attributes.error).toBe(null)
        expect(upload2.attributes.file).toBe(file2)
        expect(upload2.attributes.fileInfo).toBe(null)
        expect(upload2.attributes.error).toBe(null)

      it 'should trigger add-batch', ->
        expect(addBatchArgs.length).toEqual(1)
        expect(addBatchArgs[0].length).toEqual(2)
        expect(addBatchArgs[0][0].attributes.file).toBe(file1)

    describe 'addFiles() when an un-uploaded file already exists', ->
      file1 = { name: 'file1.txt', lastModifiedDate: date1, size: 10000 }
      addBatchArgs = null

      beforeEach ->
        addBatchArgs = []
        subject.on('add-batch', (uploads) -> addBatchArgs.push(uploads))
        subject.addFiles([ file1 ])
        subject.addFiles([ file1 ])

      afterEach ->
        subject.off('add-batch')

      it 'should not duplicate the file', ->
        expect(subject.length).toEqual(1)

      it 'should not trigger add-batch when merging', ->
        expect(addBatchArgs.length).toEqual(1)

    describe 'addFileInfos() when fileInfo does not exist', ->
      addBatchArgs = null

      beforeEach ->
        addBatchArgs = []
        subject.on('add-batch', (uploads) -> addBatchArgs.push(uploads))
        subject.addFileInfos([fileInfo1])

      afterEach ->
        subject.off('add-batch')

      it 'should create Upload objects', ->
        expect(subject.length).toEqual(1)
        upload1 = subject.models[0]
        expect(upload1.attributes.file).toBe(null)
        expect(upload1.attributes.fileInfo).toBe(fileInfo1)
        expect(upload1.attributes.error).toBe(null)

      it 'should not re-add existing fileInfos', ->
        subject.addFileInfos([fileInfo1])
        expect(subject.length).toEqual(1)

      it 'should trigger add-batch', ->
        expect(addBatchArgs.length).toEqual(1)
        expect(addBatchArgs[0].length).toEqual(1)
        expect(addBatchArgs[0][0].attributes.fileInfo).toBe(fileInfo1)

    describe 'with a file-backed Upload', ->
      file1 = { name: 'file1.txt', lastModifiedDate: date1, size: 10000 }
      beforeEach -> subject.addFiles([file1])

      it 'should merge a fileInfo through addFileInfos()', ->
        fileInfo1 = { name: 'file1.txt', lastModifiedDate: date1, loaded: 2000, total: 10000 }
        subject.addFileInfos([fileInfo1])
        expect(subject.length).toEqual(1)
        upload = subject.models[0]
        expect(upload.attributes.file).toBe(file1)
        expect(upload.attributes.fileInfo).toBe(fileInfo1)

    describe 'with a fileInfo-backed Upload', ->
      fileInfo1 = { name: 'file1.txt', lastModifiedDate: date1, loaded: 2000, total: 10000 }
      beforeEach -> subject.addFileInfos([fileInfo1])

      it 'should merge a file through addFiles()', ->
        file1 = { name: 'file1.txt', lastModifiedDate: date1, size: 10000 }
        subject.addFiles([file1])
        expect(subject.length).toEqual(1)
        upload = subject.models[0]
        expect(upload.attributes.file).toBe(file1)
        expect(upload.attributes.fileInfo).toBe(fileInfo1)

    describe 'forFile', ->
      it 'should search by webkitRelativePath if there is one', ->
        file =
          id: 'foo/bar.txt'
          name: 'bar.txt'
          webkitRelativePath: 'foo/bar.txt'
          lastModifiedDate: date1
          size: 10000

        subject.addFiles([ file ])
        expect(subject.forFile(file).file).toEqual(file)

      it 'should search by name if there is no webkitRelativePath', ->
        file =
          id: 'bar.txt'
          name: 'bar.txt'
          lastModifiedDate: date1
          size: 10000

        subject.addFiles([ file ])
        expect(subject.forFile(file).file).toEqual(file)

    describe 'forFileInfo', ->
      it 'should search by name', ->
        subject.addFileInfos([ fileInfo1 ])
        expect(subject.forFileInfo(fileInfo1).fileInfo).toEqual(fileInfo1)

    describe 'next', ->
      it 'should return null on empty collection', ->
        expect(subject.next()).toBe(null)

      it 'should return null if all files are uploaded', ->
        subject.reset([
          { file: file1, fileInfo: _.defaults({ loaded: file1.size }, fileInfo1), error: null }
        ])
        expect(subject.next()).toBe(null)

      it 'should return null if an unfinished file was not selected by the user', ->
        subject.reset([
          { file: null, fileInfo: fileInfo1, error: null }
        ])
        expect(subject.next()).toBe(null)

      it 'should return null if all files have errors', ->
        subject.reset([
          { file: file1, fileInfo: fileInfo1, error: 'error' }
        ])
        expect(subject.next()).toBe(null)

      it 'should return an un-uploaded file', ->
        upload = { file: file1, fileInfo: fileInfo1, error: null }
        subject.reset([ upload ])
        expect(subject.next()).toBe(subject.get('file1.txt'))

      it 'should return a deleting file ahead of an uploading file', ->
        subject.reset([
          { file: file1, fileInfo: fileInfo1, uploading: true, error: null }
          { file: file2, fileInfo: fileInfo2, deleting: true, error: null }
        ])
        expect(subject.next()).toBe(subject.get('file2.txt'))

      it 'should return an uploading file ahead of an unfinished file', ->
        subject.reset([
          { file: file1, fileInfo: fileInfo1, error: null }
          { file: file2, fileInfo: fileInfo2, uploading: true, error: null }
        ])
        expect(subject.next()).toBe(subject.get('file2.txt'))

      it 'should return an unfinished file ahead of an unstarted file', ->
        subject.reset([
          { file: file1, fileInfo: null, error: null }
          { file: file2, fileInfo: fileInfo2, error: null }
        ])
        expect(subject.next()).toBe(subject.get('file2.txt'))

      it 'should return files in collection order', ->
        subject.reset([
          { file: file2, fileInfo: null, error: null }
          { file: file1, fileInfo: null, error: null }
        ])
        expect(subject.next()).toBe(subject.get('file2.txt'))

      it 'should return a second file after the first is uploaded', ->
        subject.reset([
          { file: file1, fileInfo: null, error: null }
          { file: file2, fileInfo: null, error: null }
        ])
        subject.get('file1.txt').set(fileInfo: _.extend({}, fileInfo1, { loaded: 10000 }))
        expect(subject.next()).toBe(subject.get('file2.txt'))
