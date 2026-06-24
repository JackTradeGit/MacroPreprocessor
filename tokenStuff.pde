Token getNextToken(boolean allowEscape) throws Exception{
  logVerbose(Log.Minimum, Log.Function, Log.Console, "getNextToken: \"" + CurrentLineInput + "\" @ [" + CurrentInputIndex + "]");
  String token = "";
  int state = 0;
  boolean inString = false;
  boolean gotString = false;
  int parenDepth = 0;
  
  for(; CurrentInputIndex < CurrentLineInput.length() && state != -1; CurrentInputIndex++){
    char c = CurrentLineInput.charAt(CurrentInputIndex);
    switch(state){
      case 0:
        switch(c){
          case ';': // hit comment, so end of line
            if(!inString){
              if(gotString == false){ // ';' was first char, so return it to caller
                token += c;
              }
              state = -1;
            }
            break;
          
          case '"':
            token += c;
            inString = !inString;
            gotString = true;
            break;
          
          case '\\':
            if(allowEscape == true){
              logVerbose(Log.Minimum, Log.Function, Log.Console, "getNextToken:0:cleanEscape");
              gotString = true;
              Token output = cleanEscape(CurrentLineInput, CurrentInputIndex, false);
              CurrentInputIndex = output.nextIndex;
              token += output.String;
            }else{
              token += c;
            }
            break;
          
          case ' ':
          case '\t':
            if(inString){
              token += c;
              gotString = true;
            }else{
              state = gotString ? -1 : 0;
            }
            break;
          
          case '(': // do we handle things within paren's as a 'discreet' unit? escaped open-paren are handled by cleanEscape() obviously...
            if(inString){
              token += c;
            }else{
              // we would still need to check for escaped objects and handle them, but no other processing would occur on stuff within paren's...
              parenDepth++; // we would need to correctly handle nested paren's too...
              //token += c;
              gotString = true;
              //state = 1;
            }
            break;
          
          case ')': // perhaps we should also be handling unbalanced paren's too?
            if(inString){
              token += c;
            }else{
              parenDepth--;
              if(parenDepth == 0){
                //state = 0; // what else do we have to handle here?
              }
            }
            break;
          
          default:
            token += c;
            gotString = true;
            break;
        }
        break;
      
      case 1:
        switch(c){
          case '(': // do we handle things within paren's as a 'discreet' unit?
            // we would still need to check for escaped objects and handle them, but no other processing would occur on stuff within paren's...
            parenDepth++; // we would need to correctly handle nested paren's too...
            break;
          
          case '\\': // escaped open-paren are still handled by cleanEscape() obviously...
            if(allowEscape == true){
              logVerbose(Log.Minimum, Log.Function, Log.Console, "getNextToken:1:cleanEscape");
              gotString = true;
              Token output = cleanEscape(CurrentLineInput, CurrentInputIndex, false);
              CurrentInputIndex = output.nextIndex;
              token += output.String;
            }else{
              token += c;
            }
            break;
          
          case ')':
            parenDepth--;
            if(parenDepth == 0){
              state = 0; // what else do we have to handle here?
            }
            break;
        }
        break;
    }
  }
  
  if(CurrentLineInput.length() == 1 && token.equals("")){
    token = CurrentLineInput;
    CurrentInputIndex++;
  }
  
  logVerbose(Log.Minimum, Log.Function, Log.Console, "getNextToken:output = \"" + token + "\" @ [" + CurrentInputIndex + "]");
  return new Token(token, CurrentInputIndex, false);
}

