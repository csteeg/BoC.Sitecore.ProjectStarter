using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Glass.Mapper.Sc.Configuration.Attributes;

namespace $rootnamespace$.Models
{
    /// <summary>
    /// Add this template to your pages
    /// </summary>
    [SitecoreType(true, "{26575e33-bfb3-41fe-98b1-d59d80a83274}")]
    public interface ISitecorePage
    {
        string MetaTitle { get; set; }
        string MetaDescription { get; set; }
        string MetaKeywords { get; set; }

        bool NoIndex { get; set; }
        bool NoFollow { get; set; }
        bool NoOdp { get; set; }
        bool NoInternalIndex { get; set; }
    }
}
