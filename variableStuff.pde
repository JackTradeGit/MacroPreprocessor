enum TokenType{
  Integer,
  //Float, // might need to be converted to hex format for some assemblers
  String,
  Char, // to be used for character arithmetic (sbc 'A' - '0')
  Byte, // for db (Define Byte)
  Word, // for dw (Define Word)
  RWord, // for drw (Define Reverse Word)
  Struct, // struct with named members (variables)
  Array, // array of unnamed variables
  Argument, // macro argument
  Variable, // global variable
  Function, // built-in function
  StackFunction, // stack function
  FileFunction, // file functions
  Builtin, // built-in variables
  Error, // error output
}

class Token{
  TokenType Type;
  String String;
  int Integer;
  //float Float;
  char Char;
  boolean Number;
  int nextIndex;
  
  Token(String s){
    String = s;
    Type = TokenType.String;
  }
  
  Token(String s, int i){
    String = s;
    Integer = i;
    Number = true;
    Type = TokenType.Integer;
  }
  
  Token(String s, int i, boolean n){
    String = s;
    if(n){
      Integer = i;
    }else{
      nextIndex = i;
    }
    Number = n;
    Type = n ? TokenType.Integer : TokenType.String;
  }
  
  Token(String s, TokenType t){
    String = s;
    Type = t;
  }
  
  Token(String s, int n, TokenType t){
    String = s;
    nextIndex = n;
    Type = t;
  }
  
  String getNumber(){
    switch(Type){
      case Integer: return "" + Integer;
      default: return "0";
    }
  }
  
  String type(){
    return Type.name();
    //switch(Type){
    //  case Integer: return "Integer";
    //  case Float: return "Float";
    //  case Argument: return "Argument";
    //  case Variable: return "Variable";
    //  case Function: return "Function";
    //  case Error: return "Error";
    //  case String:  return "String";
    //  case Char:  return "Char";
    //  default: return "Unkown";
    //}
  }
  
  String toString(){
    switch(Type){
      case Integer: return str(Integer);
      case Argument:
      case Variable:
      case Function:
      case Error:
      case String: return String;
      default: return "";
    }
  }
}

void parseLet() throws Exception{
  parseLet(getNextToken(true).String, getNextToken(true).String, getNextToken(true).String);
}

void parseLet(String variable, String action, String secondToken) throws Exception{
  //println("parseLet: [" + variable + "](" + parseVariables(_Vars.hasKey(variable) ? _Vars.get(variable) : "0") + ") " + action + " [" + secondToken + "](" + parseVariables(_Vars.hasKey(secondToken) ? _Vars.get(secondToken) : "0") + ")");
  switch(action){
    case "++":
      updateVariable(variable, str(parseVariables(_Vars.hasKey(variable) ? _Vars.get(variable) : "0").Integer + 1));
      return;
    
    case "--":
      updateVariable(variable, str(parseVariables(_Vars.hasKey(variable) ? _Vars.get(variable) : "0").Integer - 1));
      return;
  }
  
  Token firstVar = parseVariables(_Vars.hasKey(variable) ? _Vars.get(variable) : "0");
  Token secondVar = parseVariables(secondToken);
  if(hyperVerboseOutput){ println("parseLet: [" + variable + "](" + firstVar + ") " + action + " [" + secondToken + "](" + secondVar + ")"); }
  
  if(firstVar.Number && secondVar.Number){
    updateVariable(variable, str(parseLet(firstVar.Integer, action, secondVar.Integer)));
  }else{
    switch(action){
      case "+=":
        if(_Vars.hasKey(variable)){ updateVariable(variable, _Vars.get(variable) + secondVar.String); }
        else{ updateVariable(variable, secondVar.String); }
        break;
      
      case "-=":
        if(_Vars.hasKey(variable)){ updateVariable(variable, _Vars.get(variable).replace(secondVar.String, "")); }
        break;
      
      case "=":
        // println(".let " + variable + " = " + secondVar.String);
        updateVariable(variable, secondVar.String);
        break;
    }
  }
}

void updateVariable(String var_, String value_){
  _Vars.set(var_, value_);
  
  if(var_.startsWith("__")){
    value_ = stripStr(value_); // strip leading and trailing "
    switch(var_){
      //case "__ext_db": ext_db = value_; break;
      
      default:
        boolean valueBool = false;
    
        switch(value_.toLowerCase()){
          case "true": valueBool = true; break;
          case "false": break;
          default:
            Token tmp = null; // might want to do this at top of function, then switch on tmp.Type
            try{ tmp = parseVariables(value_); }
            catch(Exception e){ log(Log.Always, Log.Error, Log.Console, "How in the heck did you create an error while setting a variable!? " + e.toString()); }
            
            if(tmp != null && tmp.Number){
              switch(var_){ // update numerical directive variables
                case "__minLogLevel": minLogLevel = tmp.Integer; break;
              }
            }
            return;
        }
        
        switch(var_){ // update boolean directive variables
          case "__maintainComments": maintainComments = valueBool; break;
          case "__showLines": showLines = valueBool; break;
          case "__concatenateFiles": concatenateFiles = valueBool; break;
          case "__hyperVerboseOutput": hyperVerboseOutput = valueBool; break;
          case "__initEmptyStacks": initEmptyStacks = valueBool; break;
          case "__ignoreMacroRecreate": ignoreMacroRecreate = valueBool; break;
        }
        break;
    }
  }
}

