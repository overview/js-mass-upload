FileInfo = require('../../src/MassUpload/FileInfo')

describe 'MassUpload/FileInfo', ->
  subject = undefined

  describe '.fromJson', ->
    subject = FileInfo.fromJson
      name: 'name'
      lastModified: new Date('2013-08-07T10:28:13-04:00').valueOf()
      total: 100000
      loaded: 20000

    it 'should have name', ->
      expect(subject.name).to.eq('name')

    it 'should have lastModified', ->
      expect(subject.lastModified).to.eq(1375885693000)

    it 'should have total', ->
      expect(subject.total).to.eq(100000)

    it 'should have loaded', ->
      expect(subject.loaded).to.eq(20000)

  describe '.fromFile', ->
    beforeEach ->
      subject = FileInfo.fromFile
        name: 'name'
        lastModified: 1375885693000
        size: 10000

    it 'should have name', ->
      expect(subject.name).to.eq('name')

    it 'should have lastModified', ->
      expect(subject.lastModified).to.eq(1375885693000)

    it 'should have total', ->
      expect(subject.total).to.eq(10000)

    it 'should have loaded=0', ->
      expect(subject.loaded).to.eq(0)

    it 'should use .webkitRelativePath if there is one', ->
      subject = FileInfo.fromFile
        name: 'name'
        lastModified: new Date().valueOf()
        size: 10000
        webkitRelativePath: 'foo/bar/name'

      expect(subject.name).to.eq('foo/bar/name')
