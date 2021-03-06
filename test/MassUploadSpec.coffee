Backbone = require('backbone')
MassUpload = require('../src/MassUpload')

date1 = new Date('Mon, 12 Aug 2013 14:43:17 -0400').valueOf()

file1 = { name: 'file1.txt', size: 10000, lastModified: date1 }
file2 = { name: 'file2.txt', size: 20000, lastModified: date1 }
file3 = { name: 'file3.txt', size: 30000, lastModified: date1 }
fileInfo1 = { name: 'file1.txt', loaded: 1000, total: 10000, lastModified: date1 }
fileInfo2 = { name: 'file2.txt', loaded: 2000, total: 20000, lastModified: date1 }

FakeUpload = Backbone.Model.extend
  initialize: (attributes) ->
    fileLike = attributes.file ? attributes.fileInfo
    @set('id', fileLike.name)

  updateWithProgress: ->
    @set(updateWithProgressArguments: Array.prototype.slice.call(arguments))

  getProgress: ->
    if (args = @get('updateWithProgressArguments'))? && args.length
      args[0]
    else if (fileInfo = @get('fileInfo'))?
      { loaded: fileInfo.loaded, total: fileInfo.total }
    else if (file = @get('file'))?
      { loaded: 0, total: file.size }

  size: -> @get('file').size

FakeUploads = Backbone.Collection.extend
  model: FakeUpload

  forFile: (f) -> @get(f.name)
  forFileInfo: (fi) -> @get(fi.name)

  next: -> @find((model) -> model.get('deleting') || (model.get('file')? && !model.get('error')?))

