define [ 'MassUpload/MultiUploader' ], (MultiUploader) ->
  describe 'MassUpload/MultiUploader', ->
    spies = undefined
    subject = undefined
    doUpload = undefined

    beforeEach ->
      spies = {}
      spies[k] = jasmine.createSpy() for k in [
        'onStart'
        'onStop'
        'onSingleStart'
        'onSingleProgress'
        'onSingleSuccess'
        'onSingleError'
        'onSingleStop'
        'onProgress'
        'onSuccess'
        'onErrors'
      ]
      doUpload = jasmine.createSpy()

    describe 'with no uploads', ->
      beforeEach ->
        subject = new MultiUploader([], doUpload, spies)
        subject.run()

      it 'should call onStart', ->
        expect(spies.onStart).toHaveBeenCalledWith()

      it 'should not call onSingleAnything', ->
        for k in [ 'onSingleStart', 'onSingleProgress', 'onSingleSuccess', 'onSingleError', 'onSingleStop' ]
          expect(spies[k]).not.toHaveBeenCalled()

      it 'should not call doUpload', ->
        expect(doUpload).not.toHaveBeenCalled()

      it 'should call onSuccess', ->
        expect(spies.onSuccess).toHaveBeenCalledWith()

      it 'should call onStop', ->
        expect(spies.onStop).toHaveBeenCalledWith()

      it 'should allow calling run() again', ->
        expect(-> subject.run()).not.toThrow()

    describe 'with multiple unsent uploads', ->
      uploads = undefined
      userProgress = undefined
      userSuccess = undefined
      userError = undefined

      beforeEach ->
        uploads = [
          { file: { name: 'file1', size: 1000 }, fileInfo: null }
          { file: { name: 'file2', size: 4000 }, fileInfo: null }
        ]
        subject = new MultiUploader(uploads, doUpload, spies)
        subject.run()
        [ __, userProgress, userSuccess, userError ] = doUpload.mostRecentCall?.args ? []

      it 'should call doUpload with the first file', ->
        expect(doUpload.mostRecentCall.args[0]).toEqual(uploads[0].file)

      it 'should call onSingleStart(upload)', ->
        expect(spies.onSingleStart).toHaveBeenCalledWith(uploads[0])

      describe 'on single file progress', ->
        beforeEach ->
          userProgress({ loaded: 100, total: 1000 })

        it 'should call onSingleProgress(upload, progressEvent)', ->
          expect(spies.onSingleProgress).toHaveBeenCalledWith(uploads[0], { loaded: 100, total: 1000 })

        it 'should call onProgress(progressEvent)', ->
          expect(spies.onProgress).toHaveBeenCalledWith({ loaded: 100, total: 5000 })

        it 'should create the FileInfo object when it does not exist', ->
          expect(uploads[0].fileInfo).not.toBeNull()
          expect(uploads[0].fileInfo.loaded).toEqual(100)
          expect(uploads[0].fileInfo.total).toEqual(1000)

        it 'should not accumulate loaded', ->
          userProgress({ loaded: 150, total: 1000 })
          expect(spies.onProgress).toHaveBeenCalledWith({ loaded: 150, total: 5000 })

        it 'should adjust the FileInfo object when it does exist', ->
          fileInfo = uploads[0].fileInfo
          userProgress({ loaded: 150, total: 1000 })
          expect(fileInfo.loaded).toEqual(150)

      describe 'on single file success', ->
        beforeEach ->
          userSuccess()

        it 'should fire onSingleSuccess(upload)', ->
          expect(spies.onSingleSuccess).toHaveBeenCalledWith(uploads[0])

        it 'should not call onSuccess()', ->
          expect(spies.onSuccess).not.toHaveBeenCalled()

        it 'should call doUpload() with the next file', ->
          expect(doUpload.mostRecentCall.args[0]).toEqual(uploads[1].file)

        it 'should call onSingleStop(upload)', ->
          expect(spies.onSingleStop).toHaveBeenCalledWith(uploads[0])

        it 'should call onSingleStart() with the next upload', ->
          expect(spies.onSingleStart).toHaveBeenCalledWith(uploads[1])

        it 'should ignore further calls on this upload', ->
          userSuccess()
          expect(spies.onSingleSuccess.calls.length).toEqual(1)

      describe 'on all files success', ->
        beforeEach ->
          userSuccess()
          [ __, userProgress, userSuccess, userError ] = doUpload.mostRecentCall?.args ? []
          userSuccess()

        it 'should fire onSuccess()', ->
          expect(spies.onSuccess).toHaveBeenCalled()

        it 'should fire onStop()', ->
          expect(spies.onStop).toHaveBeenCalled()

        it 'should allow calling run() again', ->
          expect(-> subject.run()).not.toThrow()

      describe 'on single file error', ->
        beforeEach ->
          userError('an error')

        it 'should fire onSingleError(upload, errorDetail)', ->
          expect(spies.onSingleError).toHaveBeenCalledWith(uploads[0], 'an error')

        it 'should fire onSingleStop(upload)', ->
          expect(spies.onSingleStop).toHaveBeenCalledWith(uploads[0])

        it 'should not call onSuccess()', ->
          expect(spies.onSuccess).not.toHaveBeenCalled()

        it 'should not call onErrors()', ->
          expect(spies.onErrors).not.toHaveBeenCalled()

        it 'should call doUpload() with the next file', ->
          expect(doUpload.mostRecentCall.args[0]).toEqual(uploads[1].file)

        it 'should call onSingleStart() with the next upload', ->
          expect(spies.onSingleStart).toHaveBeenCalledWith(uploads[1])

      describe 'finishing last file with an error', ->
        beforeEach ->
          userSuccess()
          [ __, userProgress, userSuccess, userError ] = doUpload.mostRecentCall?.args ? []
          userError('an error')

        it 'should call onErrors()', ->
          expect(spies.onErrors).toHaveBeenCalledWith([{ upload: uploads[1], detail: 'an error' }])

        it 'should call onStop()', ->
          expect(spies.onStop).toHaveBeenCalledWith()

      describe 'finishing last file with success though an error happened before', ->
        beforeEach ->
          userError('an error')
          [ __, userProgress, userSuccess, userError ] = doUpload.mostRecentCall?.args ? []
          userSuccess()

        it 'should call onErrors()', ->
          expect(spies.onErrors).toHaveBeenCalledWith([{ upload: uploads[0], detail: 'an error' }])

        it 'should call onStop()', ->
          expect(spies.onStop).toHaveBeenCalledWith()
