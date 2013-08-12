define [ 'MassUpload/FileDeleter' ], (FileDeleter) ->
  describe 'MassUpload/FileDeleter', ->
    spies = undefined
    doDeleteFile = undefined
    subject = undefined

    beforeEach ->
      spies = {}
      spies[k] = jasmine.createSpy() for k in [ 'onStart', 'onStop', 'onSuccess', 'onError' ]
      doDeleteFile = jasmine.createSpy()
      subject = new FileDeleter(doDeleteFile, spies)

    it 'should not call any callbacks right away', ->
      for __, v of spies
        expect(v).not.toHaveBeenCalled()

    describe 'on run', ->
      date = new Date('Mon, 12 Aug 2013 13:40:08 -0400')
      fileInfo = { name: 'file.txt', lastModifiedDate: date, loaded: 2000, total: 10000 }
      userSuccess = undefined
      userError = undefined

      beforeEach ->
        subject.run(fileInfo)
        [ __, userSuccess, userError ] = doDeleteFile.mostRecentCall?.args ? []

      it 'should call doDeleteFile with the file info', ->
        expect(doDeleteFile.mostRecentCall.args[0]).toBe(fileInfo)

      it 'should not allow calling run() again', ->
        expect(-> subject.run(fileInfo)).toThrow('already running')

      it 'should call onStart()', ->
        expect(spies.onStart).toHaveBeenCalledWith(fileInfo)

      it 'should pass success and error functions to doDeleteFile', ->
        expect(userSuccess).toBeDefined()
        expect(userError).toBeDefined()

      describe 'on success', ->
        beforeEach -> userSuccess()

        it 'should call onSuccess()', ->
          expect(spies.onSuccess).toHaveBeenCalledWith(fileInfo)

        it 'should call onStop()', ->
          expect(spies.onStop).toHaveBeenCalledWith(fileInfo)

        it 'should allow calling run() again', ->
          expect(-> subject.run(fileInfo)).not.toThrow('already running')

      describe 'on error', ->
        beforeEach -> userError('error')

        it 'should call onError()', ->
          expect(spies.onError).toHaveBeenCalledWith(fileInfo, 'error')

        it 'should call onStop()', ->
          expect(spies.onStop).toHaveBeenCalledWith(fileInfo)

        it 'should allow calling run() again', ->
          expect(-> subject.run(fileInfo)).not.toThrow('already running')
