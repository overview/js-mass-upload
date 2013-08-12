define [ 'MassUpload', 'backbone' ], (MassUpload, Backbone) ->
  date1 = new Date('Mon, 12 Aug 2013 14:43:17 -0400')
  date2 = new Date('Mon, 12 Aug 2013 15:43:17 -0400')

  file1 = { name: 'file1.txt', size: 10000, lastModifiedDate: date1 }
  file2 = { name: 'file2.txt', size: 20000, lastModifiedDate: date1 }
  fileInfo1 = { name: 'file1.txt', loaded: 1000, total: 10000, lastModifiedDate: date1 }
  fileInfo2 = { name: 'file2.txt', loaded: 2000, total: 20000, lastModifiedDate: date1 }
  conflictFile = { name: 'conflicting-file.txt', size: 30000, lastModifiedDate: date1 }
  conflictFileInfo = { name: 'conflicting-file.txt', loaded: 3000, total: 30000, lastModifiedDate: date2 }

  FakeUpload = Backbone.Model.extend
    initialize: (attributes) ->
      fileLike = attributes.file ? attributes.fileInfo
      @set('id', fileLike.name)

    updateWithProgress: ->
      @updateWithProgressArguments = Array.prototype.slice.call(arguments)

  FakeUploads = Backbone.Collection.extend
    model: FakeUpload

  describe 'MassUpload', ->
    options = undefined
    subject = undefined

    describe 'constructor', ->
      beforeEach ->
        options =
          doListFiles: jasmine.createSpy()
          doUploadFile: jasmine.createSpy()
          doDeleteFile: jasmine.createSpy()
          onUploadConflictingFile: jasmine.createSpy()

      it 'should set uploads, lister, uploader and deleter to default implementations', ->
        subject = new MassUpload()
        expect(subject.uploads).toBeDefined()
        expect(subject.lister).toBeDefined()
        expect(subject.uploader).toBeDefined()
        expect(subject.deleter).toBeDefined()

      it 'should set callbacks on lister', ->
        subject = new MassUpload()
        for k in [ 'onStart', 'onStop', 'onProgress', 'onSuccess', 'onError' ]
          expect(subject.lister.callbacks[k]).toBeDefined()

      it 'should set callbacks on uploader', ->
        subject = new MassUpload()
        for k in [ 'onStartAbort', 'onSingleStart', 'onSingleStop', 'onSingleProgress', 'onSingleSuccess', 'onSingleError', 'onStart', 'onStop', 'onProgress', 'onSuccess', 'onErrors' ]
          expect(subject.uploader.callbacks[k]).toBeDefined()

      it 'should set callbacks on deleter', ->
        subject = new MassUpload()
        for k in [ 'onStart', 'onStop', 'onSuccess', 'onError' ]
          expect(subject.deleter.callbacks[k]).toBeDefined()

      it 'should allow user-set lister, uploader and deleter, for testing', ->
        attrs = [ 'lister', 'uploader', 'deleter' ]
        options = {}
        options[attr] = attr for attr in attrs
        subject = new MassUpload(options)
        for attr in attrs
          expect(subject[attr]).toEqual(options[attr])

      it 'should allow user-set uploads, for testing', ->
        options = { uploads: new FakeUploads() }
        subject = new MassUpload(options)
        expect(subject.uploads).toBe(options.uploads)

    describe 'with dependencies mocked', ->
      uploads = undefined
      uploader = undefined
      lister = undefined
      deleter = undefined

      beforeEach ->
        uploads = new FakeUploads()
        uploads.addFileInfos = jasmine.createSpy()
        uploads.addFiles = jasmine.createSpy()
        uploader = { run: jasmine.createSpy(), abort: jasmine.createSpy() }
        lister = { run: jasmine.createSpy() }
        deleter = { run: jasmine.createSpy() }

        options = {
          uploads: uploads
          uploader: uploader
          lister: lister
          deleter: deleter
        }
        subject = new MassUpload(options)

      describe 'starting empty', ->
        it 'should have status=empty', ->
          expect(subject.get('status')).toEqual('empty')

      describe 'when listing files', ->
        beforeEach ->
          lister.run.andCallFake(-> lister.callbacks.onStart())
          subject.fetchFileInfosFromServer()

        it 'should call lister.run', ->
          expect(lister.run).toHaveBeenCalledWith()

        it 'should have status=listing-files', ->
          expect(subject.get('status')).toEqual('listing-files')

        describe 'on success', ->
          fileInfos = [ { name: 'file.txt', total: 10000, loaded: 1000, lastModifiedDate: date1 } ]

          beforeEach ->
            lister.callbacks.onSuccess(fileInfos)
            lister.callbacks.onStop()

          it 'should add to uploads', ->
            expect(uploads.addFileInfos).toHaveBeenCalledWith(fileInfos)

        describe 'on progress', ->
          progress = { loaded: 1000, total: 10000 }

          beforeEach -> lister.callbacks.onProgress(progress)

          it 'should set listFilesProgress', ->
            expect(subject.get('listFilesProgress')).toEqual(progress)

        describe 'on error', ->
          beforeEach ->
            lister.callbacks.onError('error')
            lister.callbacks.onStop()

          it 'should set status=listing-files-error', ->
            expect(subject.get('status')).toEqual('listing-files-error')

          it 'should set listFilesError', ->
            expect(subject.get('listFilesError')).toEqual('error')

          it 'should allow retryListFiles()', ->
            subject.retryListFiles()
            expect(subject.get('status')).toEqual('listing-files')
            expect(subject.get('listFilesError')).toBe(null)

      describe 'starting with uploads from the server', ->
        beforeEach ->
          subject.uploads.reset([
            { file: null, fileInfo: fileInfo1, error: null }
            { file: null, fileInfo: fileInfo2, error: null }
          ]) 
          subject.set('status', 'empty')

        describe 'when adding files', ->
          beforeEach -> subject.addFiles([file1])

          it 'should call uploads.addFiles', ->
            expect(subject.uploads.addFiles).toHaveBeenCalledWith([file1])

          describe 'and merge happens', ->
            # That is, when uploads.addFiles() does its thing
            beforeEach -> subject.uploads.at(0).set({ file: file1 })

            it 'should call uploader.run', ->
              expect(uploader.run).toHaveBeenCalledWith(subject.uploads.toJSON())

            describe 'when uploader.run is called', ->
              beforeEach ->
                uploader.callbacks.onStart.call()

              it 'should set status=uploading', ->
                expect(subject.get('status')).toEqual('uploading')

      describe 'when uploading', ->
        beforeEach ->
          subject.uploads.reset([
            { file: file1, fileInfo: fileInfo1, error: null }
            { file: null, fileInfo: fileInfo2, error: 'previous error' }
          ]) 
          uploader.callbacks.onStart.call()

        it 'should set progress on progress', ->
          uploader.callbacks.onSingleProgress(file1, { loaded: 1400, total: 10000 })
          expect(uploads.at(0).updateWithProgressArguments).toEqual([{ loaded: 1400, total: 10000 }])

        it 'should set uploading on start', ->
          uploader.callbacks.onSingleStart(file1)
          expect(uploads.at(0).get('uploading')).toBe(true)

        it 'should unset error on start', ->
          uploader.callbacks.onSingleStart(file2)
          expect(uploads.at(1).get('error')).toBe(null)

        it 'should unset uploading on stop', ->
          uploader.callbacks.onSingleStop(file1)
          expect(uploads.at(0).get('uploading')).toBe(false)

        it 'should set upload error on error', ->
          uploader.callbacks.onSingleError(file1, 'error')
          expect(uploads.at(0).get('error')).toEqual('error')

        it 'should not crash on success', ->
          expect(-> uploader.callbacks.onSingleSuccess(file1)).not.toThrow()

        describe 'when adding a file', ->
          beforeEach ->
            subject.uploads.at(1).set('file', file2)

          it 'should abort uploading', ->
            expect(uploader.abort).toHaveBeenCalled()

          describe 'when abort is complete', ->
            beforeEach ->
              uploader.callbacks.onStop()

            it 'should start uploading again', ->
              expect(uploader.run).toHaveBeenCalledWith(uploads.toJSON())

        describe 'when deleting a file', ->
          uploadToDelete = undefined

          beforeEach ->
            uploadToDelete = subject.uploads.at(0)
            subject.removeUpload(uploadToDelete)

          it 'should abort uploading', ->
            expect(uploader.abort).toHaveBeenCalled()

          describe 'when abort is complete', ->
            beforeEach ->
              deleter.run.andCallFake(-> deleter.callbacks.onStart(uploadToDelete))
              uploader.callbacks.onStop()

            it 'should call deleter.run()', ->
              expect(deleter.run).toHaveBeenCalledWith(uploadToDelete)

            describe 'when delete is complete', ->
              beforeEach ->
                deleter.callbacks.onSuccess(uploadToDelete)
                deleter.callbacks.onStop(uploadToDelete)

              it 'should remove the upload from the list', ->
                expect(uploads.length).toEqual(1)

              it 'should continue with uploading', ->
                expect(uploader.run).toHaveBeenCalledWith(uploads.toJSON())

            describe 'when delete fails', ->
              beforeEach ->
                deleter.callbacks.onError(uploadToDelete, 'error')
                deleter.callbacks.onStop(uploadToDelete)

              it 'should keep the upload in the list', ->
                expect(uploads.length).toEqual(2)

              it 'should set error and keep deleting=true', ->
                expect(uploadToDelete.get('deleting')).toBe(true)
                expect(uploadToDelete.get('error')).toEqual('error')

              it 'should continue with uploading', ->
                expect(uploader.run).toHaveBeenCalledWith(uploads.toJSON())