describe 'MassUpload', ->
  options = undefined
  subject = undefined

  describe 'constructor', ->
    beforeEach ->
      options =
        doListFiles: sinon.stub()
        doUploadFile: sinon.stub()
        doDeleteFile: sinon.stub()
        onUploadConflictingFile: sinon.stub()

    it 'should set uploads, lister, uploader and deleter to default implementations', ->
      subject = new MassUpload()
      expect(subject.uploads).not.to.be.undefined
      expect(subject.lister).not.to.be.undefined
      expect(subject.uploader).not.to.be.undefined
      expect(subject.deleter).not.to.be.undefined

    it 'should set callbacks on lister', ->
      subject = new MassUpload()
      for k in [ 'onStart', 'onStop', 'onProgress', 'onSuccess', 'onError' ]
        expect(subject.lister.callbacks[k]).not.to.be.undefined

    it 'should set callbacks on uploader', ->
      subject = new MassUpload()
      for k in [ 'onStart', 'onStop', 'onProgress', 'onSuccess', 'onError' ]
        expect(subject.uploader.callbacks[k]).not.to.be.undefined

    it 'should set callbacks on deleter', ->
      subject = new MassUpload()
      for k in [ 'onStart', 'onStop', 'onSuccess', 'onError' ]
        expect(subject.deleter.callbacks[k]).not.to.be.undefined

    it 'should allow user-set lister, uploader and deleter, for testing', ->
      lister = {}
      uploader = {}
      deleter = {}
      options = { lister: lister, uploader: uploader, deleter: deleter }
      subject = new MassUpload(options)
      expect(subject.lister).to.equal(lister)
      expect(subject.uploader).to.equal(uploader)
      expect(subject.deleter).to.equal(deleter)

    it 'should allow user-set uploads, for testing', ->
      options = { uploads: new FakeUploads() }
      subject = new MassUpload(options)
      expect(subject.uploads).to.eq(options.uploads)

  describe 'with dependencies mocked', ->
    uploads = undefined
    uploader = undefined
    lister = undefined
    deleter = undefined

    beforeEach ->
      uploads = new FakeUploads()
      uploads.addFileInfos = sinon.stub()
      uploads.addFiles = sinon.stub()
      uploader = { run: sinon.spy(), abort: sinon.spy() }
      lister = { run: sinon.spy() }
      deleter = { run: sinon.spy() }

      options =
        uploads: uploads
        uploader: uploader
        lister: lister
        deleter: deleter
      subject = new MassUpload(options)

    it 'should have status=waiting to begin with', ->
      expect(subject.get('status')).to.eq('waiting')

    it 'should have uploadProgress at 0/0', ->
      expect(subject.get('uploadProgress')).to.deep.eq({ loaded: 0, total: 0 })

    it 'should call lister.run', ->
      subject.fetchFileInfosFromServer()
      expect(lister.run).to.have.been.called

    describe 'when listing files', ->
      beforeEach ->
        lister.run = -> lister.callbacks.onStart()
        subject.fetchFileInfosFromServer()

      it 'should have status=listing-files', ->
        expect(subject.get('status')).to.eq('listing-files')

      describe 'on success', ->
        fileInfos = [ { name: 'file.txt', total: 10000, loaded: 1000, lastModified: date1 } ]

        beforeEach ->
          lister.callbacks.onSuccess(fileInfos)
          lister.callbacks.onStop()

        it 'should add to uploads', ->
          expect(uploads.addFileInfos).to.have.been.calledWith(fileInfos)

      it 'should set listFilesProgress on progress', ->
        progress = { loaded: 1000, total: 10000 }
        lister.callbacks.onProgress(progress)
        expect(subject.get('listFilesProgress')).to.eq(progress)

      describe 'on error', ->
        beforeEach ->
          lister.callbacks.onError('error')
          lister.callbacks.onStop()

        it 'should set status=listing-files-error', ->
          expect(subject.get('status')).to.eq('listing-files-error')

        it 'should set listFilesError', ->
          expect(subject.get('listFilesError')).to.eq('error')

        it 'should allow retryListFiles()', ->
          subject.retryListFiles()
          expect(subject.get('status')).to.eq('listing-files')
          expect(subject.get('listFilesError')).to.eq(null)

    describe 'starting with uploads from the server', ->
      beforeEach ->
        subject.uploads.reset([
          { file: null, fileInfo: fileInfo1, error: null }
          { file: null, fileInfo: fileInfo2, error: null }
        ])
        @upload1 = subject.uploads.at(0)
        @upload2 = subject.uploads.at(1)

      describe 'when adding files', ->
        beforeEach -> subject.addFiles([file1])

        it 'should call uploads.addFiles', ->
          expect(subject.uploads.addFiles).to.have.been.calledWith([file1])

        describe 'and merge happens', ->
          # That is, when uploads.addFiles() does its thing
          beforeEach -> @upload1.set({ file: file1 })

          it 'should call uploader.run', ->
            expect(uploader.run).to.have.been.calledWith(@upload1)

          it 'should set status=uploading when uploader.run is called', ->
            uploader.callbacks.onStart(@upload1)
            expect(subject.get('status')).to.eq('uploading')

    describe 'when uploading', ->
      beforeEach ->
        subject.uploads.reset([
          { file: null, fileInfo: fileInfo1, error: null }
          { file: file2, fileInfo: fileInfo2, error: null }
          { file: file3, fileInfo: null, error: 'previous error' }
        ])
        @upload1 = subject.uploads.at(0)
        @upload2 = subject.uploads.at(1)
        @upload3 = subject.uploads.at(2)
        uploader.callbacks.onStart(@upload2)

      it 'should set progress on progress', ->
        uploader.callbacks.onProgress(@upload2, { loaded: 2400, total: 20000 })
        expect(@upload2.get('updateWithProgressArguments')).to.deep.eq([{ loaded: 2400, total: 20000 }])

      it 'should set uploadProgress on progress', ->
        uploader.callbacks.onProgress(@upload2, { loaded: 2400, total: 20000 })
        expect(subject.get('uploadProgress')).to.deep.eq({ loaded: 3400, total: 60000 })

      it 'should set uploading on start', ->
        expect(@upload2.get('uploading')).to.eq(true)

      it 'should unset error on start', ->
        uploader.callbacks.onStart(@upload3)
        expect(@upload3.get('error')).to.eq(null)

      it 'should unset uploading on stop', ->
        uploader.callbacks.onStop(@upload2)
        expect(@upload2.get('uploading')).to.eq(false)

      it 'should set upload error on error', ->
        uploader.callbacks.onError(@upload2, 'error')
        expect(@upload2.get('error')).to.eq('error')

      it 'should set uploadProgress on success', ->
        uploader.callbacks.onSuccess(@upload2)
        expect(@upload2.get('updateWithProgressArguments')).to.deep.eq([ { loaded: 20000, total: 20000 } ])

      describe 'when adding a file', ->
        beforeEach ->
          @upload1.set('file', file1)

        it 'should abort uploading', ->
          expect(uploader.abort).to.have.been.called

        it 'should start uploading again when abort is complete', ->
          uploader.callbacks.onStop(@upload2)
          expect(uploader.run).to.have.been.called
          expect(uploader.run.lastCall.args[0]).to.eq(@upload1)

      describe 'on abort', ->
        beforeEach ->
          subject.prepare = sinon.spy()
          subject.set(uploadProgress: { loaded: 0, total: 0 })
          subject.abort()

        it 'should have status=waiting', ->
          expect(subject.get('status')).to.eq('waiting')

        it 'should have uploadProgress at 0/0', ->
          expect(subject.get('uploadProgress')).to.deep.eq({ loaded: 0, total: 0 })

        it 'has no uploads', ->
          expect(subject.uploads.at(0)).to.be.undefined

        it 'resets the uploader, lister, etc', ->
          expect(subject.prepare).to.have.been.called

      describe 'when deleting a file', ->
        beforeEach ->
          subject.removeUpload(@upload1)

        it 'should abort uploading', ->
          expect(uploader.abort).to.have.been.called

        describe 'when abort is complete', ->
          beforeEach ->
            deleter.run = (args...) =>
              @deleterRan = args
              deleter.callbacks.onStart(@upload1)
            uploader.callbacks.onStop(@upload2)

          it 'should call deleter.run()', ->
            expect(@deleterRan).to.deep.eq([ @upload1 ])

          describe 'when delete is complete', ->
            beforeEach ->
              deleter.callbacks.onSuccess(@upload1)
              deleter.callbacks.onStop(@upload1)

            it 'should remove the upload from the list', ->
              expect(uploads.length).to.eq(2)

            it 'should continue with uploading', ->
              expect(uploader.run).to.have.been.called
              expect(uploader.run.lastCall.args[0]).to.eq(@upload2)

          describe 'when delete fails', ->
            beforeEach ->
              deleter.callbacks.onError(@upload1, 'error')
              deleter.callbacks.onStop(@upload1)

            it 'should keep the upload in the list', ->
              expect(uploads.length).to.eq(3)

            it 'should set error and keep deleting=true', ->
              expect(@upload1.get('deleting')).to.eq(true)
              expect(@upload1.get('error')).to.eq('error')

            it 'should continue with uploading', ->
              expect(uploader.run).to.have.been.called

    describe 'when finishing all uploads', ->
      beforeEach ->
        uploads.reset([
          { file: file1, fileInfo: fileInfo1, error: null }
        ])
        upload1 = uploads.at(0)
        uploader.callbacks.onStart(upload1)
        uploads.next = sinon.stub().returns(null)
        uploader.callbacks.onSuccess(upload1)
        uploader.callbacks.onStop(upload1)

      it 'should set status=waiting', ->
        expect(subject.get('status')).to.eq('waiting')

    describe 'with a broken upload', ->
      beforeEach ->
        uploads.reset([
          { file: file1, fileInfo: fileInfo1, error: 'an error' }
        ])
        @upload = uploads.at(0)

      it 'should have status uploading-error, even when waiting', ->
        expect(subject.get('status')).to.eq('uploading-error')

      it 'should allow retryUpload', ->
        subject.retryUpload(@upload)
        expect(uploader.run).to.have.been.calledWith(@upload)

      it 'should allow retryAllUploads', ->
        subject.retryAllUploads()
        expect(uploader.run).to.have.been.calledWith(@upload)

      it 'should have uploadErrors', ->
        expect(subject.get('uploadErrors')).to.deep.eq([
          { upload: @upload, error: 'an error' }
        ])

    describe 'with a missing file', ->
      beforeEach ->
        subject.set(uploadProgress: { total: 10000, loaded: 1000 })
        uploads.reset([
          { file: null, fileInfo: fileInfo1, error: null }
        ])

      it 'should have status=waiting-error', ->
        expect(subject.get('status')).to.eq('waiting-error')
