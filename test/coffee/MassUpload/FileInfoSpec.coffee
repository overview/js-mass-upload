define [ 'MassUpload/FileInfo' ], (FileInfo) ->
  describe 'MassUpload/FileInfo', ->
    subject = undefined

    describe '.fromJson', ->
      subject = FileInfo.fromJson
        name: 'name'
        lastModifiedDate: '2013-08-07T10:28:13-04:00'
        total: 100000
        loaded: 20000

      it 'should have name', ->
        expect(subject.name).toEqual('name')

      it 'should parse lastModifiedDate in the correct timezone', ->
        expect(subject.lastModifiedDate.getTime()).toEqual(1375885693000)

      it 'should have total', ->
        expect(subject.total).toEqual(100000)

      it 'should have loaded', ->
        expect(subject.loaded).toEqual(20000)

    describe '.fromFile', ->
      beforeEach ->
        subject = FileInfo.fromFile
          name: 'name'
          lastModifiedDate: new Date(1375885693000)
          size: 10000

      it 'should have name', ->
        expect(subject.name).toEqual('name')

      it 'should have lastModifiedDate', ->
        expect(subject.lastModifiedDate.getTime()).toEqual(1375885693000)

      it 'should have total', ->
        expect(subject.total).toEqual(10000)

      it 'should have loaded=0', ->
        expect(subject.loaded).toEqual(0)

      it 'should use .webkitRelativePath if there is one', ->
        subject = FileInfo.fromFile
          name: 'name'
          lastModifiedDaet: new Date()
          size: 10000
          webkitRelativePath: 'foo/bar/name'

        expect(subject.name).toEqual('foo/bar/name')
