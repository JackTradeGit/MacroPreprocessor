String cleanUnicode(String input){ // \\{0022} counts as more characters than it should...
  String output = "";
  int state = 0;
  String code = "";
  for(int i = 0; i < input.length(); i++){
    char c = input.charAt(i);
    switch(state){
      case 0:
        switch(c){
          case '\\':
            state = 1;
            break;
          
          default:
            output += c;
            break;
        }
        break;
      
      case 1:
        switch(c){
          case 'u':
            state = 2;
            break;
          
          default:
            output += "\\" + c;
            state = 0;
            break;
        }
        break;
      
      case 2:
        if(isHex(c)){
          code += c;
        }else if(c == '}'){
          output += char(parseInt(code));
          code = "";
          state = 0;
        }
        break;
    }
  }
  
  return output;
}

String stripStr(String input){
  if(input == null){ return null; }
  input = input.startsWith("\"") ? input.substring(1) : input; // strip leading and trailing "
  return input.endsWith("\"") ? input.substring(0, input.length()-1) : input;
}

String lowerCase(String input){
  if(input == null){ return null; }
  return input.toLowerCase();
}

String answerToStr(String func, String name, Object answer){
  if (answer instanceof Boolean) 
    return str(((Boolean) answer).booleanValue());
  else if (answer instanceof Integer)
    return str(((Integer) answer).intValue());
  else if (answer instanceof Float)
    return str(((Float) answer).floatValue());
  //else if (answer instanceof Double)
    //return str(((Double) answer).doubleValue());
  else
    return "\\!{parseFunction." + func + ": " + name + " is of unknown type!}";
}

String[] splitVersion(String input){
  input = input.toLowerCase();
  input = input.startsWith("v") ? input.substring(1) : input; // strip leading 'V'
  
  String[] tmp = split(input, "."); // 2.2.0-pr.1 -> [2, 2, 0-pr, 1]
  
  if(tmp.length > 3){
    tmp[2] = split(tmp[2], "-")[0]; // 0-pr -> 0
  }
  
  String[] out = new String[4];
  for(int i = 0; i < out.length && i < tmp.length; i++){
    out[i] = tmp[i];
  }
  
  return out;
}

boolean compareVersions(String version, String action, String first, String second) throws Exception{
  version = stripStr(version);
  action = stripStr(action);
  first = stripStr(first);
  second = stripStr(second);
  
  if(hyperVerboseOutput){ println("compareVersions: " + version + " " + action + " " + first + " " + second); }
  if(version == null){ log(Log.Always, Log.Error, Log.Output, "\\!{compareVersions: version to check is required!"); return false; }
  if(action == null){ log(Log.Always, Log.Error, Log.Output, "\\!{compareVersions: action to try is required!"); return false; }
  if(first == null){ log(Log.Always, Log.Error, Log.Output, "\\!{compareVersions: version to check against is required!}"); return false; }
  
  if(second != null){
    switch(action){
      case "<!=>": // not between or equal
        return compareVersions(version, "<", first, null) || compareVersions(version, ">", second, null);
      
      case "<=>": // between or equal
        return compareVersions(version, ">=", first, null) && compareVersions(version, "<=", second, null);
      
      case "<!>": // not between
        return compareVersions(version, "<=", first, null) || compareVersions(version, ">=", second, null);
      
      case "<>": // between
        return compareVersions(version, ">", first, null) && compareVersions(version, "<", second, null);
      
      default:
        log(Log.Minimum, Log.Warning, Log.Output, "; \\!{compareVersions: only min is required to use #check/compareVer, max is unnecessary.}");
        break;
    }
  }
  
  String[] verArr = splitVersion(version);
  String[] v1 = splitVersion(first);
  
  boolean cond = true;
  for(int i = 0; i < verArr.length; i++){
    if(verArr[i] == null || v1[i] == null){
      cond = false;
      break;
    }
    cond &= v1[i].equals(verArr[i]); // _version == v1
  }
  
  switch(action){
    case "!=": // not same
      return !cond;
    
    case "==": // same
      return cond;
    
    case ">=": // greater than or equal
      if(cond == true){ return true; }
      action = ">";
      break;
    
    case "<=": // less than or equal
      if(cond == true){ return true; }
      action = "<";
      break;
    
    case "<!=>": // not between or equal
    case "<=>": // between or equal
    case "<!>": // not between
    case "<>": // between
      log(Log.Always, Log.Error, Log.Output, "\\!{compareVersions: checking between requires both min and max!}");
      return false;
  }
  
  cond = false;
  switch(action){
    case ">": // greater than
      for(int i = 0; i < verArr.length; i++){
        if(checkIf(verArr[i] != null ? verArr[i] : "-1", ">", v1[i] != null ? v1[i] : "-1", null, false)){
          cond = true;
          break; // break out of loop
        }
      }
      return cond;
    
    case "<": // less than
      for(int i = 0; i < verArr.length; i++){
        //println(verArr[i] + " < " + v1[i] + " = " + checkIf(verArr[i] != null ? verArr[i] : "-1", "<", v1[i] != null ? v1[i] : "-1", null, false));
        if(checkIf(verArr[i] != null ? verArr[i] : "-1", "<", v1[i] != null ? v1[i] : "-1", null, false)){
          cond = true;
          break; // break out of loop
        }
      }
      return cond;
  }
  
  log(Log.Always, Log.Error, Log.Output, "\\!{compareVersions: " + action + " is an unknown action!}");
  return false;
}

