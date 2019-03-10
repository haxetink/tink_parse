package tink.parse;

import haxe.macro.Expr;

@:forward
abstract Reporter<Pos, Error>(ReporterObject<Pos, Error>) 
  from ReporterObject<Pos, Error> 
  to ReporterObject<Pos, Error> 
{
  static public function expr(file:String):Reporter<Position, Error>
    return new ExprReporter(file);
}

interface ReporterObject<Pos, Error> {
  function makeError(message:String, pos:Pos):Error;  
  function makePos(from:Int, to:Int):Pos;
}

class ExprReporter implements ReporterObject<Position, Error> {
  
  var file:String;

  public function new(file) {
    this.file = file;
  }

  public function makeError(message:String, pos:Position):Error
    return new Error(message, pos);

  public function makePos(from:Int, to:Int):Position {
    return #if macro haxe.macro.Context.makePos #end({ min: from, max: to, file: file });
  }
}
