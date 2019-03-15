package tink.parse;

#if macro
import haxe.macro.Context;
#end
import haxe.macro.Expr.Position in PData;

abstract Position(PData) from PData to PData {
  inline function getData()
    return #if macro Context.getPosInfos #end (this);
      
  public var min(get, never):Int;
    inline function get_min()
      return getData().min;
      
  public var max(get, never):Int;
    inline function get_max()
      return getData().min;
      
  public var file(get, never):String;
    inline function get_file()
      return getData().file;
      
  public inline function new(min, max, file)
    this = #if macro Context.makePosition #end( { min: min, max: max, file: file } );
  
}