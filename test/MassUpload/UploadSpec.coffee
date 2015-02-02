Upload = require('../../src/MassUpload/Upload')

describe 'MassUpload/Upload', ->
  date1 = new Date('Mon, 12 Aug 2013 10:02:54 -0400')
  date2 = new Date('Mon, 12 Aug 2013 11:02:54 -0400')

  describe 'starting with a File', ->
    file = undefined
    subject = undefined

    beforeEach ->
      file = { size: 10000, name: 'file.txt', lastModifiedDate: date1 }
      subject = new Upload({ file: file })

    it 'should have file, fileInfo, error, uploading and deleting attributes', ->
      expect('file' of subject.attributes).to.eq(true)
      expect('fileInfo' of subject.attributes).to.eq(true)
      expect('uploading' of subject.attributes).to.eq(true)
      expect('deleting' of subject.attributes).to.eq(true)
      expect('error' of subject.attributes).to.eq(true)

    it 'should have an id of the filename', ->
      expect(subject.id).to.eq('file.txt')

    it 'should have an id of the webkitRelativePath if there is one', ->
      file.webkitRelativePath = 'foo/bar/file.txt'
      subject = new Upload({ file: file })
      expect(subject.id).to.eq('foo/bar/file.txt')

    it 'should have no fileInfo or error', ->
      expect(subject.get('fileInfo')).to.eq(null)
      expect(subject.get('error')).to.eq(null)

    it 'should have getProgress() return 0/size', ->
      expect(subject.getProgress()).to.deep.eq({ loaded: 0, total: file.size })

    it 'should have size(), a memoized size', ->
      expect(subject.size()).to.eq(10000)

    it 'should have lastModifiedDate(), a memoized lastModifiedDate', ->
      expect(subject.lastModifiedDate()).to.eq(date1)

    describe 'updateWithProgress', ->
      beforeEach ->
        subject.uploading = true
        subject.updateWithProgress({ loaded: 2000, total: 10000 })

      it 'should create a fileInfo', ->
        fileInfo = subject.get('fileInfo')
        expect(fileInfo).not.to.eq(null)
        expect(fileInfo.name).to.eq(file.name)
        expect(fileInfo.lastModifiedDate).to.eq(file.lastModifiedDate)
        expect(fileInfo.total).to.eq(file.size)
        expect(fileInfo.loaded).to.eq(2000)

      it 'should have isFullyUploaded=false because loaded != total', ->
        subject.uploading = false
        expect(subject.isFullyUploaded()).to.eq(false)

      it 'should have getProgress() return the progress', ->
        expect(subject.getProgress()).to.deep.eq({ loaded: 2000, total: 10000 })

  describe 'starting with a completed FileInfo', ->
    fileInfo = { loaded: 10000, total: 10000, name: 'file.txt', lastModifiedDate: date1 }
    subject = undefined

    beforeEach ->
      subject = new Upload({ fileInfo: fileInfo })

    it 'should have an id of the filename', ->
      expect(subject.id).to.eq('file.txt')

    it 'should have isFullyUploaded=true', ->
      expect(subject.isFullyUploaded()).to.eq(true)

    it 'should have isFullyUploaded=false if deleting=true', ->
      subject.deleting = true
      expect(subject.isFullyUploaded()).to.eq(false)

  describe 'starting with an incomplete FileInfo', ->
    fileInfo = { loaded: 2000, total: 10000, name: 'file.txt', lastModifiedDate: date1 }
    subject = undefined

    beforeEach ->
      subject = new Upload({ fileInfo: fileInfo })

    it 'should have isFullyUploaded=false', ->
      expect(subject.isFullyUploaded()).to.eq(false)

    it 'should have getProgress() return the progress', ->
      expect(subject.getProgress()).to.deep.eq({ loaded: 2000, total: 10000 })

  describe 'with compatible File and FileInfo', ->
    file = { size: 10000, name: 'file.txt', lastModifiedDate: date1 }
    fileInfo = { loaded: 10000, total: 10000, name: 'file.txt', lastModifiedDate: date1 }
    subject = undefined
    beforeEach -> subject = new Upload({ file: file, fileInfo: fileInfo })

    it 'should have isFullyUploaded=true', ->
      expect(subject.isFullyUploaded()).to.eq(true)

    it 'should have isFullyUploaded=false if error!=null', ->
      subject.error = 'an error'
      expect(subject.isFullyUploaded()).to.eq(false)

    it 'should have isFullyUploaded=false if uploading=true', ->
      subject.uploading = true
      expect(subject.isFullyUploaded()).to.eq(false)

  describe 'with incompatible File and FileInfo', ->
    file = { size: 12000, name: 'file.txt', lastModifiedDate: date2 }
    fileInfo = { loaded: 10000, total: 10000, name: 'file.txt', lastModifiedDate: date1 }
    subject = undefined
    beforeEach -> subject = new Upload({ file: file, fileInfo: fileInfo })

    it 'should have getProgress() return the file progress, not the fileInfo progress', ->
      expect(subject.getProgress()).to.deep.eq({ loaded: 0, total: 12000 })

  describe 'hasConflict', ->
    subject = undefined
    init = (file, fileInfo) -> subject = new Upload({ file: file, fileInfo: fileInfo })

    it 'should be false when File and FileInfo match', ->
      init(
        { size: 10000, name: 'file.txt', lastModifiedDate: date1 },
        { loaded: 10000, total: 10000, name: 'file.txt', lastModifiedDate: date1 }
      )
      expect(subject.hasConflict()).to.eq(false)

    it 'should be true when size is different', ->
      init(
        { size: 10003, name: 'file.txt', lastModifiedDate: date1 },
        { loaded: 10000, total: 10000, name: 'file.txt', lastModifiedDate: date1 }
      )
      expect(subject.hasConflict()).to.eq(true)

    it 'should be true when lastModifiedDate is different', ->
      init(
        { size: 10000, name: 'file.txt', lastModifiedDate: date2 },
        { loaded: 10000, total: 10000, name: 'file.txt', lastModifiedDate: date1 }
      )
      expect(subject.hasConflict()).to.eq(true)
