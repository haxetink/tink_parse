package;

import haxe.unit.TestCase;
import tink.parse.StringSlice;

class TestStringSlice extends TestCase {
  
  function testClamp() {
    var str:StringSlice = new StringSlice('hello world! how are you?', 6, 12); 
    assertEquals(str.length, 6);
    for (i in 0...str.length)
      assertEquals(i, str.clamp(i));
    for (i in str.length...100)
      assertEquals(str.length, str.clamp(i));
    for (i in -str.length...0)
      assertEquals(i + str.length, str.clamp(i));
  }
  
  function testSlice() {
    var str:StringSlice = 'hello world! how are you?'; 
    
    assertEquals('h', str[0...1]);
    assertEquals('hello', str[0...5]);
    
    for (i in 0...str.length >> 1) {
      var str = str[i... -i];
      for (i in 1...str.length >> 1) {
        assertEquals(str[0...-i].toString(), str[0...str.length-i].toString());
      }
    }
  }
  
  function testBefore() {
    var str:StringSlice = 'hello world! how are you?'; 
    
    for (i in 0...str.length >> 1) {
      
      var str = str[i... -i];
      
      for (i in 0...str.length) {
        
        assertEquals(i, str.before(i).length);
        
        if (i > 0)
          assertEquals(str.length - i, str.before(-i).length);
        
        assertEquals(str.before(i).toString(), str[0...i]);
        assertEquals(str.before(-i).toString(), str[0...-i]);
      }
    }
  }
  
  function testAfter() {
    var str:StringSlice = 'hello world! how are you?'; 
    
    for (i in 0...str.length >> 1) {
      
      var str = str[i... -i];
      
      for (i in 0...str.length) {
        
        assertEquals(str.length - i, str.after(i).length);
        
        if (i > 0)
          assertEquals(i, str.after( -i).length);
          
        assertEquals(str.after(i).toString(), str[i...str.length]);
        assertEquals(str.after(-i).toString(), str[-i...str.length]);
      }
    }
  }  
  
}