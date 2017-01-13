using System;
using FluentValidation;
using Microsoft.Practices.Unity;

namespace CMP
{
    public class UnityValidatorFactory : ValidatorFactoryBase
    {
        private readonly IUnityContainer container;

        public UnityValidatorFactory(IUnityContainer container)
        {
            this.container = container;
        }

        public override IValidator CreateInstance(Type validatorType)
        {
            if (container.IsRegistered(validatorType))
            {
                var validator = container.Resolve(validatorType) as IValidator;
                return validator;
            }

            return null;
        }
    }
}