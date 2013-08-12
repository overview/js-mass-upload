define [ 'MassUpload/FileUploader' ], (FileUploader) ->
  describe 'MassUpload/FileUploader', ->
    spies = undefined
    subject = undefined
    doUpload = undefined

    beforeEach ->
      spies = {}
      spies[k] = jasmine.createSpy() for k in [
        'onStart'
        'onStop'
        'onProgress'
        'onSuccess'
        'onError'
      ]
      doUpload = jasmine.createSpy()
      subject = new FileUploader(doUpload, spies)

    describe 'abort', ->
      it 'should do nothing if not running', ->
        expect(-> subject.abort()).not.toThrow()

    describe 'run', ->
      file = { name: 'file1', size: 1000, lastModifiedDate: null }
      userAbort = undefined
      userProgress = undefined
      userSuccess = undefined
      userError = undefined

      beforeEach ->
        userAbort = jasmine.createSpy()
        doUpload.andReturn(userAbort)
        subject.run(file)
        [ __, userProgress, userSuccess, userError ] = doUpload.mostRecentCall?.args ? []

      it 'should call doUpload with the file', ->
        expect(doUpload.mostRecentCall.args[0]).toEqual(file)

      it 'should call onStart(file)', ->
        expect(spies.onStart).toHaveBeenCalledWith(file)

      describe 'on abort when abort is a function', ->
        beforeEach ->
          subject.abort()

        it 'should call the user abort method', ->
          expect(userAbort).toHaveBeenCalled()

        it 'should do nothing on second abort', ->
          subject.abort()
          expect(userAbort.calls.length).toEqual(1)

        it 'should call onSuccess(file) and onStop(file) on success', ->
          userSuccess()
          expect(spies.onSuccess).toHaveBeenCalledWith(file)
          expect(spies.onStop).toHaveBeenCalledWith(file)

        it 'should call onError(file) and onStop(file) on error', ->
          userError('aborting')
          expect(spies.onError).toHaveBeenCalledWith(file, 'aborting')
          expect(spies.onStop).toHaveBeenCalledWith(file)

        it 'should not allow running while aborting', ->
          expect(-> subject.run('new file')).toThrow('already running')

        it 'should allow running after abort is complete', ->
          userSuccess()
          expect(-> subject.run('new file')).not.toThrow('already running')

      it 'should call onProgress(file, progressEvent) on progress', ->
        userProgress({ loaded: 100, total: 1000 })
        expect(spies.onProgress).toHaveBeenCalledWith(file, { loaded: 100, total: 1000 })

    describe 'on abort when abort is not a function', ->
      file = { name: 'file1', size: 1000, lastModifiedDate: null }
      userProgress = undefined
      userSuccess = undefined
      userError = undefined

      beforeEach ->
        userAbort = 'some stupid return value'
        doUpload.andReturn(userAbort)
        subject.run(file)
        [ __, userProgress, userSuccess, userError ] = doUpload.mostRecentCall?.args ? []
        subject.abort()

      it 'should not error (by trying to call the function that is not a function)', ->
        expect(true).toBe(true)

      it 'should call onStop() when this file is done', ->
        userSuccess()
        expect(spies.onStop).toHaveBeenCalledWith(file)
