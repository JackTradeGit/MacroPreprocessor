static class Log{
  static class LogType{
    String prefix;
    String suffix;
    
    LogType(String p, String s){
      prefix = p;
      suffix = s;
    }
  }
  
  final static int Console = 1;
  final static int ConsoleIDX = 0;
  final static int Output = 2;
  final static int OutputIDX = 1;
  final static int ConOut = Console | Output;
  
  final static int Always = -1;
  final static int Minimum = 0;
  
  final static char Escape = char(0x1B);
  
  final static String F_Black    = Escape + "[30m";
  final static String F_Red      = Escape + "[31m";
  final static String F_Green    = Escape + "[32m";
  final static String F_Yellow   = Escape + "[33m";
  final static String F_Blue     = Escape + "[34m";
  final static String F_Magenta  = Escape + "[35m";
  final static String F_Cyan     = Escape + "[36m";
  final static String F_White    = Escape + "[37m";
  final static String F_Gray     = Escape + "[1;30m";
  final static String FB_Red     = Escape + "[1;31m";
  final static String FB_Green   = Escape + "[1;32m";
  final static String FB_Yellow  = Escape + "[1;33m";
  final static String FB_Blue    = Escape + "[1;34m";
  final static String FB_Magenta = Escape + "[1;35m";
  final static String FB_Cyan    = Escape + "[1;36m";
  final static String FB_White   = Escape + "[1;37m";
  final static String F_Reset    = Escape + "[39m";
  
  final static String B_Black    = Escape + "[40m";
  final static String B_Red      = Escape + "[41m";
  final static String B_Green    = Escape + "[42m";
  final static String B_Yellow   = Escape + "[43m";
  final static String B_Blue     = Escape + "[44m";
  final static String B_Magenta  = Escape + "[45m";
  final static String B_Cyan     = Escape + "[46m";
  final static String B_White    = Escape + "[47m";
  final static String B_Gray     = Escape + "[1;40m";
  final static String BB_Red     = Escape + "[1;41m";
  final static String BB_Green   = Escape + "[1;42m";
  final static String BB_Yellow  = Escape + "[1;43m";
  final static String BB_Blue    = Escape + "[1;44m";
  final static String BB_Magenta = Escape + "[1;45m";
  final static String BB_Cyan    = Escape + "[1;46m";
  final static String BB_White   = Escape + "[1;47m";
  final static String B_Reset    = Escape + "[49m";
  
  final static LogType notAllowed = null;
  final static LogType noExtra = new LogType("", "");
  
  final static LogType[] Warning = new LogType[]{new LogType(F_Yellow, F_Reset), new LogType("; \\!{", "}")}; // (yellow text, reset), (commented error)
  final static LogType[] Error = new LogType[]{new LogType(F_Red, F_Reset), new LogType("\\!{", "}")}; // (red text, reset), (error)
  
  final static LogType[] Function = new LogType[]{noExtra, notAllowed}; // (red text, reset), (not allowed)
}
  
void log(int level, Log.LogType[] type, int outputMask, String msg){
  if(level != Log.Always && level <= minLogLevel){ return; } // return if level is below min, but only if not -1...
  
   // log can be output to multiple locations...
  if((outputMask & Log.Console) != 0 && type[Log.ConsoleIDX] != null){ println(type[Log.ConsoleIDX].prefix + msg + type[Log.ConsoleIDX].suffix); }
  if((outputMask & Log.Output) != 0 && type[Log.OutputIDX] != null){ appendOutput(type[Log.OutputIDX].prefix + msg + type[Log.OutputIDX].suffix); }
}
  
void logVerbose(int level, Log.LogType[] type, int outputMask, String msg){
  if(level != Log.Always && level <= hyperVerboseOutput){ return; } // return if level is below min, but only if not -1...
  
   // log can be output to multiple locations...
  if((outputMask & Log.Console) != 0 && type[Log.ConsoleIDX] != null){ println(type[Log.ConsoleIDX].prefix + msg + type[Log.ConsoleIDX].suffix); }
  if((outputMask & Log.Output) != 0 && type[Log.OutputIDX] != null){ appendOutput(type[Log.OutputIDX].prefix + msg + type[Log.OutputIDX].suffix); }
}