String getLabelUUID(){
  return UUID.randomUUID().toString().replace('-', '_');
}

boolean isAlpha(char c){
  return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
}

boolean isHex(char c){
  return isNumber(c) || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}

boolean isBinary(char c){
  return (c == '0' || c == '1' || c == '|');
}

boolean isOctal(char c){
  return c >= '0' && c <= '7';
}

boolean isNumber(char c){
  return c >= '0' && c <= '9';
}

boolean isWhitespace(char c){
  return c == ' ' || c == '\t' || c == '\n' || c == '\r';
}

String octalToHex(String input_){
  if(input_ == null){ return null; }
  int value = 0;
  for(int i = 0; i < input_.length(); i++){
    value <<= 3;
    value |= input_.charAt(i) - 0x30;
  }
  return hex(value,4);
}

void outputLine(boolean skip) throws Exception{
  if(skip == true){
    if(hyperVerboseOutput){ println("outputLine skipped: \"" + CurrentLineOutput + "\""); }
  }else{
    boolean empty = isLineEmpty(CurrentLineOutput);
    if(empty){ // the current line is blank...
      if(!isLineEmpty(getLastOutputLine())){ // ...but the last one wasn't...
        _output.append(""); // ...so output a blank line for aesthetics.
      }
    }else{ // the current line is not blank...
      String tmp = cleanComments(parseVariables(CurrentLineOutput).String); // ...so clean up any remaining escaped stuff or comments...
      if(tmp != null && tmp.length() > 0){ // ...and if not null or empty afterwards...
        appendOutput(tmp);
      }
    }
  }
}

boolean isLineEmpty(String line){
  if(line == null || line.strip().length() == 0){ return true; }
  for(int i = 0; i < line.length(); i++){
    char c = line.charAt(i);
    if(c == ';'){ return true; }
    if(!isWhitespace(c)){ return false; }
  }
  return true;
}

String cleanComments(String line){
  if(maintainComments){ return line; }
  String output = "";
  int state = 0;
  boolean inString = false;
  
  for(int i = 0; i < line.length() && state != -1; i++){
    char c = line.charAt(i);
    
    switch(c){
      case '"':
        output += c;
        inString = !inString;
        break;
      
      case ';':
        if(inString){
          output += c;
        }else{
          state = -1;
        }
        break;
      
      default:
        output += c;
        break;
    }
  }
  
  return output;
}

