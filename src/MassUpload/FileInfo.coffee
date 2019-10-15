module.exports = class FileInfo
  constructor: (@name, @lastModified, @total, @loaded) ->

FileInfo.fromJson = (obj) ->
  new FileInfo(
    obj.name,
    obj.lastModified,
    obj.total,
    obj.loaded
  )

FileInfo.fromFile = (obj) ->
  new FileInfo(
    obj.webkitRelativePath || obj.name,
    obj.lastModified,
    obj.size,
    0
  )
