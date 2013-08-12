define [ 'MassUpload' ], (MassUpload) ->
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
        for k in [ 'onStart', 'onStop', 'onSuccess', 'onError' ]
          expect(subject.lister.callbacks[k]).toBeDefined()

      it 'should set callbacks on uploader', ->
        subject = new MassUpload()
        for k in [ 'onStartAbort', 'onSingleStart', 'onSingleStop', 'onSingleProgress', 'onSingleSuccess', 'onSingleError', 'onStart', 'onStop', 'onProgress', 'onSuccess', 'onErrors' ]
          expect(subject.uploader.callbacks[k]).toBeDefined()

      it 'should set callbacks on deleter', ->
        subject = new MassUpload()
        for k in [ 'onStart', 'onStop', 'onSuccess', 'onError' ]
          expect(subject.deleter.callbacks[k]).toBeDefined()

      it 'should allow user-set uploads, lister, uploader and deleter, for testing', ->
        attrs = [ 'uploads', 'lister', 'uploader', 'deleter' ]
        options = {}
        options[attr] = attr for attr in attrs
        subject = new MassUpload(options)
        for attr in attrs
          expect(subject[attr]).toEqual(options[attr])
