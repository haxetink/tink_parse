package tink.parse;

typedef Located<T, Pos> = {
  var pos(default, never):Pos;
  var value(default, never):T;
}