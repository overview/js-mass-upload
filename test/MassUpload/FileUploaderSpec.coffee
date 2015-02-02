FileUploader = require('../../src/MassUpload/FileUploader')

describe 'MassUpload/FileUploader', ->
  spies = undefined
  subject = undefined
  doUpload = undefined

  beforeEach ->
    spies = {}
    spies[k] = sinon.spy() for k in [
      'onStart'
      'onStop'
      'onProgress'
      'onSuccess'
      'onError'
    ]
    doUpload = sinon.stub()
    subject = new FileUploader(doUpload, spies)

  describe 'abort', ->
    it 'should do nothing if not running', ->
      expect(-> subject.abort()).not.to.throw

  describe 'run', ->
    file = { name: 'file1', size: 1000, lastModifiedDate: null }
    userAbort = undefined
    userProgress = undefined
    userSuccess = undefined
    userError = undefined

    beforeEach ->
      userAbort = sinon.spy()
      doUpload.returns(userAbort)
      subject.run(file)
      [ __, userProgress, userSuccess, userError ] = doUpload.lastCall?.args ? []

    it 'should call doUpload with the file', ->
      expect(doUpload.lastCall.args[0]).to.eq(file)

    it 'should call onStart(file)', ->
      expect(spies.onStart).to.have.been.calledWith(file)

    describe 'on abort when abort is a function', ->
      beforeEach ->
        subject.abort()

      it 'should call the user abort method', ->
        expect(userAbort).to.have.been.called

      it 'should do nothing on second abort', ->
        subject.abort()
        expect(userAbort.callCount).to.eq(1)

      it 'should call onSuccess(file) and onStop(file) on success', ->
        userSuccess()
        expect(spies.onSuccess).to.have.been.calledWith(file)
        expect(spies.onStop).to.have.been.calledWith(file)

      it 'should call onError(file) and onStop(file) on error', ->
        userError('aborting')
        expect(spies.onError).to.have.been.calledWith(file, 'aborting')
        expect(spies.onStop).to.have.been.calledWith(file)

      it 'should not allow running while aborting', ->
        expect(-> subject.run('new file')).to.throw('already running')

      it 'should allow running after abort is complete', ->
        userSuccess()
        expect(-> subject.run('new file')).not.to.throw('already running')

    it 'should call onProgress(file, progressEvent) on progress', ->
      userProgress({ loaded: 100, total: 1000 })
      expect(spies.onProgress).to.have.been.calledWith(file, { loaded: 100, total: 1000 })

  describe 'on abort when abort is not a function', ->
    file = { name: 'file1', size: 1000, lastModifiedDate: null }
    userProgress = undefined
    userSuccess = undefined
    userError = undefined

    beforeEach ->
      userAbort = 'some stupid return value'
      doUpload.returns(userAbort)
      subject.run(file)
      [ __, userProgress, userSuccess, userError ] = doUpload.lastCall?.args ? []
      subject.abort()

    it 'should not error (by trying to call the function that is not a function)', ->
      expect(true).to.eq(true)

    it 'should call onStop() when this file is done', ->
      userSuccess()
      expect(spies.onStop).to.have.been.calledWith(file)
