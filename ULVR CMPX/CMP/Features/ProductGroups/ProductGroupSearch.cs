using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using AutoMapper;
using Infrastructure;
using MediatR;

namespace CMP.Features.ProductGroups
{
    public class ProductGroupSearch
    {
        public class Query : IRequest<Result>
        {
            public string SearchText { get; set; }

            public int MaxItems { get; set; }
        }

        public class Result
        {
            public List<ProductGroupVM> Items { get; set; }

            public MetaContainer Meta { get; set; }

            public class ProductGroupVM
            {
                public string Name { get; set; }
                public Guid Id { get; set; }
                public string ProductCategoryName { get; set; }
            }

            public class MetaContainer
            {
                public int TotalItemCount { get; set; }
            }
        }

        public class Handler : IRequestHandler<Query, Result>
        {
            private readonly CmpContext _context;
            private readonly IConfigurationProvider _config;

            public Handler(CmpContext context, IConfigurationProvider config)
            {
                _context = context;
                _config = config;
            }

            public Result Handle(Query query)
            {
                var productGroups = _context.ProductGroups
                    .Where(p => p.Name.Contains(query.SearchText));

                var results = productGroups
                    .Take(query.MaxItems)
                    .ProjectToList<Result.ProductGroupVM>(_config);

                var totalItemCount = productGroups.Count();

                var result = new Result
                {
                    Items = results,
                    Meta = new Result.MetaContainer { TotalItemCount = totalItemCount }
                };

                return result;
            }
        }
    }
}