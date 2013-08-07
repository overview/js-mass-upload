define [ 'MassUpload/Error' ], (Error) ->
  describe 'MassUpload/Error', ->
    subject = undefined

    describe 'with a typical error', ->
      subject = new Error('call', 'argument', 'detail')

    it 'should have a failedCall', ->
      expect(subject.failedCall).toEqual('call')

    it 'should have a failedCallArgument', ->
      expect(subject.failedCallArgument).toEqual('argument')

    it 'should have a detail', ->
      expect(subject.detail).toEqual('detail')
