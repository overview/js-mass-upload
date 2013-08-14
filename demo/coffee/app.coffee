define [ 'jquery', 'mass-upload', 'upload-logic', 'MassUpload/views/MassUpload' ], ($, MassUpload, uploadLogic, MassUploadView) ->
  options = $.extend({
  }, uploadLogic)

  massUpload = new MassUpload(options)

  new MassUploadView(model: massUpload, el: $('.mass-upload'))

  $networkIsWorking = $('#network-is-working')
  $networkIsWorking.change ->
    value = $networkIsWorking.prop('checked')
    uploadLogic.toggleWorking(value)

  massUpload.fetchFileInfosFromServer()
