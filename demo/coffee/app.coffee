$ = require('jquery')
Backbone = require('backbone')

Backbone.$ = $

MassUpload = require('../../js-mass-upload')
uploadLogic = require('./upload-logic')
MassUploadView = require('../../src/MassUpload/views/MassUpload')

options = $.extend({}, uploadLogic)

massUpload = new MassUpload(options)

new MassUploadView(model: massUpload, el: $('.mass-upload'))

$networkIsWorking = $('#network-is-working')
$networkIsWorking.change ->
  value = $networkIsWorking.prop('checked')
  uploadLogic.toggleWorking(value)

massUpload.fetchFileInfosFromServer()
