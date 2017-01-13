using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using Api.Domain;
using AutoMapper;
using FluentValidation;
using Infrastructure;
using MediatR;

namespace CMP.Features.Customers
{
    public class CustomerSearch
    {
        public class Query : IRequest<Result>
        {
            public string SearchText { get; set; }
        }

        public class QueryValidator : AbstractValidator<Query>
        {
            public QueryValidator()
            {
                RuleFor(x => x.SearchText).NotEmpty();
            }
        }

        public class Result
        {
            public List<CustomerHierarchyVM> Items { get; set; }

            public class CustomerHierarchyVM
            {
                public string Name { get; set; }
                public Guid Id { get; set; }
                public List<CustomerHierarchyVM> Children { get; set; } = new List<CustomerHierarchyVM>();
            }
            public MetaContainer Meta { get; set; }

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
                var potentialCustomers = _context.CustomerHierarchies
                    .Where(c => c.Name.Contains(query.SearchText));
                if (potentialCustomers.Count() > 0)
                {
                    var minHierarchy = potentialCustomers.Min(c => c.HierarchyLevel);

                    var customers = potentialCustomers
                        .Include(c => c.Children)
                        .Where(c => c.HierarchyLevel == minHierarchy);

                    var vm = customers.ProjectToList<Result.CustomerHierarchyVM>(_config);

                    foreach (var customer in customers.ToList())
                    {
                        foreach (var item in customer.Children)
                        {
                            LoadChildren(item, vm.Single(c => c.Id == customer.Id), _config);
                        }
                    }

                    return new Result
                    {
                        Items = vm,
                        Meta = new Result.MetaContainer { TotalItemCount = potentialCustomers.Count() }
                    };
                }
                else
                    return new Result
                    {
                        Items = new List<Result.CustomerHierarchyVM>(),
                        Meta = new Result.MetaContainer { TotalItemCount = 0 }
                    };
            }

            public Result.CustomerHierarchyVM LoadChildren(CustomerHierarchy customer, Result.CustomerHierarchyVM vm, IConfigurationProvider _config)
            {
                _context.Entry(customer).Collection(x => x.Children).Load();

                vm.Children.AddRange(customer.Children.AsQueryable().ProjectToList<Result.CustomerHierarchyVM>(_config));

                foreach (var item in customer.Children)
                {
                    LoadChildren(item, vm.Children.Single(c => c.Id == item.Id), _config);
                }

                return vm;
            }
        }
    }
}