define [ 'MassUpload/FileLister' ], (FileLister) ->
  describe 'MassUpload/FileLister', ->
    spies = undefined
    doListFiles = undefined
    subject = undefined

    beforeEach ->
      spies = {}
      spies[k] = jasmine.createSpy() for k in [ 'onStart', 'onStop', 'onProgress', 'onSuccess', 'onError' ]
      doListFiles = jasmine.createSpy()
      subject = new FileLister(doListFiles, spies)

    it 'should not call any callbacks right away', ->
      for __, v of spies
        expect(v).not.toHaveBeenCalled()

    describe 'on run', ->
      userSuccess = undefined
      userError = undefined
      userProgress = undefined

      beforeEach ->
        subject.run()
        [ userProgress, userSuccess, userError ] = doListFiles.mostRecentCall?.args ? []

      it 'should throw an error if run() is called when already running', ->
        expect(-> subject.run()).toThrow()

      it 'should call onStart', ->
        expect(spies.onStart).toHaveBeenCalledWith()

      it 'should call doListFiles', ->
        expect(doListFiles).toHaveBeenCalled()

      it 'should pass progress, success and error functions to doListFiles', ->
        expect(userProgress).toBeDefined()
        expect(userSuccess).toBeDefined()
        expect(userError).toBeDefined()

      describe 'on progress', ->
        beforeEach ->
          userProgress({ loaded: 10, total: 100 })

        it 'should call onProgress()', ->
          expect(spies.onProgress).toHaveBeenCalledWith({ loaded: 10, total: 100 })

      describe 'on success', ->
        beforeEach ->
          # we don't need real FileInfo objects...
          userSuccess([ 'fileInfo...' ])

        it 'should call onSuccess()', ->
          expect(spies.onSuccess).toHaveBeenCalledWith([ 'fileInfo...' ])

        it 'should call onStop()', ->
          expect(spies.onStop).toHaveBeenCalledWith()

        it 'should allow running again', ->
          expect(-> subject.run()).not.toThrow()

      describe 'on error', ->
        beforeEach ->
          userError('an error')

        it 'should call onError()', ->
          expect(spies.onError).toHaveBeenCalledWith('an error')

        it 'should call onStop()', ->
          expect(spies.onStop).toHaveBeenCalledWith()

        it 'should allow running again', ->
          expect(-> subject.run()).not.toThrow()
