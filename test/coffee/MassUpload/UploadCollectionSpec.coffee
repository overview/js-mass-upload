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

    describe 'addFiles() when file does not exist', ->
      beforeEach -> subject.addFiles([ file1, file2 ])

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

    describe 'addFiles() when an un-uploaded file already exists', ->
      file1 = { name: 'file1.txt', lastModifiedDate: date1, size: 10000 }

      beforeEach ->
        subject.addFiles([ file1 ])
        subject.addFiles([ file1 ])

      it 'should not duplicate the file', ->
        expect(subject.length).toEqual(1)

    describe 'addFileInfos() when fileInfo does not exist', ->
      beforeEach -> subject.addFileInfos([fileInfo1])

      it 'should create Upload objects', ->
        expect(subject.length).toEqual(1)
        upload1 = subject.models[0]
        expect(upload1.attributes.file).toBe(null)
        expect(upload1.attributes.fileInfo).toBe(fileInfo1)
        expect(upload1.attributes.error).toBe(null)

      it 'should not re-add existing fileInfos', ->
        subject.addFileInfos([fileInfo1])
        expect(subject.length).toEqual(1)

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

    describe 'next', ->
      it 'should return null on empty collection', ->
        uploads = new UploadCollection([])
        expect(uploads.next()).toBe(null)

      it 'should return null if all files are uploaded', ->
        uploads = new UploadCollection([
          { file: file1, fileInfo: _.defaults({ loaded: file1.size }, fileInfo1), error: null }
        ])
        expect(uploads.next()).toBe(null)

      it 'should return null if an unfinished file was not selected by the user', ->
        uploads = new UploadCollection([
          { file: null, fileInfo: fileInfo1, error: null }
        ])
        expect(uploads.next()).toBe(null)

      it 'should return null if all files have errors', ->
        uploads = new UploadCollection([
          { file: file1, fileInfo: fileInfo1, error: 'error' }
        ])
        expect(uploads.next()).toBe(null)

      it 'should return an un-uploaded file', ->
        upload = { file: file1, fileInfo: fileInfo1, error: null }
        uploads = new UploadCollection([ upload ])
        expect(uploads.next()).toBe(uploads.get('file1.txt'))

      it 'should return a deleting file ahead of an uploading file', ->
        uploads = new UploadCollection([
          { file: file1, fileInfo: fileInfo1, uploading: true, error: null }
          { file: file2, fileInfo: fileInfo2, deleting: true, error: null }
        ])
        expect(uploads.next()).toBe(uploads.get('file2.txt'))

      it 'should return an uploading file ahead of an unfinished file', ->
        uploads = new UploadCollection([
          { file: file1, fileInfo: fileInfo1, error: null }
          { file: file2, fileInfo: fileInfo2, uploading: true, error: null }
        ])
        expect(uploads.next()).toBe(uploads.get('file2.txt'))

      it 'should return an unfinished file ahead of an unstarted file', ->
        uploads = new UploadCollection([
          { file: file1, fileInfo: null, error: null }
          { file: file2, fileInfo: fileInfo2, error: null }
        ])
        expect(uploads.next()).toBe(uploads.get('file2.txt'))

      it 'should return files in collection order', ->
        uploads = new UploadCollection([
          { file: file2, fileInfo: null, error: null }
          { file: file1, fileInfo: null, error: null }
        ])
        expect(uploads.next()).toBe(uploads.get('file2.txt'))
