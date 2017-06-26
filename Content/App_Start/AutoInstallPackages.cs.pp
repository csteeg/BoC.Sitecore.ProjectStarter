using Sitecore.Pipelines;

namespace $rootnamespace$
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Web;
    using System.Web.Hosting;
    using Sitecore.Configuration;
    using Sitecore.Data.Engines;
    using Sitecore.Data.Proxies;
    using Sitecore.Install;
    using Sitecore.Install.Files;
    using Sitecore.Install.Framework;
    using Sitecore.Install.Items;
    using Sitecore.Install.Metadata;
    using Sitecore.Install.Utils;
    using Sitecore.Install.Zip;
    using Sitecore.Sites;

    public class AutoInstallPackages
    {
        public void Process(PipelineArgs args)
        {
            if (HttpContext.Current == null || HttpContext.Current.Response == null || 
				HttpContext.Current.Request.Url.ToString().ToLower().Contains("/sitecore")
				|| HttpContext.Current.Request.Url.ToString().ToLower().Contains("/~/")
				|| HttpContext.Current.Request.Url.ToString().ToLower().Contains("/-/"))
                return;

            var folder = Sitecore.Configuration.Settings.GetSetting("AutoInstallPackages.Folder", Path.Combine(Sitecore.Configuration.Settings.DataFolder, "packages-autoinstall"));
            var completedfolder = Sitecore.Configuration.Settings.GetSetting("AutoInstallPackages.CompletedFolder", Path.Combine(Sitecore.Configuration.Settings.DataFolder, "packages-autoinstall\\completed"));

            if (folder.StartsWith("~") || folder.StartsWith("/"))
            {
                folder = HostingEnvironment.MapPath("~/") + folder.Substring(1).Replace("/", Path.DirectorySeparatorChar.ToString());
            }
            if (completedfolder.StartsWith("~") || completedfolder.StartsWith("/"))
            {
                completedfolder = HostingEnvironment.MapPath("~/") + completedfolder.Substring(1).Replace("/", Path.DirectorySeparatorChar.ToString());
            }
            if (!System.IO.Directory.Exists(folder))
                return;
            if (!System.IO.Directory.Exists(completedfolder))
                Directory.CreateDirectory(completedfolder);

            var files = Directory.GetFiles(folder, "*.zip", SearchOption.AllDirectories).ToArray();
            if (files == null || files.Length == 0)
                return;
            var completedfiles = Directory.GetFiles(completedfolder);

            var proceedUrl = HttpContext.Current.Request.Url.ToString();
            proceedUrl += proceedUrl.Contains("?") ? "&" : "?";


            var installed = files.Where(f => completedfiles.Any(c => new FileInfo(f).Name == new FileInfo(c).Name)).ToArray();
            var needinstall = files.Where(f => !installed.Contains(f) && !f.Contains("deploy-")).ToArray();
            if (!needinstall.Any())
            {
                var unicorned = Path.Combine(completedfolder, ".sitecoreprojectstarter.unicorned");
                var redirectedToUnicorn = File.Exists(unicorned);
                if (!redirectedToUnicorn)
                {
                    File.WriteAllText(unicorned, "ok");
                    HttpContext.Current.Response.Redirect("~/unicorn.aspx?verb=sync");
                    HttpContext.Current.Response.End();
                }
                return;
            }

            HttpContext.Current.Response.ClearContent();
            HttpContext.Current.Response.Write(GetHtml(installed, needinstall, proceedUrl, !string.IsNullOrEmpty(HttpContext.Current.Request["projectstarter.proceed"])));
            HttpContext.Current.Response.Flush();

            if (string.IsNullOrEmpty(HttpContext.Current.Request["projectstarter.proceed"]))
            {
                args.AbortPipeline();
                HttpContext.Current.Response.Write("</body>");
                HttpContext.Current.Response.End();
                return;
            }

            using (new SiteContextSwitcher(Factory.GetSite("shell")))
                using (new ProxyDisabler())
                    using (ConfigWatcher.PostponeEvents())
                        using (new SyncOperationContext())
                        {
                            var f = needinstall.First();
                            Install(f);
                            File.WriteAllText(Path.Combine(completedfolder, new FileInfo(f).Name), "ok");
                            HttpContext.Current.Response.Write(string.Format("<script>window.location.reload()</script></body>"));
                            HttpContext.Current.Response.End();
                        }


        }

        private string GetHtml(IEnumerable<string> installed, IEnumerable<string> needinstall, string proceedUrl, bool isProceeding)
        {
            return "<!DOCTYPE html>\r\n<html lang=\"en\">\r\n<head>\r\n<meta http-equiv=\"content-type\" content=\"text/html; charset=UTF-8\"> \r\n        <meta charset=\"utf-8\">\r\n<title>Sitecore projectstarter</title>\r\n<link href=\"//maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css\" rel=\"stylesheet\">\r\n<link href=\"//maxcdn.bootstrapcdn.com/font-awesome/4.2.0/css/font-awesome.min.css\" type=\"text/css\" rel=\"stylesheet\" /></head>\r\n<body>\r\n<div class=\"container-fluid\">\r\n  <div class=\"row\">\r\n    <div class=\"col-sm-9\">\r\n          \r\n        <h1>Projectstarter</h1>\r\n        \r\n    \t<div class=\"alert alert-info\">\r\n          <h3>Updates required</h3>\r\n          The following modules need to be installed:\r\n<ul>\r\n"
                   + string.Join("", needinstall.Select(s =>
                       string.Format(isProceeding && s == needinstall.First() ? "<li><h4><i class=\"fa fa-spinner fa-spin fa-3x fa-fw\"></i>{0}</h4></li>" : "<li>{0}</li>", new FileInfo(s).Name)))
                   + string.Join("", installed.Select(s => string.Format("<li style=\"text-decoration: line-through;\">{0}</li>", new FileInfo(s).Name)))
                   + "</ul>\r\n          <br /><br />\r\n"
                   + (isProceeding ? "" : "<a href=\"" + proceedUrl + "projectstarter.proceed=true\" class=\"btn btn-primary btn-large\" data-toggle=\"popover\" title=\"\" data-placement=\"right\">Proceed</a>")
                   + "</div>\r\n    </div>\r\n  </div>\r\n  <br>\r\n  \r\n</div>";
        }

        protected static void Install(string package)
        {
            IProcessingContext context = new SimpleProcessingContext();
            IItemInstallerEvents instance = new DefaultItemInstallerEvents(new BehaviourOptions(InstallMode.Merge, MergeMode.Merge));
            context.AddAspect<IItemInstallerEvents>(instance);
            IFileInstallerEvents events = new DefaultFileInstallerEvents(true);
            context.AddAspect<IFileInstallerEvents>(events);

            var installer = new Installer();
            installer.InstallPackage(package, context);

            //run poststep:
            try
            {

                ISource<PackageEntry> source = new PackageReader(package);
                var previewContext = Installer.CreatePreviewContext();
                var view = new MetadataView(previewContext);
                var metadataSink = new MetadataSink(view);
                metadataSink.Initialize(previewContext);
                source.Populate(metadataSink);
                if (view.PostStep != null)
                    installer.ExecutePostStep(view.PostStep, previewContext);
            }
            catch (Exception exc)
            {
                HttpContext.Current.Response.Write("<div class=\"alert alert-warning\"><h3>Error in poststep!</h3><pre>");
                HttpContext.Current.Response.Write(exc.Message);
                HttpContext.Current.Response.Write("\r\n----------------------------------\r\n");
                HttpContext.Current.Response.Write(exc.Source);
                HttpContext.Current.Response.Write("\r\n----------------------------------\r\n");
                HttpContext.Current.Response.Write(exc.StackTrace);
                HttpContext.Current.Response.Write("</pre><br /><strong>Refresh the page to continue anyway</strong></div>");
                HttpContext.Current.Response.Write("</body>");
                HttpContext.Current.Response.End();
            }
        }

    }
}
