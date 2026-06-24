import java.util.UUID; // used for generation of unique local labels
import java.util.Map; // used for handling of _TmpGlobalVars
import java.util.Arrays;
import java.io.File;
import java.util.Comparator;
import org.quark.jasmine.*; // used for complex expression evaluation (#eval)

StringList _output;
String _outputFile;
boolean _exit = false;
boolean _run = false;
StringDict _Vars; // variables that can be changed
StringDict _Equates; // variables that are set once and can't be changed
HashMap<String, String> _TmpGlobalVars; // ditto, but a way to easily save and restore global variables
ArrayList<HashMap<String, String>> _TmpGlobalVarsArr; // ditto, but a way to easily save and restore global variables
HashMap<String, StringList> Stacks; // hashmap of data stacks for use in complex preprocessing

StringList processedFiles;
boolean forceTest = false;

// How many changes, and how much effort, would it be to change _Vars, Stacks, and the other bits, to use Token's?

// boolean directive variables
boolean maintainComments = false; // should comments be passed on, or cleaned up
boolean showLines = false; // show all lines, including 'eaten' ones
boolean concatenateFiles = true; // combine all input files into one output file
boolean initEmptyStacks = false; // will an uninintialized stack be created on push, or generate an error?
boolean ignoreMacroRecreate = false; // will an overwritten macro output a warning?
boolean outputBinaryFile = false; // Do we use saveStrings() or spit out a binary file?
boolean hexNotUnicode = false; // do we output 0x??, or \\u{??} for escaped value?

// integer directive variables
int hyperVerboseOutput = 0; // will all the println's in the universe be printed? (-1 = all, 0 = none)
int minLogLevel = 0; // what's the minimum level of log that will be output? (-1 = all, 0 = none)

PathReturn CurrentDirectory; // current working directory for file includes...
int CurrentInputIndex = 0;
String CurrentLineInput; // current line from input being worked on
String CurrentLineOutput; // current working line for output
StringList _switch_Args; // stack for switch arguments
ArrayList<String[]> _while_Args; // stack for while loop arguments
ArrayList<int[]> _begin_Args; // stack for .begin .again .while .repeat

//processing-java's directory must be added to PATH
//--sketch refers to the directory, not the file
//anything after --run is passed as args
//processing-java.exe --sketch=%~dp0 --run 123 123

// takes in .asm files (w/ includes) and outputs single .obj file

/*
  has to handle includes as well, but should be able to be told not to bother
    #pragma noFloats #include "path/file.ext"
    #include "path/file.ext"
  needs to be told what needs to be converted, and how
    convert to hexadecimal (binary)
      f8(1234.5678)   8 bit floating point number - Quarter-Precision Float (1 byte)
      f16(1234.5678) 16 bit floating point number - Half-Precision Float (2 bytes)
      f32(1234.5678) 32 bit floating point number - Float (4 bytes)
      f64(1234.5678) 64 bit floating point number - Double (8 bytes)
*/

