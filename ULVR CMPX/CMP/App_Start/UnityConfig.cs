using System;
using System.Linq;
using System.Reflection;
using System.Web.Http;
using System.Web.Http.Controllers;
using AutoMapper;
using CMP.MappingBase;
using FluentValidation;
using MediatR;
using Microsoft.Practices.Unity;
using Unity.WebApi;

namespace CMP
{
    public static class UnityConfig
    {
        public static void RegisterComponents(UnityContainer container)
        {
            // Mediatr - register mediatr
            container.RegisterType<IMediator, Mediator>();

            // Find all types and register them - except validatorTypes, they must be registered later
            var types = AllClasses.FromAssemblies(true, Assembly.GetExecutingAssembly());
            var filteredTypes = types
                .Where(t => typeof(IValidator).IsAssignableFrom(t) == false)
                .Where(t => typeof(IHttpController).IsAssignableFrom(t) == false)
                .Where(t => typeof(BaseProfile).IsAssignableFrom(t) == false);

            container.RegisterTypes(
                filteredTypes,
                WithMappings.FromAllInterfaces,
                GetName,
                GetLifetimeManager);

            container.RegisterInstance<SingleInstanceFactory>(t => container.Resolve(t));
            container.RegisterInstance<MultiInstanceFactory>(t => container.ResolveAll(t));

            // Register validators
            RegisterValidators(container);

            // Automapper profiles
            var profileTypes = typeof(BaseProfile).Assembly.GetTypes().Where(type => type.IsSubclassOf(typeof(BaseProfile)));
            var config = new MapperConfiguration(cfg => new MapperConfiguration(x =>
            {
                foreach (var type in profileTypes)
                {
                    var profile = (BaseProfile)Activator.CreateInstance(type);
                    cfg.AddProfile(profile);
                }
            }));

            container.RegisterInstance<IConfigurationProvider>(config);

            GlobalConfiguration.Configuration.DependencyResolver = new UnityDependencyResolver(container);
        }

        private static bool IsNotificationHandler(Type type)
        {
            return type.GetInterfaces().Any(x => x.IsGenericType && (x.GetGenericTypeDefinition() == typeof(INotificationHandler<>) || x.GetGenericTypeDefinition() == typeof(IAsyncNotificationHandler<>)));
        }

        private static LifetimeManager GetLifetimeManager(Type type)
        {
            return IsNotificationHandler(type) ? new ContainerControlledLifetimeManager() : null;
        }

        private static string GetName(Type type)
        {
            return IsNotificationHandler(type) ? string.Format("HandlerFor" + type.Name) : string.Empty;
        }

        private static void RegisterValidators(IUnityContainer container)
        {
            var validators = AssemblyScanner.FindValidatorsInAssembly(Assembly.GetExecutingAssembly());
            validators.ForEach(validator => container.RegisterType(validator.InterfaceType, validator.ValidatorType));
        }
    }
}