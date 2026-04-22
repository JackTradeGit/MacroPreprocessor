boolean checkIf(boolean default_) throws Exception{
  return checkIf(getNextToken(true).String, getNextToken(true).String, getNextToken(true).String, getNextToken(true).String, default_);
}

boolean checkIf(String firstToken, String action, String secondToken, String thirdToken, boolean default_) throws Exception{
  Token firstVar = parseVariables(firstToken);
  Token secondVar = parseVariables(secondToken);
  if(firstToken.equals("")){ return default_; } // || action.equals("") || secondToken.string.equals("")
  
  if(firstVar.Number == false || secondVar.Number == false){
    logVerbose(Log.Minimum, Log.Function, Log.Console, "checkIf: [" + firstToken + "](" + firstVar + ") " + action + " [" + secondToken + "](" + secondVar + ")");
    switch(action){
      case "==":
        // println("checkIf: " + firstToken + "(" + firstVar.String + ") ?=? " + secondVar.String);
        return firstVar.String.equals(secondVar.String); // check if strings are equal
      
      case "!=":
        return !firstVar.String.equals(secondVar.String);
      
      case "": // check if firstVar.String is true/false, or if firstToken.string is a defined variable
        switch(firstVar.String){
          case "true": return true;
          case "false": return false;
          default: return _Vars.hasKey(firstToken);
        }
      
      default:
        log(Log.Always, Log.Error, Log.Output, "checkIf.string.unknownOperator: " + action);
        return default_;
    }
  }else{
    int comp = Integer.compare(firstVar.Integer, secondVar.Integer);
    boolean invert = false;
    if(thirdToken == null || thirdToken.equals("") || thirdToken.startsWith(";")){
      logVerbose(Log.Minimum, Log.Function, Log.Console, "checkIf: [" + firstToken + "](" + firstVar + ") " + action + " [" + secondToken + "](" + secondVar + ")");
      switch(action){
        case "==": // same
          return comp == 0;
        
        case "!=": // not same
          return comp != 0;
        
        case ">": // greater than
          return comp > 0;
        
        case "<": // less than
          return comp < 0;
        
        case ">=": // greater than or equal
          return comp >= 0;
        
        case "<=": // less than or equal
          return comp <= 0;
        
        default:
          log(Log.Always, Log.Error, Log.Output, "checkCondition.twovar.unknownOperator: " + action);
          return default_;
      }
    }else{
      Token thirdVar = parseVariables(thirdToken);
      logVerbose(Log.Minimum, Log.Function, Log.Console, "checkIf: [" + firstToken + "](" + firstVar + ") " + action + " [" + secondToken + "](" + secondVar + ")" + " [" + thirdToken + "](" + thirdVar + ")");
      switch(action){
        case "<!>": // not between
          invert = true;
        case "<>": // between
          if(thirdVar.Number != true){
            return default_; // NAN
          }else{
            int comp2 = Integer.compare(firstVar.Integer, thirdVar.Integer);
            return (comp > 0 && comp2 < 0) ^ invert; // v2 < v1 < v3
          }
        
        case "<!=>": // not between or equal
          invert = true;
        case "<=>": // between or equal
          if(thirdVar.Number != true){
            return default_; // NAN
          }else{
            int comp2 = Integer.compare(firstVar.Integer, thirdVar.Integer);
            return ((comp > 0 && comp2 < 0) || comp == 0 || comp2 == 0) ^ invert; // v2 <= v1 <= v3
          }
        
        default:
          log(Log.Always, Log.Error, Log.Output, "checkCondition.trivar.unknownOperator: " + action);
          return default_;
      }
    }
  }
}

boolean checkCase() throws Exception{
  //VariableReturn switchValue = parseVariables(peekMacroArgs()[0]);
  int state = 0;
  StringList output = new StringList();
  
  Token token = getNextToken(true);
  for(; CurrentInputIndex < CurrentLineInput.length() && state != -1; CurrentInputIndex++){
    switch(state){
      case 0:
        switch(token.String){
          case "[": // start of value list
            state = 1;
            break;
          default: // must be a single value
            if(CurrentMacroArgs != null){ return checkIf(CurrentMacroArgs[0].Name, "==", token.String, null, false); }
            else{ return false; }
        }
        break;
      
      case 1:
        switch(token.String){
          case "]": state = -1; break; // end of value list
          case "..": state = 2; break; // denotes value range
          case ",": break; // eat value seperator
          default: output.append(token.String); break; // must be a value
        }
        break;
      
      case 2: // denotes value range {Ruby range syntax} ([1..4] == [1,2,3,4])([1,2,10..13] == [1,2,10,11,12,13])([1..4,10..8] == [1,2,3,4,10,9,8])
        if(output.size() > 0){
          for(int i = int(output.get(output.size()-1)) + 1; i <= int(token.String); i++){ output.append(str(i)); }
        }else{
          for(int i = 0; i <= int(token.String); i++){ output.append(str(i)); }
        }
        state = 1;
        break;
    }
  }
  
  return false;
}
