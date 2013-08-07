
define('MassUpload/Error',[], function() {
  var Error;
  return Error = (function() {
    function Error(failedCall, failedCallArgument, detail) {
      this.failedCall = failedCall;
      this.failedCallArgument = failedCallArgument;
      this.detail = detail;
    }

    return Error;

  })();
});

define('MassUpload',['./MassUpload/Error'], function(Error) {
  var MassUpload;
  MassUpload = (function() {
    function MassUpload() {}

    return MassUpload;

  })();
  MassUpload.Error = Error;
  return MassUpload;
});
