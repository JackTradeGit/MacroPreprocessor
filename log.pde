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
  final static int Output = 2;
  
  final static int Always = -1;
  final static int Minimum = 0;
  
  static char Escape = char(0x1B);
  
  static String F_Black    = Escape + "[30m";
  static String F_Red      = Escape + "[31m";
  static String F_Green    = Escape + "[32m";
  static String F_Yellow   = Escape + "[33m";
  static String F_Blue     = Escape + "[34m";
  static String F_Magenta  = Escape + "[35m";
  static String F_Cyan     = Escape + "[36m";
  static String F_White    = Escape + "[37m";
  static String F_Gray     = Escape + "[1;30m";
  static String FB_Red     = Escape + "[1;31m";
  static String FB_Green   = Escape + "[1;32m";
  static String FB_Yellow  = Escape + "[1;33m";
  static String FB_Blue    = Escape + "[1;34m";
  static String FB_Magenta = Escape + "[1;35m";
  static String FB_Cyan    = Escape + "[1;36m";
  static String FB_White   = Escape + "[1;37m";
  static String F_Reset   = Escape + "[39m";
  
  static String B_Black    = Escape + "[40m";
  static String B_Red      = Escape + "[41m";
  static String B_Green    = Escape + "[42m";
  static String B_Yellow   = Escape + "[43m";
  static String B_Blue     = Escape + "[44m";
  static String B_Magenta  = Escape + "[45m";
  static String B_Cyan     = Escape + "[46m";
  static String B_White    = Escape + "[47m";
  static String B_Gray     = Escape + "[1;40m";
  static String BB_Red     = Escape + "[1;41m";
  static String BB_Green   = Escape + "[1;42m";
  static String BB_Yellow  = Escape + "[1;43m";
  static String BB_Blue    = Escape + "[1;44m";
  static String BB_Magenta = Escape + "[1;45m";
  static String BB_Cyan    = Escape + "[1;46m";
  static String BB_White   = Escape + "[1;47m";
  static String B_Reset   = Escape + "[49m";
  
  static LogType Normal = new LogType("", ""); // no color change
  static LogType Warning = new LogType(F_Yellow, F_Reset); // red text, then reset
  static LogType Error = new LogType(F_Red, F_Reset); // red text, then reset
}
  
void log(int level, Log.LogType type, int outputMask, String msg){
  if(level != Log.Always && level < minLogLevel){ return; } // return if level is below min, but only if not -1...
  
  String str = type.prefix + msg + type.suffix;
  
  if((outputMask & Log.Console) != 0){ println(str); } // log can be output to multiple locations...
  if((outputMask & Log.Output) != 0){ appendOutput(str); }
}
