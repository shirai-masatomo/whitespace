using System;
using System.Text;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;

// A private, noninteractive window station cannot become the user's input desktop.
// Window placement/unfocusable settings are not used as a security boundary.
public static class FarmIsolatedDesktop {
    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)] struct SI {
        public int cb; public string reserved, desktop, title;
        public uint x,y,xSize,ySize,xChars,yChars,fill,flags;
        public short show,reserved2; public IntPtr reservedPtr,input,output,error;
    }
    [StructLayout(LayoutKind.Sequential)] struct PI { public IntPtr process,thread; public uint pid,tid; }
    [DllImport("user32.dll", CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr CreateWindowStation(string n,uint f,uint a,IntPtr s);
    [DllImport("user32.dll",SetLastError=true)] static extern bool SetProcessWindowStation(IntPtr h);
    [DllImport("user32.dll")] static extern IntPtr GetProcessWindowStation();
    [DllImport("user32.dll", CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr CreateDesktop(string n,IntPtr d,IntPtr m,uint f,uint a,IntPtr s);
    [DllImport("user32.dll", CharSet=CharSet.Unicode,SetLastError=true)] static extern bool GetUserObjectInformation(IntPtr h,int index,IntPtr data,uint bytes,out uint needed);
    delegate bool EnumWindow(IntPtr window,IntPtr data);
    [DllImport("user32.dll",SetLastError=true)] static extern bool EnumDesktopWindows(IntPtr desktop,EnumWindow callback,IntPtr data);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr window,out uint process);
    [DllImport("user32.dll")] static extern bool CloseDesktop(IntPtr h);
    [DllImport("user32.dll")] static extern bool CloseWindowStation(IntPtr h);
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode,SetLastError=true)] static extern bool CreateProcess(string app,StringBuilder cmd,IntPtr pa,IntPtr ta,bool inherit,uint flags,IntPtr env,string cwd,ref SI si,out PI pi);
    [DllImport("kernel32.dll")] static extern uint WaitForSingleObject(IntPtr h,uint ms);
    [DllImport("kernel32.dll")] static extern bool GetExitCodeProcess(IntPtr h,out uint code);
    [DllImport("kernel32.dll")] static extern bool TerminateProcess(IntPtr h,uint code);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);
    [DllImport("kernel32.dll")] static extern void SetLastError(uint error);
    static void Need(bool ok,string step) { if(!ok) throw new Win32Exception(Marshal.GetLastWin32Error(),step+" (Win32 "+Marshal.GetLastWin32Error()+")"); }
    static string Name(IntPtr h) {
        if(h==IntPtr.Zero)return "";
        IntPtr p=Marshal.AllocHGlobal(1024);
        try { uint needed; Need(GetUserObjectInformation(h,2,p,1024,out needed),"Object name");return Marshal.PtrToStringUni(p); }
        finally {Marshal.FreeHGlobal(p);}
    }
    static bool Visible(IntPtr h) {
        IntPtr p=Marshal.AllocHGlobal(12);
        try { uint needed; Need(GetUserObjectInformation(h,1,p,12,out needed),"Station visibility");return (Marshal.ReadInt32(p,8)&1)!=0; }
        finally {Marshal.FreeHGlobal(p);}
    }
    public class Result { public uint PID,ThreadID,ExitCode; public int OwnedWindowCount; public string Station,Desktop,ObservedDesktop; public bool NonInteractive,DesktopMatched,TimedOut; }
    public static Result Run(string exe,string command,string cwd,SortedDictionary<string,string> environment,int timeout) {
        IntPtr original=GetProcessWindowStation(), station=IntPtr.Zero,desktop=IntPtr.Zero,env=IntPtr.Zero;
        PI pi=new PI(); Result result=new Result();
        result.Station="FarmReview_"+Guid.NewGuid().ToString("N"); result.Desktop="Render_"+Guid.NewGuid().ToString("N");
        try {
            // CWF_CREATE_ONLY: never attach to an existing station by accident.
            station=CreateWindowStation(result.Station,1,0x37f,IntPtr.Zero);
            // Non-admin Windows tokens may only request an unnamed, logon-scoped station.
            if(station==IntPtr.Zero && Marshal.GetLastWin32Error()==5)station=CreateWindowStation(null,0,0x37f,IntPtr.Zero);
            Need(station!=IntPtr.Zero,"Create noninteractive window station");
            result.Station=Name(station);
            Need(Name(station)!="WinSta0"&&!Visible(station),"Refuse interactive window station");
            result.NonInteractive=true;
            Need(SetProcessWindowStation(station),"Connect private station");
            // No DESKTOP_SWITCHDESKTOP, hooks or journal rights requested.
            desktop=CreateDesktop(result.Desktop,IntPtr.Zero,IntPtr.Zero,0,0xc7,IntPtr.Zero);Need(desktop!=IntPtr.Zero,"Create private desktop");
            Need(SetProcessWindowStation(original),"Restore launcher station");
            var block=new StringBuilder();foreach(var pair in environment)block.Append(pair.Key).Append('=').Append(pair.Value).Append('\0');block.Append('\0');
            env=Marshal.StringToHGlobalUni(block.ToString());
            SI si=new SI();si.cb=Marshal.SizeOf(typeof(SI));si.desktop=result.Station+"\\"+result.Desktop;si.flags=0x80;
            // No handles inherited. Desktop is specified before USER32 or the first window exists.
            Need(CreateProcess(exe,new StringBuilder(command),IntPtr.Zero,IntPtr.Zero,false,0x08000400,env,cwd,ref si,out pi),"Create isolated renderer");
            result.PID=pi.pid;result.ThreadID=pi.tid;
            var limit=DateTime.UtcNow.AddSeconds(timeout);
            while(WaitForSingleObject(pi.process,100)==258) {
                // Enumerate only the private desktop, not the user's windows. A renderer can create its GUI on a non-primary thread.
                int count=0;
                EnumWindow callback=(window,data)=>{uint owner;GetWindowThreadProcessId(window,out owner);if(owner==result.PID)count++;return true;};
                SetLastError(0);
                bool enumerated=EnumDesktopWindows(desktop,callback,IntPtr.Zero);
                int error=Marshal.GetLastWin32Error();
                // Empty desktops/renderer exit can return false without an error.
                if(!enumerated && error!=0 && WaitForSingleObject(pi.process,0)==258)
                    throw new Win32Exception(error,"Enumerate isolated desktop");
                result.OwnedWindowCount=Math.Max(result.OwnedWindowCount,count);
                if(count>0){result.DesktopMatched=true;result.ObservedDesktop=result.Desktop;}
                if(DateTime.UtcNow>limit){result.TimedOut=true;TerminateProcess(pi.process,124);WaitForSingleObject(pi.process,5000);break;}
            }
            GetExitCodeProcess(pi.process,out result.ExitCode);
            return result;
        } finally {
            SetProcessWindowStation(original);
            if(pi.process!=IntPtr.Zero){uint code;if(GetExitCodeProcess(pi.process,out code)&&code==259){TerminateProcess(pi.process,125);WaitForSingleObject(pi.process,5000);}CloseHandle(pi.process);}
            if(pi.thread!=IntPtr.Zero)CloseHandle(pi.thread);
            if(env!=IntPtr.Zero)Marshal.FreeHGlobal(env);
            if(desktop!=IntPtr.Zero)CloseDesktop(desktop);
            if(station!=IntPtr.Zero)CloseWindowStation(station);
        }
    }
}
