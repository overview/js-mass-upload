define [ 'MassUpload', 'backbone' ], (MassUpload, Backbone) ->
  date1 = new Date('Mon, 12 Aug 2013 14:43:17 -0400')
  date2 = new Date('Mon, 12 Aug 2013 15:43:17 -0400')

  file1 = { name: 'file1.txt', size: 10000, lastModifiedDate: date1 }
  file2 = { name: 'file2.txt', size: 20000, lastModifiedDate: date1 }
  file3 = { name: 'file3.txt', size: 30000, lastModifiedDate: date1 }
  fileInfo1 = { name: 'file1.txt', loaded: 1000, total: 10000, lastModifiedDate: date1 }
  fileInfo2 = { name: 'file2.txt', loaded: 2000, total: 20000, lastModifiedDate: date1 }
  conflictFile = { name: 'conflicting-file.txt', size: 30000, lastModifiedDate: date1 }
  conflictFileInfo = { name: 'conflicting-file.txt', loaded: 3000, total: 30000, lastModifiedDate: date2 }

  FakeUpload = Backbone.Model.extend
    initialize: (attributes) ->
      fileLike = attributes.file ? attributes.fileInfo
      @set('id', fileLike.name)

    updateWithProgress: ->
      @set('updateWithProgressArguments', Array.prototype.slice.call(arguments))

    getProgress: ->
      if (args = @get('updateWithProgressArguments'))? && args.length
        args[0]
      else if (fileInfo = @get('fileInfo'))?
        { loaded: fileInfo.loaded, total: fileInfo.total }
      else if (file = @get('file'))?
        { loaded: 0, total: file.size }

  FakeUploads = Backbone.Collection.extend
    model: FakeUpload

    next: -> @find((model) -> model.get('deleting') || (model.get('file')? && !model.get('error')?))

  describe 'MassUpload', ->
    options = undefined
    subject = undefined

    describe 'constructor', ->
      beforeEach ->
        options =
          doListFiles: jasmine.createSpy('doListFiles')
          doUploadFile: jasmine.createSpy('doUploadFile')
          doDeleteFile: jasmine.createSpy('doDeleteFile')
          onUploadConflictingFile: jasmine.createSpy('onUploadConflictingFile')

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
        for k in [ 'onStart', 'onStop', 'onProgress', 'onSuccess', 'onError' ]
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
        uploads.addFileInfos = jasmine.createSpy('uploads.addFileInfos')
        uploads.addFiles = jasmine.createSpy('uploads.addFiles')
        uploader = { run: jasmine.createSpy('uploader.run'), abort: jasmine.createSpy('uploader.abort') }
        lister = { run: jasmine.createSpy('lister.run') }
        deleter = { run: jasmine.createSpy('deleter.run') }

        options = {
          uploads: uploads
          uploader: uploader
          lister: lister
          deleter: deleter
        }
        subject = new MassUpload(options)

      it 'should have status=waiting to begin with', ->
        expect(subject.get('status')).toEqual('waiting')

      it 'should have uploadProgress at 0/0', ->
        expect(subject.get('uploadProgress')).toEqual({ loaded: 0, total: 0 })

      it 'should call lister.run', ->
        subject.fetchFileInfosFromServer()
        expect(lister.run).toHaveBeenCalledWith()

      describe 'when listing files', ->
        beforeEach ->
          lister.run.andCallFake(-> lister.callbacks.onStart())
          subject.fetchFileInfosFromServer()

        it 'should have status=listing-files', ->
          expect(subject.get('status')).toEqual('listing-files')

        describe 'on success', ->
          fileInfos = [ { name: 'file.txt', total: 10000, loaded: 1000, lastModifiedDate: date1 } ]

          beforeEach ->
            lister.callbacks.onSuccess(fileInfos)
            lister.callbacks.onStop()

          it 'should add to uploads', ->
            expect(uploads.addFileInfos).toHaveBeenCalledWith(fileInfos)

        it 'should set listFilesProgress on progress', ->
          progress = { loaded: 1000, total: 10000 }
          lister.callbacks.onProgress(progress)
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

        describe 'when adding files', ->
          beforeEach -> subject.addFiles([file1])

          it 'should call uploads.addFiles', ->
            expect(subject.uploads.addFiles).toHaveBeenCalledWith([file1])

          describe 'and merge happens', ->
            # That is, when uploads.addFiles() does its thing
            beforeEach -> subject.uploads.at(0).set({ file: file1 })

            it 'should call uploader.run', ->
              expect(uploader.run).toHaveBeenCalledWith(file1)

            it 'should set status=uploading when uploader.run is called', ->
              uploader.callbacks.onStart(file1)
              expect(subject.get('status')).toEqual('uploading')

      describe 'when uploading', ->
        beforeEach ->
          subject.uploads.reset([
            { file: null, fileInfo: fileInfo1, error: null }
            { file: file2, fileInfo: fileInfo2, error: null }
            { file: file3, fileInfo: null, error: 'previous error' }
          ])
          uploader.callbacks.onStart(file1)

        it 'should set progress on progress', ->
          uploader.callbacks.onProgress(file2, { loaded: 2400, total: 20000 })
          expect(uploads.at(1).get('updateWithProgressArguments')).toEqual([{ loaded: 2400, total: 20000 }])

        it 'should set uploadProgress on progress', ->
          uploader.callbacks.onProgress(file2, { loaded: 2400, total: 20000 })
          expect(subject.get('uploadProgress')).toEqual({ loaded: 3400, total: 60000 })

        it 'should set uploading on start', ->
          expect(uploads.at(0).get('uploading')).toBe(true)

        it 'should unset error on start', ->
          uploader.callbacks.onStart(file3)
          expect(uploads.at(2).get('error')).toBe(null)

        it 'should unset uploading on stop', ->
          uploader.callbacks.onStop(file1)
          expect(uploads.at(0).get('uploading')).toBe(false)

        it 'should set upload error on error', ->
          uploader.callbacks.onError(file1, 'error')
          expect(uploads.at(0).get('error')).toEqual('error')

        it 'should not crash on success', ->
          expect(-> uploader.callbacks.onSuccess(file1)).not.toThrow()

        describe 'when adding a file', ->
          beforeEach ->
            subject.uploads.at(0).set('file', file1)

          it 'should abort uploading', ->
            expect(uploader.abort).toHaveBeenCalled()

          it 'should start uploading again when abort is complete', ->
            uploader.callbacks.onStop(file2)
            expect(uploader.run).toHaveBeenCalled()
            expect(uploader.run.mostRecentCall.args[0]).toBe(file1)

        describe 'on abort', ->
          beforeEach ->
            spyOn(subject, 'prepare');
            subject.abort()

          it 'should have status=waiting', ->
            expect(subject.get('status')).toEqual('waiting')

          it 'should have uploadProgress at 0/0', ->
            expect(subject.get('uploadProgress')).toEqual({ loaded: 0, total: 0 })

          it 'has no uploads', ->
            expect(subject.uploads.at(0)).not.toBeDefined()

          it 'resets the uploader, lister, etc', ->
            expect(subject.prepare).toHaveBeenCalled()

        describe 'when deleting a file', ->
          uploadToDelete = undefined

          beforeEach ->
            uploadToDelete = uploads.at(0)
            subject.removeUpload(uploadToDelete)

          it 'should abort uploading', ->
            expect(uploader.abort).toHaveBeenCalled()

          describe 'when abort is complete', ->
            beforeEach ->
              deleter.run.andCallFake(-> deleter.callbacks.onStart(fileInfo1))
              uploader.callbacks.onStop(file2)

            it 'should call deleter.run()', ->
              expect(deleter.run).toHaveBeenCalledWith(uploadToDelete.get('fileInfo'))

            describe 'when delete is complete', ->
              beforeEach ->
                deleter.callbacks.onSuccess(fileInfo1)
                deleter.callbacks.onStop(fileInfo1)

              it 'should remove the upload from the list', ->
                expect(uploads.length).toEqual(2)

              it 'should continue with uploading', ->
                expect(uploader.run).toHaveBeenCalled()
                expect(uploader.run.mostRecentCall.args[0]).toBe(file2)

            describe 'when delete fails', ->
              beforeEach ->
                deleter.callbacks.onError(fileInfo1, 'error')
                deleter.callbacks.onStop(fileInfo1)

              it 'should keep the upload in the list', ->
                expect(uploads.length).toEqual(3)

              it 'should set error and keep deleting=true', ->
                expect(uploadToDelete.get('deleting')).toBe(true)
                expect(uploadToDelete.get('error')).toEqual('error')

              it 'should continue with uploading', ->
                expect(uploader.run).toHaveBeenCalled()

      describe 'when finishing all uploads', ->
        beforeEach ->
          uploads.reset([
            { file: file1, fileInfo: fileInfo1, error: null }
          ])
          uploader.callbacks.onStart(file1)
          uploads.next = jasmine.createSpy('uploads.next').andReturn(null)
          uploader.callbacks.onSuccess(file1)
          uploader.callbacks.onStop(file1)

        it 'should set status=waiting', ->
          expect(subject.get('status')).toEqual('waiting')

      describe 'with a broken upload', ->
        beforeEach ->
          uploads.reset([
            { file: file1, fileInfo: fileInfo1, error: 'an error' }
          ])

        it 'should have status uploading-error, even when waiting', ->
          expect(subject.get('status')).toEqual('uploading-error')

        it 'should allow retryUpload', ->
          subject.retryUpload(uploads.at(0))
          expect(uploader.run).toHaveBeenCalled()

        it 'should allow retryAllUploads', ->
          subject.retryAllUploads()
          expect(uploader.run).toHaveBeenCalled()

        it 'should have uploadErrors', ->
          expect(subject.get('uploadErrors')).toEqual([
            { upload: uploads.at(0), error: 'an error' }
          ])

      describe 'with a missing file', ->
        beforeEach ->
          uploads.reset([
            { file: null, fileInfo: fileInfo1, error: null }
          ])

        it 'should have status=waiting-error', ->
          expect(subject.get('status')).toEqual('waiting-error')
