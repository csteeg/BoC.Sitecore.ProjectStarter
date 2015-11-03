@using $rootnamespace$.Models

@using System.Web.Mvc.Html
@using System.Web.Optimization
@using Glass.Mapper.Sc
@using Glass.Mapper.Sc.Web.Mvc
@using Sitecore.Configuration
@using Sitecore.Diagnostics
@using Sitecore.Mvc
@{
    
    var editingClass = "sc-livemode";
    if (GlassHtml.IsInEditingMode)
    {
        editingClass = "sc-editingmode";
    }
    if (Profiler.IsActive)
    {
        editingClass += " sc-profiling";
    }
    if (Tracer.IsActive)
    {
        editingClass += " sc-tracing";
    }
}

<!DOCTYPE html>
<!--[if IE 9]><html lang="@Sitecore.Context.Site.Language" class="no-js ie9"><![endif]-->
<!--[if (gt IE 9)|!(IE)]><!-->
<html lang="@Sitecore.Context.Site.Language" class=" no-js">
<!--<![endif]-->
@{ Html.RenderPartial("MetaData", Html.Glass().SitecoreContext.GetCurrentItem<ISitecorePage>()); }
<body ontouchstart="" class="@editingClass">
    <div class="viewport">
        @Html.Sitecore().Placeholder("header")
        <div class="content">
            <div class="container">
                @Html.Sitecore().Placeholder("content")
            </div>
        </div>

        <footer class="footer">
            <div class="container">
                @Html.Sitecore().Placeholder("footer")
            </div>
        </footer>

    </div>
@Scripts.Render("~/bundles/" + Sitecore.Context.Site.Name + ".js")
</body>

</html>