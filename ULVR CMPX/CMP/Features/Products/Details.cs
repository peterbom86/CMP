using System;
using System.Linq;
using AutoMapper;
using CMP.Features.Shared.ViewModels;
using FluentValidation;
using Infrastructure;
using MediatR;

namespace CMP.Features.Products
{
    public class ProductDetails
    {
        public class Query : IRequest<Result>
        {
            public Guid id { get; set; }
        }

        public class QueryValidator : AbstractValidator<Query>
        {
            public QueryValidator()
            {
                RuleFor(q => q.id).NotEmpty();
            }
        }

        public class Result : ProductVM
        {
            public Guid Id { get; set; }
        }

        public class Handler : IRequestHandler<Query, Result>
        {
            private readonly CmpContext _context;
            private IConfigurationProvider _config;

            public Handler(CmpContext context, IConfigurationProvider config)
            {
                _context = context;
                _config = config;
            }

            public Result Handle(Query query)
            {
                var result = _context.Products.Where(p => p.Id == query.id)
                    .ProjectToFirstOrDefault<Result>(_config);

                return result;
            }
        }
    }
}