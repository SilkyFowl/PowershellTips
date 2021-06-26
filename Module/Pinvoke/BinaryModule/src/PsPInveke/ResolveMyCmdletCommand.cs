using System;
using System.Management.Automation;
using Microsoft.Windows.Sdk;
using static Microsoft.Windows.Sdk.PInvoke;

namespace PsPInveke
{
     class Test
    {
        static Type Native => Type.GetType("PInvoke");

        public static BOOL OutputWindow(HWND hwnd, LPARAM lParam)
        {
            Console.WriteLine(hwnd.Value);
            return true;
        }

        public static BOOL Do()
        {
            return EnumWindows(OutputWindow, (LPARAM)0);
        }


    }

    [Cmdlet(VerbsDiagnostic.Resolve, "MyCmdlet")]
    public class ResolveMyCmdletCommand : PSCmdlet
    {
        [Parameter(Position = 0)]
        public Object InputObject { get; set; }

        protected override void EndProcessing()
        {
            var t = typeof(Test);
            this.WriteObject(t);
            base.EndProcessing();
        }
    }
}
