package;

import haxe.unit.TestRunner;
import tink.parse.ParserBase;

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