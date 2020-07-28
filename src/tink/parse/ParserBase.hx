package tink.parse;

using StringTools;
using tink.CoreApi;

typedef ListSyntax = {
  @:optional var start(default, never):StringSlice;
  var end(default, never):StringSlice;
  @:optional var sep(default, never):StringSlice;
  @:optional var trailing(default, never):TrailingSeparator;
}

@:enum abstract TrailingSeparator(String) {
  var Always = "Always";
  var Never = "Never";
}

class ParserBase<Pos, Error> {

  var reporter:Reporter<Pos, Error>;
  var source:StringSlice;
  var pos:Int;
  var max:Int;
  var offset:Int;

  function chomp(start, ?offset = 0)
    return source[start...pos + offset];

  public function new(source:StringSlice, reporter, ?offset = 0) {
    this.source = source;
    this.max = source.length;
    this.pos = 0;
    this.reporter = reporter;
    this.offset = offset;
  }

  /**
   * skip ignored characters, then match the character against the specified condition, without consuming it
   */
  inline function upNext(cond:Char):Bool {
    skipIgnored();
    return is(cond);
  }

  /**
   * return current character, without consuming it
   */
  inline function current():Int
    return source.fastGet(pos);

  /**
   * check if current character matches the specified condition, without consuming it
   */
  inline function is(cond:Char):Bool
    return pos < max && cond[current()];

  /**
   * advance while character fulfills the specified condition
   */
  inline function doReadWhile(cond:Char):Void
    while (is(cond)) pos++;

  /**
   * skip ignored characters, then advance while character fulfills the specified condition, and return the scanned string
   */
  inline function readWhile(cond:Char):StringSlice {
    skipIgnored();
    var start = pos;
    doReadWhile(cond);
    return source[start...pos];
  }

  var lastSkip:Int;

  /**
   * skip ignored values
   */
  function skipIgnored():Continue {
    while (lastSkip != pos) {
      lastSkip = pos;
      doSkipIgnored();
    }
    lastSkip = pos;
    return null;
  }

  function doSkipIgnored() {}

  /**
   * check if current position matches the specifed string, without consuming it
   */
  inline function isNext(s:StringSlice):Bool
    return source.hasSub(s, pos);

  /**
   * skip the specified number of characters
   */
  inline function junk(count = 1):Void {
    pos += count;
    if (pos > max) pos = max;
  }

  /**
   * skip ignored characters, then match the specified string, and consume it if matched
   */
  function allow(s:StringSlice):Bool
    return skipIgnored() + allowHere(s);

  /**
   * match the specified string, and consume it if matched
   */
  function allowHere(s:StringSlice):Bool
    return
      if (isNext(s)) {
        pos += s.length;
        true;
      }
      else false;

  /**
   * skip ignored characters, then match the specified string, and throw if doesn't match
   * use with operator `+` to produce a value
   */
  function expect(s:StringSlice):Continue {
    if (!allow(s))
      die('expected $s');
    return null;
  }

  /**
   * match the specified string, and throw if doesn't match
   * use with operator `+` to produce a value
   */
  function expectHere(s:StringSlice):Continue {
    if (!allowHere(s))
      die('expected $s');
    return null;
  }

  /**
   * produce an outcome and rewind only in case of failure
   */
  function attempt<S, F>(s:Void->Outcome<S, F>):Outcome<S, F> {
    var start = this.pos;
    var ret = s();
    if (!ret.isSuccess()) this.pos = start;
    return ret;
  }

  /**
   * produce a value and then rewind position (note: throw in the generator function to abort)
   */
  function lookahead<T>(fn:Void->T):T {
    var start = pos;
    return Error.tryFinally(fn, function () pos = start);
  }

  /**
   * produce a value and include its position
   */
  function located<T>(f:Void->T):Located<T, Pos> {
    var start = pos;
    return { value: f(), pos: makePos(start, pos) };
  }

  /**
   * consume and return string upto `end`, set `addEnd = true` to include `end` itself
   */
  function upto(end:StringSlice, ?addEnd:Bool):Outcome<StringSlice, Error>
    return
      switch source.indexOf(end, pos) {
        case -1:
          Failure(makeError('expected $end', makePos(pos)));
        case v:
          var ret = source[pos...v + if (addEnd) end.length else 0];
          pos = v + end.length;
          Success(ret);
      }

  function first(a:Array<String>, before) {
    var ret = Failure(makeError('Failed to find either of ${a.join(",")}', makePos(pos, pos))),
        min = max;

    for (s in a)
      switch source.indexOf(s, pos) {
        case -1:
        case v:
          if (v < min) {
            min = v;
            ret = Success(s);
          }
      }


    switch ret {
      case Success(v):
        before(source[pos...min]);
        pos = min + v.length;
      default:
    }
    return ret;
  }

  /**
   * throw an error, optionally include a position (default at current character)
   */
  function die(message:String, ?range:IntIterator):Dynamic {
    if (range == null) range = pos...pos + 1;
    return throw makeError(message, @:privateAccess makePos(range.min, range.max));
  }

  function read<A>(reader:Void->A) {
    skipIgnored();
    var start = pos,
        ret = reader();

    return {
      data: ret,
      pos: makePos(start, pos),
      bytesRead: pos - start
    }
  }

  /**
   * skip ignored characters and check if reached the end
   */
  function done():Bool {
    skipIgnored();
    return pos >= max;
  }

  function reject(s:StringSlice, ?reason:String):Dynamic
    return
      if (reason == null) reject('unexpected $s');
      else throw makeError(reason, makePos(s.start, s.end));

  inline function makeError(message:String, pos:Pos)
    return reporter.makeError(message, pos);

  inline function makePos(from:Int, ?to:Int):Pos
    return reporter.makePos(offset + from, offset + if (to == null) from + 1 else to);

  function parseRepeatedly(reader:Void->Void, settings:ListSyntax):Void {
    if (settings.start != null && !allow(settings.start)) return;
    switch settings.sep {
      case null:
        while (!allow(settings.end)) reader();
      case sep:
        if (allow(settings.end)) return;
        while (true) {
          reader();
          switch settings.trailing {
            case null:
              var hasSep = allow(sep);
              if (allow(settings.end)) return;
              if (!hasSep)
                die('expected ${sep} or ${settings.end}');
            case Always:
              expect(sep);
              if (allow(settings.end)) return;
            case Never:
              if (allow(settings.end)) return;
              expect(sep);
          }
        }
    }
  }

  function parseList<A>(reader:Void->A, settings):Array<A> {
    var ret = [];
    parseRepeatedly(function () ret.push(reader()), settings);
    return ret;
  }

}

abstract Continue(Dynamic) {

  @:op(a+b)
  @:extern static inline function then<A>(e:Continue, a:A):A
    return a;

  @:op(a+b)
  @:extern static inline function rthen<A>(a:A, e:Continue):A
    return a;

}