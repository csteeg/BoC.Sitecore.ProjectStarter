using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace SelectFile
{
    class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            if (args == null || !args.Any())
            {
                args = new[] {"*.*", "Select your file"};
            }
            string fileName;
            OpenFileDialog fd = new OpenFileDialog();
            fd.Filter = args[0];
            fd.Title = args[1];
            fd.ShowDialog();
            fileName = fd.FileName;
            Console.Write(fileName);
        }
    }
}
