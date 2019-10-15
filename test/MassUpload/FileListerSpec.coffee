FileLister = require('../../src/MassUpload/FileLister')

describe 'MassUpload/FileLister', ->
  beforeEach ->
    @spies = {}
    @spies[k] = sinon.spy() for k in [ 'onStart', 'onStop', 'onProgress', 'onSuccess', 'onError' ]
    @doListFiles = sinon.spy()
    @subject = new FileLister(@doListFiles, @spies)

  it 'should not call any callbacks right away', ->
    for __, v of @spies
      expect(v).not.to.have.been.called

  describe 'on run', ->
    beforeEach ->
      @subject.run()
      [ @userProgress, @userDone ] = @doListFiles.lastCall?.args ? []

    it 'should throw an error if run() is called when already running', ->
      expect(=> @subject.run()).to.throw

    it 'should call onStart', ->
      expect(@spies.onStart).to.have.been.called

    it 'should call doListFiles', ->
      expect(@doListFiles).to.have.been.called

    it 'should pass progress and done functions to doListFiles', ->
      expect(@userProgress).not.to.be.undefined
      expect(@userDone).not.to.be.undefined

    describe 'on progress', ->
      beforeEach ->
        @userProgress({ loaded: 10, total: 100 })

      it 'should call onProgress()', ->
        expect(@spies.onProgress).to.have.been.calledWith({ loaded: 10, total: 100 })

    describe 'on success', ->
      beforeEach ->
        # we don't need real FileInfo objects...
        @userDone(null, [ 'fileInfo...' ])

      it 'should call onSuccess()', ->
        expect(@spies.onSuccess).to.have.been.calledWith([ 'fileInfo...' ])

      it 'should call onStop()', ->
        expect(@spies.onStop).to.have.been.calledWith()

      it 'should allow running again', ->
        expect(=> @subject.run()).not.to.throw

    describe 'on error', ->
      beforeEach ->
        @error = new Error('an error')
        @userDone(@error)

      it 'should call onError()', ->
        expect(@spies.onError).to.have.been.calledWith(@error)

      it 'should call onStop()', ->
        expect(@spies.onStop).to.have.been.calledWith()

      it 'should allow running again', ->
        expect(=> @subject.run()).not.to.throw
