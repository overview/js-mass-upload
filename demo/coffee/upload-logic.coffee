define ->
  date1 = new Date('Mon, 13 Aug 2013 09:29:16 -0400')
  date2 = new Date('Mon, 14 Aug 2013 09:29:16 -0400')
  date3 = new Date('Mon, 15 Aug 2013 09:29:16 -0400')
  serverFiles = [
    { name: 'file1.txt', loaded: 2000, total: 10000, lastModifiedDate: date1 }
    { name: 'file2.txt', loaded: 3000, total: 20000, lastModifiedDate: date2 }
    { name: 'file3.txt', loaded: 4000, total: 30000, lastModifiedDate: date3 }
  ]

  networkIsWorking = true # when false, all ticks fail

  tickListFilesAtBytes = (bytes, progress, success, error) ->
    if !networkIsWorking
      error()
    else
      total = 1000
      increment = 100
      timeout = 100

      if bytes >= total
        progress({ loaded: total, total: total })
        success(serverFiles)
      else
        progress({ loaded: bytes, total: total })
        window.setTimeout((-> tickListFilesAtBytes(bytes + increment, progress, success, error)), timeout)

  tickUploadFileAtByte = (file, bytes, progress, success, error) ->
    if !networkIsWorking
      error()
    else
      increment = 50000
      timeout = 500

      if bytes >= file.size
        progress({ loaded: file.size, total: file.size })
        success()
      else
        progress({ loaded: bytes, total: file.size })
        window.setTimeout((-> tickUploadFileAtByte(file, bytes + increment, progress, success, error)), timeout)

  # Returns three dummy files, taking about a second
  doListFiles: (progress, success, error) -> tickListFilesAtBytes(0, progress, success, error)

  # "Uploads" the file at 100kb/s (really, does nothing but call success)
  doUploadFile: (file, progress, success, error) -> tickUploadFileAtByte(file, 0, progress, success, error)

  # "Deletes" the file after 1s (really, does nothing but call success)
  doDeleteFile: (fileInfo, success, error) ->
    window.setTimeout(->
      if networkIsWorking
        success()
      else
        error()
    , 1000)

  # Specifies to overwrite
  onUploadConflictingFile: (file, conflictingFileInfo, deleteFromServer, skip) -> deleteFromServer()

  toggleWorking: (working) -> networkIsWorking = working
