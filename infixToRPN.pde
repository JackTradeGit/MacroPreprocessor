// TODO: infixToRPN would allow the preprocessor to do some otherwise difficult/impossible things...
// Pulled from an ancient project that I left in a ROUGH state...
//takes infix (normal) notation and converts it to reverse polish notation using a stack
//String testRPN_input = "((123 * (2 + 45) * (2.3 / 5) ^ 0.2 - 1) % 5 * (1 - 5) ^ \\&{token_prec} + \\#{random,10,50})";
String testRPN_input = "((123 * (2 + 45) * (23 / 5) ^ 2 - 1) % (5 * (1 - -5)) ^ \\&{token_prec})"; // infix notation to be converted
// 123 2 45 + * 23 5 / * 2 1 - ^ 5 1 5 - * % 1337 ^
// == 1312

// we only have to perform infix to RPN conversion for our own code (or for "\("), otherwise we can simply emit the unconverted line

/*
5 - 5, 5-5, 5 -5, 5- 5 = minus
5 - -5 = minus & unary negate
(-5) = unary negate
*/

void testRPN(){
  if(_Vars == null){ _Vars = new StringDict(); }
  println("input:" + testRPN_input);
  updateVariable("token_prec", "" + 1337);
  try{
    String testRPN_output = lineToRPN(testRPN_input, 0); // converted output
    println("output:" + testRPN_output);
    printArray(_Vars);
  }catch(Exception e){}
}

int getPrecedenceRPN(String c){
  switch(c){
    case "|": // Bitwise OR
      return 10;
    
    case "^": // Bitwise XOR
      return 20;
    
    case "&": // Bitwise AND
      return 30;
    
    case "+": // Addition
    case "-": // Subtraction
      return 40;
    
    case "*": // Multiplication
    case "/": // Division
    case "%": // Modulo
      return 50;
  }
  
  //println("getPrecedenceRPN.unknownToken: " + c);
  return 0;
}

boolean validUnary(char c){
  return c == '~' || // Unary Invert
         c == '+' || // Unary Positive
         c == '-';   // Unary Negative
}

class RPNToken{
  String indentifier;
  int precedence;
  
  RPNToken(String n, int p){
    indentifier = n;
    precedence = p;
  }
  
  RPNToken(char c, int p){
    indentifier = "" + c;
    precedence = p;
  }
  
  String toString(){
    return "<" + indentifier + ":" + precedence + ">";
  }
}

class Stack{
  ArrayList<RPNToken> data;
  
  Stack(){
    data = new ArrayList<RPNToken>();
  }
  
  int size(){
    return data.size();
  }
  
  void push(RPNToken value){
    data.add(value);
  }
  
  RPNToken get(int index) {
    if(index >= data.size() || index < 0) {
      return new RPNToken(index < 0 ? "~" : "!", -1); //throw new ArrayIndexOutOfBoundsException(index);
    }
    return data.get(index);
  }

  RPNToken pop(){
    if(data.size() == 0){
      return new RPNToken("#", -1); //throw new RuntimeException("Can't call pop() on an empty list");
    }
    return data.remove(data.size() - 1);
  }
  
  RPNToken peek(){
    return get(data.size() - 1);
  }
  
  String toString(){
    String output_ = "";
    for(int i = 0; i < data.size(); i++){
      output_ += "\n[" + i + "] " + data.get(i);
    }
    return output_;
  }
}

