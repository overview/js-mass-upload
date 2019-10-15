Backbone = require('backbone')
FileDeleter = require('../../src/MassUpload/FileDeleter')

describe 'MassUpload/FileDeleter', ->
  beforeEach ->
    @spies = {}
    @spies[k] = sinon.spy() for k in [ 'onStart', 'onStop', 'onSuccess', 'onError' ]
    @doDeleteFile = sinon.spy()
    @subject = new FileDeleter(@doDeleteFile, @spies)

  it 'should not call any callbacks right away', ->
    for __, v of @spies
      expect(v).not.to.have.been.called

  describe 'on run', ->
    beforeEach ->
      date = new Date('Mon, 12 Aug 2013 13:40:08 -0400').valueOf()
      fileInfo = { name: 'file.txt', lastModified: date, loaded: 2000, total: 10000 }
      @upload = new Backbone.Model(fileInfo: fileInfo)
      @subject.run(@upload)
      [ __, @userDone ] = @doDeleteFile.lastCall?.args ? []

    it 'should call doDeleteFile with the Upload', ->
      expect(@doDeleteFile.lastCall.args[0]).to.eq(@upload)

    it 'should not allow calling run() again', ->
      expect(=> @subject.run(@upload)).to.throw('already running')

    it 'should call onStart()', ->
      expect(@spies.onStart).to.have.been.calledWith(@upload)

    it 'should pass done functions to doDeleteFile', ->
      expect(@userDone).not.to.be.undefined

    describe 'on success', ->
      beforeEach -> @userDone()

      it 'should call onSuccess()', ->
        expect(@spies.onSuccess).to.have.been.calledWith(@upload)

      it 'should call onStop()', ->
        expect(@spies.onStop).to.have.been.calledWith(@upload)

      it 'should allow calling run() again', ->
        expect(=> @subject.run(@upload)).not.to.throw('already running')

    describe 'on error', ->
      beforeEach ->
        @error = new Error('some error')
        @userDone(@error)

      it 'should call onError()', ->
        expect(@spies.onError).to.have.been.calledWith(@upload, @error)

      it 'should call onStop()', ->
        expect(@spies.onStop).to.have.been.calledWith(@upload)

      it 'should allow calling run() again', ->
        expect(=> @subject.run(@upload)).not.to.throw('already running')