enum CleanEscapeState{
  Done,
  Initial,
  StartCurly,
  BuildCurly,
  StartHex,
  EndHex,
  BuildOctal,
  RubyFirst,
  RubyNext,
  RubyFinal
}
String hexNotUnicode(String input){
  return hexNotUnicode ? "0x" + input : "\\u{" + input + "}";
}
Token cleanEscape(String line, int index, boolean runFunction) throws Exception{
  //println("[" + line + "]{" + index + "}");
  if(line.length() > 0 && index < line.length() && line.charAt(index) == '\\'){ index++; } // eat the incoming '\\'
  
  String token = "";
  CleanEscapeState state = CleanEscapeState.Initial;
  TokenType type = TokenType.String;
  boolean outputEscape = false;
  boolean wasUnicode = false;
  
  for(; index < line.length() && state != CleanEscapeState.Done; index++){
    char c = line.charAt(index);
    //print(c);
    switch(state){
      case Initial:
        state = CleanEscapeState.Done; // default is to finish after one character
        switch(c){
          case '0': // NULL or Octal Character (\033)
            state = CleanEscapeState.BuildOctal;
            break;
          case 'a': // BELL
            token += hexNotUnicode("07");
            break;
          case 'b': // BACKSPACE
            token += hexNotUnicode("08");
            break;
          case 'e': // ESCAPE SEQUENCE (\e, \x1B, \033, 27, ^[)
            token += hexNotUnicode("1B");
            break;
          case 'f': // FORM FEED
            token += hexNotUnicode("0C");
            break;
          case 'n': // NEWLINE
            token += hexNotUnicode("0A");
            break;
          case 'r': // CARRIAGE RETURN
            token += hexNotUnicode("0D");
            break;
          case 't': // TAB
            token += hexNotUnicode("09");
            break;
          case 'u': // unicode
            wasUnicode = true;
            state = CleanEscapeState.StartCurly;
            break;
          case 'v': // VERTICAL TAB
            token += hexNotUnicode("0B");
            break;
          case 'x': // Hexadecimal Character (\x1B)
            state = CleanEscapeState.StartHex;
            break;
          case '!': // error output
            token += "\\!";
            outputEscape = true;
            type = TokenType.Error;
            state = CleanEscapeState.StartCurly;
            break;
          case '#': // built-in function
            type = TokenType.Function;
            state = CleanEscapeState.StartCurly;
            break;
          case '%': // macro arg
            type = TokenType.Argument;
            state = CleanEscapeState.StartCurly;
            break;
          case '&': // global var
            type = TokenType.Variable;
            state = CleanEscapeState.StartCurly;
            break;
          case '$': // built-in var
            type = TokenType.Builtin;
            state = CleanEscapeState.StartCurly;
            break;
          case '~': // transitory macro variable
            //ArrayList<StringDict> _TmpMacroVars;
            //when a macro is encountered, a new StringDict is pushed to _TmpMacroVars
            //from there, any number of TMVs can be made and used
            //when the macro ends, popFileIfLastLine()? or popMacroArgs()? removes the last StringDict from _TmpMacroVars
            //this allows and endless number of temporary variables that are contained within their own macro instance
            break;
          case '^': // stack operations
            type = TokenType.StackFunction;
            state = CleanEscapeState.StartCurly;
            break;
          case '>': // file operations
            type = TokenType.FileFunction;
            state = CleanEscapeState.StartCurly;
            break;
          case '(': // escaped open-paren means we need to do infixToRPN stuff
            // doing infix to RPN conversion and then emitting the result is useful for asm-time forth stuff
            //token += lineToRPN(line, index);
            break;
          case '[': // Ruby Range Syntax (e.g. [1..4] == [1,2,3,4])([1,2,10..13] == [1,2,10,11,12,13])([1..4,10..8] == [1,2,3,4,10,9,8])
            state = CleanEscapeState.RubyFirst; // look for first number or ..
            break;
          default:
            token += hexNotUnicode(hex(c));
            break;
        }
        break;
      
      case StartCurly: // start unicode
        if(c == '{'){
          if(outputEscape){ token += c; }
          state = CleanEscapeState.BuildCurly;
        }
        break;
      
      case BuildCurly: // build unicode
        switch(c){
          case '}':
            if(outputEscape){ token += c; }
            if(wasUnicode){ token = hexNotUnicode(token); }
            state = CleanEscapeState.Done;
            break;
          
          case '\\':
            if((index == line.length() - 1) || (index + 1 < line.length() && (line.charAt(index + 1) == ' ' || line.charAt(index + 1) == ';'))){
              // if \ is the final character on line or the following character is a space or ;
              // then we need to continue onto next line for more stuff, as this is a multi-line thing
              //incIndex();
              //line = getLine();
              //index = 0;
              // not that simple though, as caller may still be using old line...
              // we may have to make line be global?
            }//else{
              Token output = cleanEscape(line, index, outputEscape); // if we're not stripping escape tokens, then don't do it on recurse
              index = output.nextIndex;
              token += output.String;
            //}
            break;
          
          default:
            token += c;
            break;
        }
        break;
      
      case StartHex:
        token += c;
        state = CleanEscapeState.EndHex;
        break;
      
      case EndHex:
        token = hexNotUnicode(token + c);
        state = CleanEscapeState.Done;
        break;
      
      case BuildOctal:
        if(isOctal(c)){
          token += c;
        }else{
          if(token.length() == 0){ token = hexNotUnicode("00"); } // escaped NULL
          else{ token = hexNotUnicode(octalToHex(token)); } // escaped octal
          index--;
          state = CleanEscapeState.Done;
        }
        break;
      
      case RubyFirst: // look for first number or '..' --- a ']' would be an error (empty range)
      case RubyNext: // look for next number '..' ']' --- split on ',' or ' '
      case RubyFinal: // found all sections of range, go through it and produce final output
        token += c;
        if(c == ']'){
          token = "\\!{Ruby Range Syntax is not yet implemented! - [" + token + "}";
          state = CleanEscapeState.Done;
        }
        break;
      
      default:
        token = "\\!{CleanEscape: state machine in unknown state, " + state.name() + "}";
        state = CleanEscapeState.Done;
        break;
    }
  }
  
  switch(state){ // if we hit the end of input without finishing a state...
    case Done:
      break;
    
    case BuildOctal:
      if(token.length() == 0){ token = hexNotUnicode("00"); } // escaped NULL
      else{ token = hexNotUnicode(octalToHex(token)); } // escaped octal
      break;
    
    default:
      token = "\\!{CleanEscape: input resulted in state machine ending in unfinished state, " + state.name() + "}";
      break;
  }
  
  switch(type){
    case Argument: // macro argument
      //println("cleanEscape:Argument " + token);
      token = getVariable(token, false); // don't check global variables
      break;
    case Variable: // global variable
      token = getVariable(token, true); // don't check macro arguments
      break;
    case Function: // built-in function
      logVerbose(Log.Minimum, Log.Function, Log.Console, "cleanEscape:parseFunction = " + runFunction);
      if(runFunction){ // for some reason (bad programming probably...) parseFunction is being called twice for every function
        token = parseFunction(token); // parse function
      }else{
        token = "\\#{" + token + "}"; // re-encase function for future parsing
      }
      break;
    case StackFunction:
      logVerbose(Log.Minimum, Log.Function, Log.Console, "cleanEscape:parseStackFunction = " + runFunction);
      if(runFunction){ // same issue as parseFunction!
        token = parseStackFunction(token);
      }else{
        token = "\\^{" + token + "}"; // re-encase function for future parsing
      }
      break;
    case FileFunction:
      logVerbose(Log.Minimum, Log.Function, Log.Console, "cleanEscape:parseFileFunction = " + runFunction);
      if(runFunction){ // same issue as parseFunction!
        token = parseFileFunction(token);
      }else{
        token = "\\>{" + token + "}"; // re-encase function for future parsing
      }
    case Builtin: // built-in variable
      token = getBuiltin(token);
      break;
    default:
      // token = token;
      break;
  }
  
  //VariableReturn out = new VariableReturn(token, index-1, type);
  //println(out.type() + ":" + out + ";" + token);
  return new Token(token, index-1, false); // token-1 due to increment after use!
}
