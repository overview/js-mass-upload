define ->
  class FileInfo
    constructor: (@name, @lastModifiedDate, @total, @loaded) ->

  FileInfo.fromJson = (obj) ->
    new FileInfo(
      obj.name,
      new Date(obj.lastModifiedDate),
      obj.total,
      obj.loaded
    )

  FileInfo.fromFile = (obj) ->
    new FileInfo(
      obj.name,
      obj.lastModifiedDate,
      obj.size,
      0
    )

  FileInfo
