date1 = new Date('Mon, 13 Aug 2013 09:29:16 -0400')
date2 = new Date('Mon, 14 Aug 2013 09:29:16 -0400')
date3 = new Date('Mon, 15 Aug 2013 09:29:16 -0400')
serverFiles = [
  { name: 'file1.txt', loaded: 2000, total: 10000, lastModifiedDate: date1 }
  { name: 'file2.txt', loaded: 3000, total: 20000, lastModifiedDate: date2 }
  { name: 'file3.txt', loaded: 4000, total: 30000, lastModifiedDate: date3 }
]

networkIsWorking = true # when false, all ticks fail

sendAsyncError = (callback, message) ->
  window.setTimeout((-> callback(new Error(message))), 50)

tickListFilesAtBytes = (bytes, progress, done) ->
  if !networkIsWorking
    sendAsyncError(done, 'network is broken')
  else
    total = 1000
    increment = 100
    timeout = 100

    if bytes >= total
      progress({ loaded: total, total: total })
      done(null, serverFiles)
    else
      progress({ loaded: bytes, total: total })
      window.setTimeout((-> tickListFilesAtBytes(bytes + increment, progress, done)), timeout)

tickUploadFileAtByte = (file, bytes, progress, done) ->
  if !networkIsWorking
    sendAsyncError(done, 'network is broken')
  else
    increment = 50000
    timeout = 500

    if bytes >= file.size
      progress({ loaded: file.size, total: file.size })
      done()
    else
      progress({ loaded: bytes, total: file.size })
      window.setTimeout((-> tickUploadFileAtByte(file, bytes + increment, progress, done)), timeout)

module.exports =
  # Returns three dummy files, taking about a second
  doListFiles: (progress, done) -> tickListFilesAtBytes(0, progress, done)

  # "Uploads" the file at 100kb/s (really, does nothing but call success)
  doUploadFile: (upload, progress, done) -> tickUploadFileAtByte(upload.get('file'), 0, progress, done)

  # "Deletes" the file after 1s (really, does nothing but call success)
  doDeleteFile: (upload, done) ->
    window.setTimeout(->
      if networkIsWorking
        done()
      else
        done(new Error('network is broken'))
    , 1000)

  # Specifies to overwrite
  onUploadConflictingFile: (upload, conflictingFileInfo, deleteFromServer, skip) -> deleteFromServer()

  toggleWorking: (working) -> networkIsWorking = working
