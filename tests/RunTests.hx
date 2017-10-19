package ;

import aws.iot.*;

class RunTests {

  static function main() {
    trace(SigV4Utils.getSignedUrl);
    travix.Logger.println('it works');
    travix.Logger.exit(0); // make sure we exit properly, which is necessary on some targets, e.g. flash & (phantom)js
  }
  
}