void cleanMultilineComments() throws Exception{
  int depth = 0;
  for(; getIndex() < getFileLength(); incIndex()){
    CurrentLineInput = getLine();
    if(maintainComments){ _output.append("; " + CurrentLineInput); }
    CurrentInputIndex = 0;
    Token token = getNextToken(false);
    switch(token.String){
      case "/*":
        depth++; // handle nested multiline comments
        continue;
      
      case "*/":
        depth--;
        if(depth <= 0){
          //if(token.nextIndex < line.length()){ // this won't work due to processInput() always starting at beginning of line...
            //decIndex(); // need to --lineIndex due to being ++ on next iteration of processInput()
          //} // as such, code can't follow the "*/" of a multiline comment...
          return; // end of (nested) multiline comments
        }
        continue; // end of current nested multiline comment
    }
    
    //println(line + ":" + depth);
    while(token.nextIndex < CurrentLineInput.length()){ // handle multiline comments that exist on a single line
      switch(token.String){
        case "/*":
          depth++; // handle nested multiline comments
          break;
        
        case "*/":
          depth--;
          if(depth <= 0){
            //if(token.nextIndex < line.length()){ // this won't work due to processInput() always starting at beginning of line...
              //decIndex(); // need to --lineIndex due to being ++ on next iteration of processInput()
            //} // as such, code can't follow the "*/" of a multiline comment...
            return; // end of (nested) multiline comments
          }
          break; // end of current nested multiline comment
      }
      token = getNextToken(false); // get next token on same line
    }
  }
}

Token tryInt(String in) throws Exception{
  String output = "";
  int state = 0;
  boolean valid = true;
  
  //perform self check on number overflow?
  //should work for any radix?
  //radix = 10;
  //notOverflow = intVal < (Integer.MAX_VALUE - digVal) / radix;
  //if(notOverflow){ intVal = (intVal * radix) + digVal; }
  //else{ } // value (would) overflow, therefore we need to error out
  
  char c = ' ';
  for(int i = 0; i < in.length(); i++){
    c = in.charAt(i);
    switch(state){
      case 0:
        switch(c){
          case '0':
            state = 1;
            break;
          
          case ' ':
          case '\t':
            break;
          
          default:
            output += c;
            state = 5;
            break;
        }
        break;
      
      case 1:
        switch(c){
          case 'x': // hexadecimal
            state = 2;
            break;
          
          case 'b': // binary
            state = 3;
            break;
          
          case 'o': // octal
            state = 4;
            break;
          
          default: // decimal
            state = 5;
            break;
        }
        break;
      
      case 2: // hexadecimal
        if(isHex(c)){
          valid = true;
          output += c;
        }if(c == ' ' || c == '\t'){
          valid = true;
          state = -1;
        }else{
          valid = false;
          state = -1;
        }
        break;
      
      case 3: // binary
        if(isBinary(c)){
          valid = true;
          output += c;
        }if(c == ' ' || c == '\t'){
          valid = true;
          state = -1;
        }else{
          valid = false;
          state = -1;
        }
        break;
      
      case 4: // octal
        if(isOctal(c)){
          valid = true;
          output += c;
        }if(c == ' ' || c == '\t'){
          valid = true;
          state = -1;
        }else{
          valid = false;
          state = -1;
        }
        break;
      
      case 5: // decimal
        if(isNumber(c)){
          valid = true;
          output += c;
        //}else if(c == ' ' || c == '\t'){
          //valid = true;
          //state = -1;
        }else{
          valid = false;
          state = -1;
        }
        break;
    }
  }
  
  switch(state){
    case 1: // just '0' as input!
      output = "0";
      state = 5;
      break;
    case 5:
      if(!isNumber(c)){
        valid = false;
      }
      break;
  }
  
  int value = 0;
  if(valid){
    switch(state){
      case 2: // hexadecimal
        value = parseInt(output, 16);
        break;
      
      case 3: // binary
        value = parseInt(output, 2);
        break;
      
      case 4: // octal
        value = parseInt(output, 8);
        break;
      
      case 5: // decimal
        value = parseInt(output, 10);
        break;
      
      default: // if a line is just spaces or tabs...
        valid = false;
        break;
    }
  }
  
  if(valid){
    return new Token(in, value);
  }
  else{ return new Token(in); }
}
