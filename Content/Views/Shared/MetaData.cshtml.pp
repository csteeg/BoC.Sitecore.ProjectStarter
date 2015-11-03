@inherits Glass.Mapper.Sc.Web.Mvc.GlassView<$rootnamespace$.Models.ISitecorePage>
@{
    var stylesheet = string.Format("/areas/{0}/css/{0}.css", Sitecore.Context.Site.Name);
#if DEBUG
		stylesheet += "&ts=" + DateTime.Now.Ticks;
#endif
}

<head>
    @if (Model != null)
    {
        <title>@Model.MetaTitle</title>
        <meta name="Description" content="@Model.MetaDescription" />
        <meta name="Keywords" content="@Model.MetaKeywords" />
        <meta name="robots" content="@(Model.NoIndex ? "noindex" : "index"), @(Model.NoFollow ? "nofollow" : "follow") @(Model.NoOdp ? "" : ",odp")" />
        <meta property="og:title" content="@Model.MetaTitle" />
        <meta property="og:description" content="@Model.MetaDescription">
    }
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
    <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="apple-mobile-web-app-capable" content="yes" />
    <meta name="apple-touch-fullscreen" content="yes" />
    <meta name="apple-mobile-web-app-status-bar-style" content="black" />
	<meta name="application-name" content="@(Sitecore.Context.Site.Name)">
    <link rel="stylesheet" href="~/css/core.css" />
		
		<!-- Favicons -->
    <link rel="apple-touch-icon" href="/areas/@(Sitecore.Context.Site.Name)/img/apple-icon.png" />
    <link rel="apple-touch-icon" sizes="72x72" href="/areas/@(Sitecore.Context.Site.Name)/img/apple-icon-72x72.png" />
    <link rel="apple-touch-icon" sizes="114x114" href="/areas/@(Sitecore.Context.Site.Name)/img/apple-icon-114x114.png" />
	<link rel="icon" href="/areas/@(Sitecore.Context.Site.Name)/img/favicon.png">
	<link rel="shortcut icon" href="/areas/@(Sitecore.Context.Site.Name)/img/favicon.ico">
	<meta name="msapplication-TileColor" content="#008200">
	<meta name="msapplication-TileImage" content="/areas/@(Sitecore.Context.Site.Name)/img/ms-icon-144x144.png">

    @Html.Partial("VisitorIdentification")
</head>