String _program_name = "Macro Preprocessor";
String _version_major = "5";
String _version_minor = "6";
String _version_patch;// = "2";
String _version_preRelease; // = "1"
String[] _version = {_version_major, _version_minor, _version_patch, _version_preRelease};
String _VERSION = buildVersion(_version);
void setup(){
  println(_program_name + " " + _VERSION);
  println("sketchPath() = " + sketchPath());
  
  initCore();
  initBuiltinVars(false);
  
  boolean showHelp = false;
  
  if(args != null){ // allows input from command line
    for (int i = 0; i < args.length && !_exit; i++) {
      String arg = args[i];
      print(arg);
      switch(arg){
        case "--input":
          arg = args[++i]; // get source file
          File extFile = new File(sketchPath(arg + ".asm"));
          if(extFile.exists()){
            PathReturn filename = splitFilepath(arg + ".asm");
            CurrentDirectory = filename;
            println(" " + filename + " [" + filename.Reverse + "]");
            _outputFile = filename.getPath() + filename.Name + ".obj";
            println("--input Arg: Loading " + splitFilepath(sketchPath()), filename);
            getNewFile(splitFilepath(sketchPath()), filename);
            _exit = false;
            _run = true;
          }else{
            println("Error: file passed to --input does not exist! [" + arg + ".asm]");
            showHelp = true;
            _exit = true;
            _run = false;
          }
          break;
        
        case "--var":
          arg = args[++i]; // get name=value
          print(" " + arg);
          String[] pair = split(arg, '=');
          if(pair.length != 2){
            println(" - bad var assignment! - " + arg);
            showHelp = true;
          }else{
            println(" - set variable \"" + pair[0] + "\" to \"" + pair[1] + "\"");
            updateVariable(pair[0], pair[1]);
          }
          break;
        
        case "--help":
          showHelp = true;
          _exit = true;
          _run = false;
          break;
        
        case "--force-test":
          forceTest = true; // Used to make the tests generate their own 'Compare' files...
          break;
        
        case "--self-test":
          println(" - Attempting self-test...");
          File tests_Source = new File(sketchPath("Tests/Source")); // Test source files
          File tests_Destination = new File(sketchPath("Tests/Destination")); // Test output directory
          File tests_Compare = new File(sketchPath("Tests/Compare")); // File to compare outputs to
          
          if(!tests_Source.exists() || !tests_Destination.exists() || !tests_Compare.exists()){
            println("One or more of the 'Tests' directories do not exist!");
            if(!tests_Source.exists()){ println("Tests/Source does not exist!"); }
            if(!tests_Destination.exists()){ println("Tests/Destination does not exist!"); }
            if(!tests_Compare.exists()){ println("Tests/Compare does not exist!"); }
            _exit = true;
            continue;
          }
          
          File[] testFiles = getFiles(tests_Source, true);
          
          for(int j = 0; j < testFiles.length; j++){
            initCore();
            initBuiltinVars(true);
            
            String testName = split(testFiles[j].getName(), '.')[0];
            File testCompare = new File(tests_Compare + "/" + testName + ".bin");
            
            if(forceTest || testCompare.exists()){
              println("Running test [" + testName + "] " + (j + 1) + "/" + testFiles.length);
              _outputFile = tests_Destination + "/" + testName + ".bin";
              
              PathReturn filename = splitFilepath(testFiles[j].getName());
              CurrentDirectory = filename;
              getNewFile(splitFilepath(tests_Source.getAbsolutePath()), filename);
              
              startProcess(false);
              
              if(testCompare.exists()){
                byte[] fileCompare = loadBytes(testCompare);
                byte[] fileDestination = loadBytes(_outputFile);
                
                boolean testPassed = Arrays.equals(fileCompare, fileDestination);
                println(testPassed ? "Test Passed!" : "Test Failed!");
              }
            }else{
              println("Test source file [" + testName + "] does not have a 'Compare' file!");
            }
          }
          _exit = true;
          _run = false;
          break;
        
        default:
          println(" = unknown arg!");
          showHelp = true;
          _exit = true;
          _run = false;
          break;
      }
    }
  }else{
    File mainAsm = new File(sketchPath("main.asm")); // if run from the IDE, we'll either auto run a "main.asm" in the root dir...
    if(mainAsm.exists()){
      println("Main.asm Default: Loading main.asm");
      PathReturn filename = splitFilepath("main.asm");
      CurrentDirectory = filename;
      println(" " + filename + " [" + filename.Reverse + "]");
      _outputFile = filename.getPath() + filename.Name + ".obj";
      getNewFile(splitFilepath(sketchPath()), filename);
      _exit = false; // don't exit...
      _run = true; // ...and begin processing the file
    }else{
      selectInput("Select a file to preprocess:", "fileSelected"); // ...or enable selecting a file via the file browser
      _exit = false; // don't exit...
      _run = false; // ...and wait for file to be selected
    }
  }
  
  if(!_exit && _run){
    startProcess(true);
    _exit = true;
  }
  
  if(showHelp){ printHelp(); }
  if(_exit){ exit(); }
  
  //testRPN();
}

void startProcess(boolean addHeader){
  int time = millis();
  
  if(addHeader){
    _output.append("; This .obj file was produced by: " + _program_name + " " + _VERSION); // append some data to the start of the output file
    _output.append("; " + getLabelUUID());
    _output.append(""); _output.append("");
  }
  
  initBuiltinVars(false);
  
  try{ // make every child function throw Exception?
    // CurrentWorker.getLine(-1); // gives an easy error...
    processInput(0, ParseState.Entry);
  }catch(Exception e){ // allows for soft errors instead of hard ones...
    log(Log.Always, Log.Error, Log.Console, e.toString());
  }
  
  print("Stacks: "); printArray(Stacks);
  print("Variables: "); printArray(_Vars);
  println("Output file: " + _outputFile);
  
  if(!outputBinaryFile){
    saveStrings(_outputFile, _output.toArray());
  }else{
    int totalBytes = 0;
    for(int i = 0; i < _output.size(); i++){
      totalBytes += _output.get(i).length(); // has to be done this way due to saveStrings appending \r\n after every line...
    }
    
    byte[] bytes = new byte[totalBytes];
    int index = 0;
    for(int i = 0; i < _output.size(); i++){
      String line = _output.get(i);
      for(int j = 0; j < line.length(); j++){
        bytes[index++] = (byte)line.charAt(j); // TODO: this does not account for multi-byte characters!
      }
    }
    
    saveBytes(_outputFile, bytes);
  }
  
  print("Total Macros: " + Macros.size());printArray(Macros);
  println("Total Macro Args Pushed: " + MacroArgsStack.size()); // should be 0 when done
  
  println("program ran for: " + (millis() - time) + " millis.");
}

