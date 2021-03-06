State = require('../../src/MassUpload/State')

describe 'MassUpload/State', ->
  subject = undefined

  beforeEach ->
    subject = new State()

  it 'should start with loaded=0', ->
    expect(subject.loaded).to.eq(0)

  it 'should start with total=0', ->
    expect(subject.total).to.eq(0)

  it 'should start with status="waiting"', ->
    expect(subject.status).to.eq("waiting")

  it 'should start with no errors', ->
    expect(subject.errors.length).to.eq(0)

  it 'should start with isComplete()=false', ->
    expect(subject.isComplete()).to.eq(false)

  describe 'withTotal', ->
    subject2 = undefined

    beforeEach ->
      subject2 = subject.withTotal(10000)

    it 'should set new total', ->
      expect(subject2.total).to.eq(10000)

    it 'should not modify total on original', ->
      expect(subject.total).to.eq(0)

    it 'should have isComplete()=false', ->
      expect(subject2.isComplete()).to.eq(false)

    describe 'withLoaded less than total', ->
      subject3 = undefined

      beforeEach ->
        subject3 = subject2.withLoaded(5000)

      it 'should set new loaded', ->
        expect(subject3.loaded).to.eq(5000)

      it 'should not change original loaded', ->
        expect(subject2.loaded).to.eq(0)

      it 'should have isComplete()=false because loaded < total', ->
        expect(subject3.isComplete()).to.eq(false)

    describe 'withLoaded at total', ->
      subject3 = undefined

      beforeEach ->
        subject3 = subject2.withLoaded(10000)

      it 'should have isComplete()=true', ->
        expect(subject3.isComplete()).to.eq(true)

      describe 'withStatus of "uploading"', ->
        subject4 = undefined

        beforeEach ->
          subject4 = subject3.withStatus("uploading")

        it 'should have isComplete()=false because state != "waiting"', ->
          expect(subject4.isComplete()).to.eq(false)

      describe 'withAnError', ->
        error = 'error'
        subject4 = undefined

        beforeEach ->
          subject4 = subject3.withAnError(error)

        it 'should have the error', ->
          expect(subject4.errors).to.deep.eq([error])

        it 'should have isComplete()=false because there is an error', ->
          expect(subject4.isComplete()).to.eq(false)

        it 'should not modify the original object', ->
          expect(subject3.errors).to.deep.eq([])

        describe 'withoutAnError', ->
          subject5 = undefined

          beforeEach ->
            subject5 = subject4.withoutAnError(error)

          it 'should remove the error', ->
            expect(subject5.errors).to.deep.eq([])

          it 'should not motify the original object', ->
            expect(subject4.errors).to.deep.eq([error])
