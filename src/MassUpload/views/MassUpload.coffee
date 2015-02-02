Backbone = require('backbone')
ListFilesProgressView = require('./ListFilesProgress')
UploadCollectionView = require('./UploadCollection')
UploadProgressView = require('./UploadProgress')

module.exports = class MassUploadView extends Backbone.View
  className: 'mass-upload'

  initialize: ->
    listFilesProgressView = new ListFilesProgressView({ model: @model })
    @listenTo(listFilesProgressView, 'retry', => @model.retryListFiles())
    @$el.append(listFilesProgressView.el)

    uploadCollectionView = new UploadCollectionView({ collection: @model.uploads })
    @$el.append(uploadCollectionView.el)

    @listenTo(uploadCollectionView, 'add-files', (files) => @model.addFiles(files))
    @listenTo(uploadCollectionView, 'remove-upload', (upload) => @model.removeUpload(upload))
    @listenTo(uploadCollectionView, 'retry-upload', (upload) => @model.retryUpload(upload))

    uploadProgressView = new UploadProgressView({ model: @model })
    @listenTo(uploadProgressView, 'retry', => @model.retryAllUploads())
    @$el.append(uploadProgressView.el)

    @listenTo(@model, 'change:status', => @render())
    @render()

  render: ->
    status = @model.get('status')
    @$el.attr('data-status', status)