String lineToRPN(String line, int index) throws Exception{
  Stack stack = new Stack();
  int state = 0;
  String output = "";
  String token = "";
  String number = "";
  int parenDepth = 1; // we start with a depth of 1 due to entering on an escaped open-paren
  
  ArrayList<RPNToken> out = new ArrayList<RPNToken>();
  
  for(int i = index; i < line.length() && state != -1; i++){
    char c = line.charAt(i);
    //println(i + ":" + c);
    switch(state){
      case 0:
        switch(c){
          case ' ':
            if(number.length() > 0){ out.add(new RPNToken(number, 0)); number = ""; }
            if(output.charAt(output.length() - 1) != ' '){ output += " "; }
            break;
          
          case '(': // '(' temporarily resets the top of stack precedence
            parenDepth++;
            stack.push(new RPNToken(c, -1));
            break;
          
          case ')':
            if(number.length() > 0){ out.add(new RPNToken(number, 0)); number = ""; }
            parenDepth--;
            if(parenDepth == 0){ state = -1; }
            else{
              while(!stack.peek().indentifier.equals("(")){
                if(output.charAt(output.length() - 1) != ' '){ output += " "; }
                out.add(stack.peek());
                output += stack.pop().indentifier;
              }
              stack.pop();
            }
            break;
          
          case '\\': // escaped values, like macro args, global variables, built-in functions, etc.
            Token tmp = cleanEscape(line, i, true);
            out.add(new RPNToken(tmp.String, 0));
            output += tmp.String;
            i = tmp.nextIndex;
            break; // may want to defer calculating anything within escaped values, unless they do their own infixToRPN work...
          
          default:
            if(isNumber(c) || c == '.'){
              output += c;
              number += c;
            }else{
              if(i+1 < line.length()){
                char c2 = line.charAt(i+1);
                if(validUnary(c) && isNumber(c2)){ // unary operation
                  output += c;
                  number += c;
                }else{
                  switch(c2){
                    case ' ': // single character operator
                      if(getPrecedenceRPN(""+c) > getPrecedenceRPN(stack.peek().indentifier)){
                        stack.push(new RPNToken(c, -1));
                      }else{
                        while(getPrecedenceRPN(""+c) <= getPrecedenceRPN(stack.peek().indentifier)){
                          if(output.charAt(output.length() - 1) != ' '){ output += " "; }
                          out.add(stack.peek());
                          output += stack.pop().indentifier;
                        }
                        stack.push(new RPNToken(c, -1));
                      }
                      break;
                    
                    default: // multi-character operator
                      token += c;
                      state = 1;
                      break;
                  }
                }
              }else{
                if(getPrecedenceRPN(""+c) > getPrecedenceRPN(stack.peek().indentifier)){
                  stack.push(new RPNToken(c, -1));
                }else{
                  while(getPrecedenceRPN(""+c) <= getPrecedenceRPN(stack.peek().indentifier)){
                    if(output.charAt(output.length() - 1) != ' '){ output += " "; }
                    out.add(stack.peek());
                    output += stack.pop().indentifier;
                  }
                  stack.push(new RPNToken(c, -1));
                }
              }
            }
            break;
        }
        break;
      
      case 1:
        switch(c){
          case ' ': // end of multi-character operator
            if(getPrecedenceRPN(token) == 0){ output += "\\!{infixToRPN:invalid-multi-op, " + token + "}"; } // invalid multi-character operator
            else{
              if(getPrecedenceRPN(token) > getPrecedenceRPN(stack.peek().indentifier)){
                stack.push(new RPNToken(token, -1));
              }else{
                while(getPrecedenceRPN(token) <= getPrecedenceRPN(stack.peek().indentifier)){
                  if(output.charAt(output.length() - 1) != ' '){ output += " "; }
                  out.add(stack.peek());
                  output += stack.pop().indentifier;
                }
                stack.push(new RPNToken(token, -1));
              }
            }
            token = "";
            state = 0;
            break;
          
          case '\\': // escaped values, like macro args, global variables, built-in functions, etc.
            Token tmp = cleanEscape(line, i, false);
            out.add(new RPNToken(tmp.String, 0));
            output += tmp.String;
            i = tmp.nextIndex;
            break; // may want to defer calculating anything within escaped values, unless they do their own infixToRPN work...
          
          default: // still more characters in the multi-character operator
            token += c;
            break;
        }
        break;
    }
    //println("[" + i + "] " + output + " : stack == " + stack);
  }
  //println("stack == " + stack);
  while(stack.size() > 0){
    output += " " + stack.pop().indentifier;
  }
  
  printArray(out);
  println("evalRPN: " + evalRPN(out));
  return output;
}

int evalRPN(ArrayList<RPNToken> rpn) throws Exception{
  Stack stack = new Stack();
  
  for(int i = 0; i < rpn.size(); i++){
    RPNToken tok = rpn.get(i);
    if(tok.precedence == 0){
      stack.push(tok);
    }else{
      Token var2 = tryInt(stack.pop().indentifier);
      Token var1 = tryInt(stack.pop().indentifier);
      switch(tok.indentifier){
        case "|": // Bitwise OR
          stack.push(new RPNToken(str(var1.Integer | var2.Integer), 0));
          break;
        
        case "^": // Bitwise XOR
          stack.push(new RPNToken(str(var1.Integer ^ var2.Integer), 0));
          break;
        
        case "&": // Bitwise AND
          stack.push(new RPNToken(str(var1.Integer & var2.Integer), 0));
          break;
        
        case "+": // Addition
          stack.push(new RPNToken(str(var1.Integer + var2.Integer), 0));
          break;
        case "-": // Subtraction
          stack.push(new RPNToken(str(var1.Integer - var2.Integer), 0));
          break;
        
        case "*": // Multiplication
          stack.push(new RPNToken(str(var1.Integer * var2.Integer), 0));
          break;
        case "/": // Division
          stack.push(new RPNToken(str(var1.Integer / var2.Integer), 0));
          break;
        case "%": // Modulo
          stack.push(new RPNToken(str(var1.Integer % var2.Integer), 0));
          break;
      }
    }
  }
  
  return tryInt(stack.pop().indentifier).Integer;
}
