define [ 'jquery', 'mass-upload', 'upload-logic', 'MassUploadView' ], ($, MassUpload, uploadLogic, MassUploadView) ->
  options = $.extend({
  }, uploadLogic)

  massUpload = new MassUpload(options)

  new MassUploadView(model: massUpload, el: $('.mass-upload'))

  massUpload.fetchFileInfosFromServer()
