FileDeleter = require('../../src/MassUpload/FileDeleter')

describe 'MassUpload/FileDeleter', ->
  spies = undefined
  doDeleteFile = undefined
  subject = undefined

  beforeEach ->
    spies = {}
    spies[k] = sinon.spy() for k in [ 'onStart', 'onStop', 'onSuccess', 'onError' ]
    doDeleteFile = sinon.spy()
    subject = new FileDeleter(doDeleteFile, spies)

  it 'should not call any callbacks right away', ->
    for __, v of spies
      expect(v).not.to.have.been.called

  describe 'on run', ->
    date = new Date('Mon, 12 Aug 2013 13:40:08 -0400')
    fileInfo = { name: 'file.txt', lastModifiedDate: date, loaded: 2000, total: 10000 }
    userSuccess = undefined
    userError = undefined

    beforeEach ->
      subject.run(fileInfo)
      [ __, userSuccess, userError ] = doDeleteFile.lastCall?.args ? []

    it 'should call doDeleteFile with the file info', ->
      expect(doDeleteFile.lastCall.args[0]).to.eq(fileInfo)

    it 'should not allow calling run() again', ->
      expect(-> subject.run(fileInfo)).to.throw('already running')

    it 'should call onStart()', ->
      expect(spies.onStart).to.have.been.calledWith(fileInfo)

    it 'should pass success and error functions to doDeleteFile', ->
      expect(userSuccess).to.be.defined
      expect(userError).to.be.defined

    describe 'on success', ->
      beforeEach -> userSuccess()

      it 'should call onSuccess()', ->
        expect(spies.onSuccess).to.have.been.calledWith(fileInfo)

      it 'should call onStop()', ->
        expect(spies.onStop).to.have.been.calledWith(fileInfo)

      it 'should allow calling run() again', ->
        expect(-> subject.run(fileInfo)).not.to.throw('already running')

    describe 'on error', ->
      beforeEach -> userError('error')

      it 'should call onError()', ->
        expect(spies.onError).to.have.been.calledWith(fileInfo, 'error')

      it 'should call onStop()', ->
        expect(spies.onStop).to.have.been.calledWith(fileInfo)

      it 'should allow calling run() again', ->
        expect(-> subject.run(fileInfo)).not.to.throw('already running')
