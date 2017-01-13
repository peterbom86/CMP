using System.Web.Http;
using System.Web.Mvc;
using System.Web.Optimization;
using System.Web.Routing;
using CMP;
using FluentValidation.WebApi;
using Microsoft.Practices.Unity;

namespace Api
{
    public class WebApiApplication : System.Web.HttpApplication
    {
        protected void Application_Start()
        {
            var container = new UnityContainer();
            UnityConfig.RegisterComponents(container);

            AreaRegistration.RegisterAllAreas();
            GlobalConfiguration.Configure(WebApiConfig.Register);
            FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
            FilterConfig.RegisterWebApiFilters(GlobalConfiguration.Configuration.Filters);
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            BundleConfig.RegisterBundles(BundleTable.Bundles);

            FluentValidationModelValidatorProvider.Configure(GlobalConfiguration.Configuration, x => x.ValidatorFactory = new UnityValidatorFactory(container));
        }
    }
}