// TODO: would it make more sense for parseLet to handle int/float stuff and return a VariableReturn?
int parseLet(int firstVar, String action, int secondVar){
  switch(action){
    case "+=":
      return firstVar + secondVar; // check if integers are equal
    
    case "-=":
      return firstVar - secondVar;
    
    case "*=":
      return firstVar * secondVar;
    
    case "/=":
      return firstVar / secondVar;
    
    case "%=":
      return firstVar % secondVar;
    
    case "&=":
      return firstVar & secondVar;
    
    case "|=":
      return firstVar | secondVar;
    
    case "^=":
      return firstVar ^ secondVar;
    
    default:
      return secondVar;
  }
}

//String getGlobalVariable(String name, boolean checkMacroArgs);
//String getMacroArgument(String name, boolean checkGlobalVars);

String getVariable(String name, boolean global) throws Exception{
  //println("getVariable: " + name + ", " + global);
  //println(getIndex());
  if(global && _Vars != null && _Vars.hasKey(name)){
    return _Vars.get(name);
  }else if(!global){
    MacroArg[] lineMacroArgs = CurrentMacroArgs;
    //print("lineMacroArgs: ");printArray(lineMacroArgs);
    if(lineMacroArgs != null && CurrentWorker.Macro != null){
      MacroArg[] curMacro = CurrentWorker.Macro.Args;
      //print("curMacro: ");print("<" + curMacro.length + ">");printArray(curMacro);
      for(int a = 0; a < curMacro.length; a++){
        // if(name is number)
        //   return curMacro[name.integer];
        //   // this would give us the ability to handle an unknown-at-asm-time amount of macro args
        //   // allowing us to pass an 'unlimited' amount of args to a macro, and then handle it in a loop
        //   // would the proper term be function overloading? even though its a macro?
        //   // might be easier to have a #function to get macro args by index rather than complicate getVariable()...
        // else if...
        if(curMacro[a].Name.equals(name)){
          if(a >= lineMacroArgs.length || lineMacroArgs[a].Name.length() == 0){ // ["this","is","a"], ["this","","","token"]
            if(curMacro[a].Value != null){ return curMacro[a].Value; }
            else{ return "\\!{macro arg '" + name + "' does not have a default value!}"; }
          }else{
            return parseVariables(lineMacroArgs[a].Name).toString();
          }
        }
      }
    }
  }
  
  return "\\!{getVariable:unknown_" + (global ? "var" : "arg") + ", " + name + "}";
}

String getBuiltin(String name){
  switch(name){
    case "@": return str(getIndex()); // get current file index
    case "*": return str(_output.size() + 1); // get total output line count
    case "filename": return CurrentWorker.File.file.Name; // get current file name
    case "argc": return str(CurrentMacroArgs != null ? CurrentMacroArgs.length : 0); // how many args does this macro instance have?
    case "versionMajor": return _version_major; // allow getting the version of the program
    case "versionMinor": return _version_minor; // allow getting the version of the program
    case "versionPatch": return _version_patch; // allow getting the version of the program
    case "versionRC": return _version_preRelease; // allow getting the version of the program
    case "version": return _VERSION; // allow getting the version of the program
  }
  
  return "\\!{getBuiltin:unknown_var, " + name + "}";
}

/*
  %identifier = macro argument
  %%id = global variable
  %?id = drop '?' and pass un-parsed "%id" onwards (allows deferring var parsing through several macros or assignments)
  %??id = drop one '?' and pass "%?id"
  %#id = drop leading "%#" and padd "id" (allows building macros with macros)
  %?#id = drop '?' and pass "%#id"
  
  change syntax? to \%{identifier} or? \%identifier%
    allows picking out stuff from anywhere in the code (strings, labels, args, etc.)
    and allows adding extra stuff \%{passCount, identifier}
    maybe seperate symbol per type? (\% = macro arg, \& = global var, \# = built-in function)
      macro arg would be \%{identifier} or? \%identifier%
      global var would be \&{identifier} or? \&identifier&
      built-in functions syntax could be \#{func, (arg, arg2)} or? \#func{arg1, arg2} or? \#func{arg1, arg2}#
      using {} grabs attention better...
*/

Token parseVariables(String line) throws Exception{ // going through entire line to convert remaining bits into final output
  if(hyperVerboseOutput){ println("parseVariables: " + line); }
  if(line == null){ return null; } // new VariableReturn("");
  String value = "";
  
  for(int i = 0; i < line.length(); i++){
    char c = line.charAt(i);
    
    switch(c){
      case '\\':
        if(hyperVerboseOutput){ println("parseVariables:cleanEscape"); }
        Token output = cleanEscape(line, i, true);
        i = output.nextIndex;
        value += output.String;
        break;
      
      default:
        value += c;
        break;
    }
  }
  
  if(value.length() > 0){
    Token tmp = tryInt(value);
    if(tmp.Number){ return tmp; }
  }
  
  return new Token(value);
}
