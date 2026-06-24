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
  
  // ANSI terminal colors as grabbed from the "ANSI escape codes" Wikipedia page (Windows Console)
  final static String F_Black    = Escape + "[38;2;000;000;000m"; // Set Foreground (38) color to RGB (2), (R), (G), (B)
  final static String F_Red      = Escape + "[38;2;128;000;000m";
  final static String F_Green    = Escape + "[38;2;000;128;000m";
  final static String F_Yellow   = Escape + "[38;2;128;128;000m";
  final static String F_Blue     = Escape + "[38;2;000;000;128m";
  final static String F_Magenta  = Escape + "[38;2;128;000;128m";
  final static String F_Cyan     = Escape + "[38;2;000;128;128m";
  final static String F_White    = Escape + "[38;2;192;192;192m";
  final static String F_Gray     = Escape + "[38;2;128;128;128m";
  final static String FB_Red     = Escape + "[38;2;255;000;000m";
  final static String FB_Green   = Escape + "[38;2;000;255;000m";
  final static String FB_Yellow  = Escape + "[38;2;255;255;000m";
  final static String FB_Blue    = Escape + "[38;2;000;000;255m";
  final static String FB_Magenta = Escape + "[38;2;255;000;255m";
  final static String FB_Cyan    = Escape + "[38;2;000;255;255m";
  final static String FB_White   = Escape + "[38;2;255;255;255m";
  final static String[] Foreground = {
    F_Black, F_Red, F_Green, F_Yellow, F_Blue, F_Magenta, F_Cyan, F_White,
    F_Gray, FB_Red, FB_Green, FB_Yellow, FB_Blue, FB_Magenta, FB_Cyan, FB_White
  };
  
  final static String B_Black    = Escape + "[48;2;000;000;000m"; // Set Background (48) color to RGB (2), (R), (G), (B)
  final static String B_Red      = Escape + "[48;2;128;000;000m";
  final static String B_Green    = Escape + "[48;2;000;128;000m";
  final static String B_Yellow   = Escape + "[48;2;128;128;000m";
  final static String B_Blue     = Escape + "[48;2;000;000;128m";
  final static String B_Magenta  = Escape + "[48;2;128;000;128m";
  final static String B_Cyan     = Escape + "[48;2;000;128;128m";
  final static String B_White    = Escape + "[48;2;192;192;192m";
  final static String B_Gray     = Escape + "[48;2;128;128;128m";
  final static String BB_Red     = Escape + "[48;2;255;000;000m";
  final static String BB_Green   = Escape + "[48;2;000;255;000m";
  final static String BB_Yellow  = Escape + "[48;2;255;255;000m";
  final static String BB_Blue    = Escape + "[48;2;000;000;255m";
  final static String BB_Magenta = Escape + "[48;2;255;000;255m";
  final static String BB_Cyan    = Escape + "[48;2;000;255;255m";
  final static String BB_White   = Escape + "[48;2;255;255;255m";
  final static String[] Background = {
    B_Black, B_Red, B_Green, B_Yellow, B_Blue, B_Magenta, B_Cyan, B_White,
    B_Gray, BB_Red, BB_Green, BB_Yellow, BB_Blue, BB_Magenta, BB_Cyan, BB_White
  };
  
  final static String CTRL_Reset        = Escape + "[0m";  // All Atrributes are cleared, as well as Fore/Background colors
  final static String CTRL_Italic       = Escape + "[3m";  // Text is made Italic
  final static String CTRL_Underline    = Escape + "[4m";  // Text is Underlined
  final static String CTRL_Reverse      = Escape + "[7m";  // Fore/Background colors are swapped
  final static String CTRL_Strike       = Escape + "[9m";  // Text is Striked-through
  final static String CTRL_NotItalic    = Escape + "[23m"; // Stop Italicizing text
  final static String CTRL_NotUnderline = Escape + "[24m"; // Stop Underlining test
  final static String CTRL_NoyReverse   = Escape + "[27m"; // Un-Reverse Fore/Background colors
  final static String CTRL_NotStrike    = Escape + "[29m"; // Stop Striking-through text
  final static String CTRL_ResetFG      = Escape + "[39m"; // Reset Foreground colors to default
  final static String CTRL_ResetBG      = Escape + "[49m"; // Reset Background colors to default
  final static String CTRL_Overlined    = Escape + "[53m"; // Overline text
  final static String CTRL_NotOverlined = Escape + "[55m"; // Stop Overlining text
  
  final static LogType notAllowed = null;
  final static LogType noExtra = new LogType("", "");
  
  final static LogType[] Normal = new LogType[]{new LogType(F_Green, CTRL_ResetFG), new LogType("; \\!{", "}")}; // (green text, reset), (commented error)
  final static LogType[] Warning = new LogType[]{new LogType(F_Yellow, CTRL_ResetFG), new LogType("; \\!{", "}")}; // (yellow text, reset), (commented error)
  final static LogType[] Error = new LogType[]{new LogType(F_Red, CTRL_ResetFG), new LogType("\\!{", "}")}; // (red text, reset), (error)
  
  final static LogType[] Function = new LogType[]{noExtra, notAllowed}; // (nothing, nothing), (not allowed)
}

void log(Log.LogType[] type, String msg){
  log(Log.Always, type, Log.Console, msg);
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
