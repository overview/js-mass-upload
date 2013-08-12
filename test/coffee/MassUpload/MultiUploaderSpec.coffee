define [ 'MassUpload/MultiUploader' ], (MultiUploader) ->
  describe 'MassUpload/MultiUploader', ->
    spies = undefined
    subject = undefined
    doUpload = undefined

    beforeEach ->
      spies = {}
      spies[k] = jasmine.createSpy() for k in [
        'onAbort'
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
      userAbort = undefined
      userProgress = undefined
      userSuccess = undefined
      userError = undefined

      beforeEach ->
        uploads = [
          { file: { name: 'file1', size: 1000 }, fileInfo: null }
          { file: { name: 'file2', size: 4000 }, fileInfo: null }
        ]
        userAbort = jasmine.createSpy()
        doUpload.andReturn(userAbort)
        subject = new MultiUploader(uploads, doUpload, spies)
        subject.run()
        [ __, userProgress, userSuccess, userError ] = doUpload.mostRecentCall?.args ? []

      it 'should call doUpload with the first file', ->
        expect(doUpload.mostRecentCall.args[0]).toEqual(uploads[0].file)

      it 'should call onSingleStart(upload)', ->
        expect(spies.onSingleStart).toHaveBeenCalledWith(uploads[0])

      describe 'on abort when abort is a function', ->
        beforeEach ->
          subject.abort()

        it 'should call the user abort method', ->
          expect(userAbort).toHaveBeenCalled()

        it 'should do nothing on second abort', ->
          subject.abort()
          expect(userAbort.calls.length).toEqual(1)

        it 'should call onAbort()', ->
          expect(spies.onAbort).toHaveBeenCalled()

        it 'should call onSingleSuccess(upload), onSingleStop(upload), onSuccess() and onStop() on success', ->
          userSuccess()
          expect(spies.onSingleSuccess).toHaveBeenCalledWith(uploads[0])
          expect(spies.onSingleStop).toHaveBeenCalledWith(uploads[0])
          expect(spies.onSuccess).toHaveBeenCalledWith()
          expect(spies.onStop).toHaveBeenCalledWith()

        it 'should not doUpload again on success', ->
          userSuccess()
          expect(doUpload.calls.length).toEqual(1)

        it 'should call onSingleError(upload), onSingleStop(upload), onErrors() and onStop() on error', ->
          userError('aborting')
          expect(spies.onSingleError).toHaveBeenCalledWith(uploads[0], 'aborting')
          expect(spies.onSingleStop).toHaveBeenCalledWith(uploads[0])
          expect(spies.onErrors).toHaveBeenCalledWith([ { upload: uploads[0], detail: 'aborting' } ])
          expect(spies.onStop).toHaveBeenCalledWith()

        it 'should not allow running while aborting', ->
          expect(-> subject.run()).toThrow('already running')

        it 'should allow running after abort is complete', ->
          userSuccess()
          expect(-> subject.run()).not.toThrow()

      describe 'on single file progress', ->
        beforeEach ->
          userProgress({ loaded: 100, total: 1000 })

        it 'should call onSingleProgress(upload, progressEvent)', ->
          expect(spies.onSingleProgress).toHaveBeenCalledWith(uploads[0], { loaded: 100, total: 1000 })

        it 'should call onProgress(progressEvent)', ->
          expect(spies.onProgress).toHaveBeenCalledWith({ loaded: 100, total: 5000 })

        it 'should not accumulate loaded', ->
          uploads[0].fileInfo = { loaded: 100, total: 1000 }
          userProgress({ loaded: 150, total: 1000 })
          expect(spies.onProgress).toHaveBeenCalledWith({ loaded: 150, total: 5000 })

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

    describe 'on abort when abort is not a function', ->
      uploads = undefined
      userProgress = undefined
      userSuccess = undefined
      userError = undefined

      beforeEach ->
        uploads = [
          { file: { name: 'file1', size: 1000 }, fileInfo: null }
          { file: { name: 'file2', size: 4000 }, fileInfo: null }
        ]
        userAbort = 'some stupid return value'
        doUpload.andReturn(userAbort)
        subject = new MultiUploader(uploads, doUpload, spies)
        subject.run()
        [ __, userProgress, userSuccess, userError ] = doUpload.mostRecentCall?.args ? []
        subject.abort()

      it 'should not error (by trying to call the function that is not a function)', ->
        expect(true).toBe(true)

      it 'should call onStop() when this upload is done', ->
        userSuccess()
        expect(spies.onStop).toHaveBeenCalled()

      it 'should not run subsequent uploads', ->
        userSuccess()
        expect(doUpload.calls.length).toEqual(1)