void fileSelected(File selection){
  if(selection == null){
    println("Did not select file to process");
    printHelp();
    exit();
  }else{
    PathReturn filename = splitFilepath(selection.getName());
    CurrentDirectory = filename;
    println(" " + filename + " [" + filename.Reverse + "]");
    _outputFile = new File(selection.getParent(), filename.Name + ".obj").toString();
    println("File Selected: Loading " + splitFilepath(selection.getParent()), filename);
    getNewFile(splitFilepath(selection.getParent()), filename);
    startProcess(true);
    exit();
  }
}

FileHolder getFile(){
  return CurrentWorker.File;
}

int getIndex(){
  return CurrentWorker.LineIndex;
}

void setIndex(int i){
  CurrentWorker.LineIndex = i;
}

void incIndex(){
  CurrentWorker.LineIndex++;
}

void decIndex(){
  CurrentWorker.LineIndex--;
}

String getLine(){
  return CurrentWorker.getLine(CurrentWorker.LineIndex);
}

int getFileLength(){
  return CurrentWorker.getLength();
}

String getFileName(){
  return CurrentWorker.getFileName();
}

void appendOutput(String line){
  if(showLines){ // possibly show where it came from, and then...
    line += getTrace();
  }
  _output.append(line); // ...append it to the output.
}

String getTrace(){ // if we're in a macro, this needs to traverse up the file stack until it hits an actual file
  //String out = getFileName() + " @ " + (getIndex()+1);
  //if(CurrentWorker.Type == WorkerType.Macro){
    
  //}
  return "\t\t\t\t; " + CurrentWorker.getOrigin() + getFileName() + " @ " + (getIndex()+1);
}

String getLastOutputLine(){
  if(_output.size() > 0){
    return _output.get(_output.size() - 1);
  }
  return "";
}

void printHelp(){
  println("Supported command line options:");
  println();
  println("--help - Show this helpful(?) text...");
  println();
  println("--input=<file.ext> - Specify the input file.");
  println("\tOutput filename will be <input-filename>.obj");
  println("\t#include's will be opened and concatenated into a single output file.");
  println();
  println("--var <name=value> - Set a variable to a value.");
  println();
  println("--self-test [<name=value>] - Run tests to ensure Macro Preprocessor is correctly functioning.");
  println("\tThis feature has not been finished yet, and does not currently do anything...");
}

void initCore(){
  _output = new StringList();
  _Vars = new StringDict(); // variables that can be changed
  //_Equates; // variables that are set once and can't be changed
  _TmpGlobalVars = new HashMap<String, String>(); // ditto, but a way to easily save and restore global variables
  _TmpGlobalVarsArr = new ArrayList<HashMap<String, String>>(); // ditto, but a way to easily save and restore global variables
  Stacks = new HashMap<String, StringList>(); // hashmap of data stacks for use in complex preprocessing
  
  processedFiles = new StringList();
  
  _switch_Args = new StringList(); // stack for switch arguments
  _while_Args = new ArrayList<String[]>(); // stack for while loop arguments
  _begin_Args = new ArrayList<int[]>(); // stack for .begin .again .while .repeat
  
  MacroStack = new ArrayList<Macro>(); // stack of macros for (nested) macros
  MacroArgsStack = new ArrayList<MacroArg[]>(); // stack of macro args for (nested) macros
  CurrentMacroArgs = null;
  Macros = new HashMap<String, Macro>(); // hashmap of defined macros
  
  Workers = new ArrayList<Worker>(); // how do we handle which file/macro we're currently working on!?
  CurrentWorker = null;
}

void initBuiltinVars(boolean overwrite){
  // boolean directive variables
  createVariable("__concatenateFiles", "true", overwrite);
  createVariable("__maintainComments", "false", overwrite);
  createVariable("__showLines", "false", overwrite);
  createVariable("__initEmptyStacks", "false", overwrite);
  createVariable("__ignoreMacroRecreate", "false", overwrite);
  createVariable("__outputBinaryFile", "false", overwrite);
  createVariable("__hexNotUnicode", "false", overwrite);
  
  // integer directive variables
  createVariable("__hyperVerboseOutput", "0", overwrite);
  createVariable("__minLogLevel", "0", overwrite);
}
