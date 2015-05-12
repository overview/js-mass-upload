_ = require('underscore')
UploadCollection = require('../../src/MassUpload/UploadCollection')

describe 'MassUpload/UploadCollection', ->
  date1 = new Date('Mon, 12 Aug 2013 10:02:54 -0400')
  date2 = new Date('Mon, 12 Aug 2013 11:02:54 -0400')

  file1 = { name: 'file1.txt', lastModifiedDate: date1, size: 10000 }
  file2 = { name: 'file2.txt', lastModifiedDate: date1, size: 20000 }

  fileInfo1 = { name: 'file1.txt', lastModifiedDate: date1, loaded: 2000, total: 10000 }
  fileInfo2 = { name: 'file2.txt', lastModifiedDate: date1, loaded: 3000, total: 20000 }

  subject = undefined
  beforeEach -> subject = new UploadCollection([])
  afterEach -> subject?.off()

  describe 'reset', ->
    it 'should reset to empty list without params', ->
      subject.reset()
      expect(subject.length).to.eq(0)

    it 'should return the collection', ->
      resetSpy = sinon.spy()
      subject.on('reset', resetSpy)
      subject.reset()
      expect(resetSpy).to.have.been.calledWith(subject)

  describe 'remove', ->
    it 'should remove the upload', ->
      subject.on('remove', spy = sinon.spy())
      subject.reset([
        { file: file1, fileInfo: fileInfo1 }
        { file: file2, fileInfo: fileInfo2 }
      ])
      upload = subject.get('file2.txt')
      subject.remove(upload)
      expect(subject.length).to.eq(1)
      expect(subject.get('file2.txt')).not.to.exist
      expect(subject.get('file1.txt')).to.exist
      expect(spy).to.have.been.calledWith(upload, subject)

  describe 'addFiles() when file does not exist', ->
    addBatchArgs = null

    beforeEach ->
      addBatchArgs = []
      subject.on('add-batch', (uploads) -> addBatchArgs.push(uploads))
      subject.addFiles([ file1, file2 ])

    afterEach ->
      subject.off('add-batch')

    it 'should create Upload objects', ->
      expect(subject.length).to.eq(2)
      upload1 = subject.models[0]
      upload2 = subject.models[1]
      expect(upload1.attributes.file).to.eq(file1)
      expect(upload1.attributes.fileInfo).to.eq(null)
      expect(upload1.attributes.error).to.eq(null)
      expect(upload2.attributes.file).to.eq(file2)
      expect(upload2.attributes.fileInfo).to.eq(null)
      expect(upload2.attributes.error).to.eq(null)

    it 'should trigger add-batch', ->
      expect(addBatchArgs.length).to.eq(1)
      expect(addBatchArgs[0].length).to.eq(2)
      expect(addBatchArgs[0][0].attributes.file).to.eq(file1)

  describe 'addFiles() when an un-uploaded file already exists', ->
    file1 = { name: 'file1.txt', lastModifiedDate: date1, size: 10000 }
    addBatchArgs = null

    beforeEach ->
      addBatchArgs = []
      subject.on('add-batch', (uploads) -> addBatchArgs.push(uploads))
      subject.addFiles([ file1 ])
      subject.addFiles([ file1 ])

    afterEach ->
      subject.off('add-batch')

    it 'should not duplicate the file', ->
      expect(subject.length).to.eq(1)

    it 'should not trigger add-batch when merging', ->
      expect(addBatchArgs.length).to.eq(1)

  describe 'addFileInfos() when fileInfo does not exist', ->
    addBatchArgs = null

    beforeEach ->
      addBatchArgs = []
      subject.on('add-batch', (uploads) -> addBatchArgs.push(uploads))
      subject.addFileInfos([fileInfo1])

    afterEach ->
      subject.off('add-batch')

    it 'should create Upload objects', ->
      expect(subject.length).to.eq(1)
      upload1 = subject.models[0]
      expect(upload1.attributes.file).to.eq(null)
      expect(upload1.attributes.fileInfo).to.eq(fileInfo1)
      expect(upload1.attributes.error).to.eq(null)

    it 'should not re-add existing fileInfos', ->
      subject.addFileInfos([fileInfo1])
      expect(subject.length).to.eq(1)

    it 'should trigger add-batch', ->
      expect(addBatchArgs.length).to.eq(1)
      expect(addBatchArgs[0].length).to.eq(1)
      expect(addBatchArgs[0][0].attributes.fileInfo).to.eq(fileInfo1)

  describe 'with a file-backed Upload', ->
    file1 = { name: 'file1.txt', lastModifiedDate: date1, size: 10000 }
    beforeEach -> subject.addFiles([file1])

    it 'should merge a fileInfo through addFileInfos()', ->
      fileInfo1 = { name: 'file1.txt', lastModifiedDate: date1, loaded: 2000, total: 10000 }
      subject.addFileInfos([fileInfo1])
      expect(subject.length).to.eq(1)
      upload = subject.models[0]
      expect(upload.attributes.file).to.eq(file1)
      expect(upload.attributes.fileInfo).to.eq(fileInfo1)

  describe 'with a fileInfo-backed Upload', ->
    fileInfo1 = { name: 'file1.txt', lastModifiedDate: date1, loaded: 2000, total: 10000 }
    beforeEach -> subject.addFileInfos([fileInfo1])

    it 'should merge a file through addFiles()', ->
      file1 = { name: 'file1.txt', lastModifiedDate: date1, size: 10000 }
      subject.addFiles([file1])
      expect(subject.length).to.eq(1)
      upload = subject.models[0]
      expect(upload.attributes.file).to.eq(file1)
      expect(upload.attributes.fileInfo).to.eq(fileInfo1)

  describe 'forFile', ->
    it 'should search by webkitRelativePath if there is one', ->
      file =
        id: 'foo/bar.txt'
        name: 'bar.txt'
        webkitRelativePath: 'foo/bar.txt'
        lastModifiedDate: date1
        size: 10000

      subject.addFiles([ file ])
      expect(subject.forFile(file).file).to.eq(file)

    it 'should search by name if there is no webkitRelativePath', ->
      file =
        id: 'bar.txt'
        name: 'bar.txt'
        lastModifiedDate: date1
        size: 10000

      subject.addFiles([ file ])
      expect(subject.forFile(file).file).to.eq(file)

  describe 'forFileInfo', ->
    it 'should search by name', ->
      subject.addFileInfos([ fileInfo1 ])
      expect(subject.forFileInfo(fileInfo1).fileInfo).to.eq(fileInfo1)

  describe 'next', ->
    it 'should return null on empty collection', ->
      expect(subject.next()).to.eq(null)

    it 'should return null if all files are uploaded', ->
      subject.reset([
        { file: file1, fileInfo: _.defaults({ loaded: file1.size }, fileInfo1), error: null }
      ])
      expect(subject.next()).to.eq(null)

    it 'should return null if an unfinished file was not selected by the user', ->
      subject.reset([
        { file: null, fileInfo: fileInfo1, error: null }
      ])
      expect(subject.next()).to.eq(null)

    it 'should return null if all files have errors', ->
      subject.reset([
        { file: file1, fileInfo: fileInfo1, error: 'error' }
      ])
      expect(subject.next()).to.eq(null)

    it 'should return an un-uploaded file', ->
      upload = { file: file1, fileInfo: fileInfo1, error: null }
      subject.reset([ upload ])
      expect(subject.next()).to.eq(subject.get('file1.txt'))

    it 'should return a deleting file ahead of an uploading file', ->
      subject.reset([
        { file: file1, fileInfo: fileInfo1, uploading: true, error: null }
        { file: file2, fileInfo: fileInfo2, deleting: true, error: null }
      ])
      expect(subject.next()).to.eq(subject.get('file2.txt'))

    it 'should return an uploading file ahead of an unfinished file', ->
      subject.reset([
        { file: file1, fileInfo: fileInfo1, error: null }
        { file: file2, fileInfo: fileInfo2, uploading: true, error: null }
      ])
      expect(subject.next()).to.eq(subject.get('file2.txt'))

    it 'should return an unfinished file ahead of an unstarted file', ->
      subject.reset([
        { file: file1, fileInfo: null, error: null }
        { file: file2, fileInfo: fileInfo2, error: null }
      ])
      expect(subject.next()).to.eq(subject.get('file2.txt'))

    it 'should return files in collection order', ->
      subject.reset([
        { file: file2, fileInfo: null, error: null }
        { file: file1, fileInfo: null, error: null }
      ])
      expect(subject.next()).to.eq(subject.get('file2.txt'))

    it 'should return a second file after the first is uploaded', ->
      subject.reset([
        { file: file1, fileInfo: null, error: null }
        { file: file2, fileInfo: null, error: null }
      ])
      subject.get('file1.txt').set(fileInfo: _.extend({}, fileInfo1, { loaded: 10000 }))
      expect(subject.next()).to.eq(subject.get('file2.txt'))
