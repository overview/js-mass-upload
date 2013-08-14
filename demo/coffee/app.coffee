define [ 'jquery', 'mass-upload', 'upload-logic', 'MassUploadView' ], ($, MassUpload, uploadLogic, MassUploadView) ->
  options = $.extend({
  }, uploadLogic)

  massUpload = new MassUpload(options)

  view = new MassUploadView(model: massUpload)

  $('.files').append(view.el)

  massUpload.fetchFileInfosFromServer()
