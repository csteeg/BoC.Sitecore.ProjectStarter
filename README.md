# BoC.Sitecore.ProjectStarter
Every now and then I have an idea for Sitecore that I want to try out quickly. Since (even with SIM), it’s quite some work to setup an empty Sitecore environment, I decided to make a nuget solution to quickly start a new Sitecore project. 
Using this package, you’ll be able to have a running sitecore environment in less then 10 minutes. It’s a solid base for any new Sitecore project, so not just for testing small stuff.

To get started, open up your Visual Studio environment _as an administrator_ and create a new _empty_ web application (the preferred visual studio is 2015, since it handles the script **much** faster, 2013 might take up the full promised 10 minutes :))  
[![image](http://csteeg.blob.core.windows.net/blog/wp-content/uploads/2015/09/image_thumb.png "image")](http://cdn.chrisvandesteeg.nl/blog/wp-content/uploads/2015/09/image.png)[![image](http://csteeg.blob.core.windows.net/blog/wp-content/uploads/2015/09/image_thumb1.png "image")](http://cdn.chrisvandesteeg.nl/blog/wp-content/uploads/2015/09/image1.png)

Now, open up your package manager console and type: Install-Package BoC.Sitecore.Projectstarter to download the basic nuget package.  
Once downloaded, the installer will ask you for a Sitecore .zip file (it sometimes happens that the popup appears behind visual studio, so check with ALT+TAB if your visual studio looks frozen).

![image](http://cdn.chrisvandesteeg.nl/blog/wp-content/uploads/2015/09/image2.png "image")

In this screen, select your sitecore website-root zip file that you’ve downloaded from [http://dev.sitecore.net/](http://dev.sitecore.net/). Pressing open will start the extracting of the Sitecore zip file. After the content has been extracted, another openfile dialog will appear, to pass in your license.xml file.

[![image](http://csteeg.blob.core.windows.net/blog/wp-content/uploads/2015/09/image_thumb2.png "image")](http://cdn.chrisvandesteeg.nl/blog/wp-content/uploads/2015/09/image3.png)

Once your license file is in place, the script will start installing some nuget packages to get your project started. The installation will **fail** with the message **“install-package : Project unavailable”!**. This is due to the script having moved the project file. As long is this is the only error message, everything went fine.

![image](http://cdn.chrisvandesteeg.nl/blog/wp-content/uploads/2015/09/image4.png "image")

Now, just hit CTRL+F5 (or Debug->Start without debugging) to open the default Sitecore page in your browser.

Things to know about your new project:

*   the debug.csproj file, on build, deploys all projects in your solution to $(solutiondir)\build
*   only on rebuild, all files in $(solutiondir)\build will be deleted first
*   the Sitecore zip file is extracted to $(solutiondir)\temp, if you remove this folder and do a rebuild, visual studio will ask for the Sitecore zip again (this way you can easily upgrade to a newer sitecore version)
*   by default the debug.csproj file is attached to IISExpress and should always be your default project. You can easily attach the project to normal IIS in it’s properties dialog
