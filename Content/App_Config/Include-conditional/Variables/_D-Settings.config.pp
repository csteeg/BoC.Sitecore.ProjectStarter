<?xml version="1.0"?>
<configuration xmlns:patch="http://www.sitecore.net/xmlconfig/" condition-machineName="DEVELOPMACHINE" xmlns:set="http://www.sitecore.net/xmlconfig/set/">
  <sitecore>
    <sc.variable name="otap-EnableDebug" set:value="true" />
    <sc.variable name="otap-livemode-database" set:value="master" />
    <sc.variable name="otap-codefirst" set:value="true" />
    
    <!--Hybris Settings-->
    <settings>
      <setting name="SomeSetting" set:value="false" />
      <setting name="BoC.Profiler.Enabled" set:value="true" />
      <setting name="AutoInstallPackages.Folder" set:value="~/../../SitecorePackages" />
    </settings>

    <pipelines>
      <httpRequestBegin>
        <processor type="$rootnamespace$.AutoInstallPackages, $AssemblyName$" patch:after="processor[@type='Sitecore.Pipelines.HttpRequest.DatabaseResolver, Sitecore.Kernel']" />
      </httpRequestBegin>
    </pipelines>
    <settings>
      <setting name="Sitecore.Foundation.Installer.RestoreMongo" value="true"/>
    </settings>
  </sitecore>
</configuration>
