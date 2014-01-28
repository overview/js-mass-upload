define [ 'MassUpload/Upload' ], (Upload) ->
  describe 'MassUpload/Upload', ->
    date1 = new Date('Mon, 12 Aug 2013 10:02:54 -0400')
    date2 = new Date('Mon, 12 Aug 2013 11:02:54 -0400')

    describe 'starting with a File', ->
      file = { size: 10000, name: 'file.txt', lastModifiedDate: date1 }
      subject = undefined

      beforeEach ->
        subject = new Upload({ file: file })

      it 'should have file, fileInfo, error, uploading and deleting attributes', ->
        expect('file' of subject.attributes).toBe(true)
        expect('fileInfo' of subject.attributes).toBe(true)
        expect('uploading' of subject.attributes).toBe(true)
        expect('deleting' of subject.attributes).toBe(true)
        expect('error' of subject.attributes).toBe(true)

      it 'should have an id of the filename', ->
        expect(subject.id).toEqual('file.txt')

      it 'should have no fileInfo or error', ->
        expect(subject.get('fileInfo')).toBe(null)
        expect(subject.get('error')).toBe(null)

      it 'should have getProgress() return 0/size', ->
        expect(subject.getProgress()).toEqual({ loaded: 0, total: file.size })

      it 'should have fstatSync() return name and lastModifiedDate', ->
        expect(subject.fstatSync()).toEqual({ size: 10000, lastModifiedDate: date1 })

      describe 'updateWithProgress', ->
        beforeEach ->
          subject.set('uploading', true)
          subject.updateWithProgress({ loaded: 2000, total: 10000 })

        it 'should create a fileInfo', ->
          fileInfo = subject.get('fileInfo')
          expect(fileInfo).not.toBe(null)
          expect(fileInfo.name).toEqual(file.name)
          expect(fileInfo.lastModifiedDate).toEqual(file.lastModifiedDate)
          expect(fileInfo.total).toEqual(file.size)
          expect(fileInfo.loaded).toEqual(2000)

        it 'should have isFullyUploaded=false because loaded != total', ->
          subject.set('uploading', false)
          expect(subject.isFullyUploaded()).toBe(false)

        it 'should have getProgress() return the progress', ->
          expect(subject.getProgress()).toEqual({ loaded: 2000, total: 10000 })

    describe 'starting with a completed FileInfo', ->
      fileInfo = { loaded: 10000, total: 10000, name: 'file.txt', lastModifiedDate: date1 }
      subject = undefined

      beforeEach ->
        subject = new Upload({ fileInfo: fileInfo })

      it 'should have an id of the filename', ->
        expect(subject.id).toEqual('file.txt')

      it 'should have isFullyUploaded=true', ->
        expect(subject.isFullyUploaded()).toBe(true)

      it 'should have isFullyUploaded=false if deleting=true', ->
        subject.set('deleting', true)
        expect(subject.isFullyUploaded()).toBe(false)

    describe 'starting with an incomplete FileInfo', ->
      fileInfo = { loaded: 2000, total: 10000, name: 'file.txt', lastModifiedDate: date1 }
      subject = undefined

      beforeEach ->
        subject = new Upload({ fileInfo: fileInfo })

      it 'should have isFullyUploaded=false', ->
        expect(subject.isFullyUploaded()).toBe(false)

      it 'should have getProgress() return the progress', ->
        expect(subject.getProgress()).toEqual({ loaded: 2000, total: 10000 })

    describe 'with compatible File and FileInfo', ->
      file = { size: 10000, name: 'file.txt', lastModifiedDate: date1 }
      fileInfo = { loaded: 10000, total: 10000, name: 'file.txt', lastModifiedDate: date1 }
      subject = undefined
      beforeEach -> subject = new Upload({ file: file, fileInfo: fileInfo })

      it 'should have isFullyUploaded=true', ->
        expect(subject.isFullyUploaded()).toBe(true)

      it 'should have isFullyUploaded=false if error!=null', ->
        subject.set('error', 'an error')
        expect(subject.isFullyUploaded()).toBe(false)

      it 'should have isFullyUploaded=false if uploading=true', ->
        subject.set('uploading', true)
        expect(subject.isFullyUploaded()).toBe(false)

    describe 'with incompatible File and FileInfo', ->
      file = { size: 12000, name: 'file.txt', lastModifiedDate: date2 }
      fileInfo = { loaded: 10000, total: 10000, name: 'file.txt', lastModifiedDate: date1 }
      subject = undefined
      beforeEach -> subject = new Upload({ file: file, fileInfo: fileInfo })

      it 'should have getProgress() return the file progress, not the fileInfo progress', ->
        expect(subject.getProgress()).toEqual({ loaded: 0, total: 12000 })

    describe 'hasConflict', ->
      subject = undefined
      init = (file, fileInfo) -> subject = new Upload({ file: file, fileInfo: fileInfo })

      it 'should be false when File and FileInfo match', ->
        init(
          { size: 10000, name: 'file.txt', lastModifiedDate: date1 },
          { loaded: 10000, total: 10000, name: 'file.txt', lastModifiedDate: date1 }
        )
        expect(subject.hasConflict()).toBe(false)

      it 'should be true when size is different', ->
        init(
          { size: 10003, name: 'file.txt', lastModifiedDate: date1 },
          { loaded: 10000, total: 10000, name: 'file.txt', lastModifiedDate: date1 }
        )
        expect(subject.hasConflict()).toBe(true)

      it 'should be true when lastModifiedDate is different', ->
        init(
          { size: 10000, name: 'file.txt', lastModifiedDate: date2 },
          { loaded: 10000, total: 10000, name: 'file.txt', lastModifiedDate: date1 }
        )
        expect(subject.hasConflict()).toBe(true)
