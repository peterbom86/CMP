using System;
using System.Data.Entity;
using System.Linq;
using AutoMapper;
using CMP.Features.Shared.ViewModels;
using FluentValidation;
using Infrastructure;
using MediatR;

namespace CMP.Features.Products
{
    public class ProductUpdate
    {
        public class Command : IRequest<Result>
        {
            public Guid Id { get; set; }
            public string Name { get; set; }
            public Guid ProductGroupId { get; set; }
        }

        public class CommandValidator : AbstractValidator<Command>
        {
            public CommandValidator()
            {
                RuleFor(p => p.Name).NotEmpty();
                RuleFor(p => p.Name).Length(5, 250);

                RuleFor(p => p.ProductGroupId).NotEmpty();
            }
        }

        public class Result : ProductVM
        {
        }

        public class Handler : IRequestHandler<Command, Result>
        {
            private readonly CmpContext _context;
            private readonly IConfigurationProvider _config;

            public Handler(CmpContext context, IConfigurationProvider config)
            {
                _context = context;
                _config = config;
            }

            public Result Handle(Command command)
            {
                var product = _context.Products.Single(p => p.Id == command.Id);
                var newProductGroup = _context.ProductGroups
                    .Include(pg => pg.ProductCategory)
                    .Single(pg => pg.Id == command.ProductGroupId);

                product.Name = command.Name;
                product.ProductGroup = newProductGroup;

                _context.SaveChanges();

                var mapper = _config.CreateMapper();
                var result = mapper.Map<Result>(product);

                return result;
            }
        }
    }
}