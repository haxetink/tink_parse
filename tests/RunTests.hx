package;

import haxe.crypto.Base64;
import haxe.io.Bytes;
import haxe.unit.TestRunner;

#if flash
typedef Sys = flash.system.System;
#end
class RunTests { 

  static function main() {
    var t = new TestRunner();
    t.add(new TestStringSlice());
    if (!t.run())
      Sys.exit(500);
  }
  
}