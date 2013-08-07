define([], function() {
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
