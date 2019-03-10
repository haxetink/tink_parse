package;

import haxe.crypto.Base64;
import haxe.io.Bytes;
import haxe.unit.TestRunner;

class RunTests { 

  static function main() {
    var t = new TestRunner();
    t.add(new TestStringSlice());
    travix.Logger.exit(
      if (t.run()) 0
      else 500
    );
  }
  
}