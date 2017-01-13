using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using Api.Domain;
using AutoMapper;
using FluentValidation;
using Infrastructure;
using MediatR;
using Newtonsoft.Json;

namespace CMP.Features.Customers
{
    public class CustomerDetails
    {
        public class Query : IRequest<Result>
        {
        }

        public class QueryValidator : AbstractValidator<Query>
        {
            public QueryValidator()
            {
            }
        }

        public class Result
        {
            public List<CustomerHierarchyVM> Items { get; set; }

            public class CustomerHierarchyVM
            {
                public string Name { get; set; }
                public Guid? ParentId { get; set; }
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
                var customers = _context.CustomerHierarchies.ProjectToList<Result.CustomerHierarchyVM>(_config);
                return new Result
                {
                    Items = BuildTree(customers),
                    Meta = new Result.MetaContainer { TotalItemCount = customers.Count() }
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
            private  List<Result.CustomerHierarchyVM> BuildTree(IEnumerable<Result.CustomerHierarchyVM> source)
            {
                var groups = source.GroupBy(i => i.ParentId);

                var roots = groups.FirstOrDefault(g => g.Key.HasValue == false).ToList();

                if (roots.Count > 0)
                {
                    var dict = groups.Where(g => g.Key.HasValue).ToDictionary(g => g.Key.Value, g => g.ToList());
                    for (int i = 0; i < roots.Count; i++)
                        AddChildren(roots[i], dict);
                }

                return roots;
            }

            private void AddChildren(Result.CustomerHierarchyVM node, IDictionary<Guid, List<Result.CustomerHierarchyVM>> source)
            {
                if (source.ContainsKey(node.Id))
                {
                    node.Children = source[node.Id];
                    for (int i = 0; i < node.Children.Count; i++)
                        AddChildren(node.Children[i], source);
                }
                else
                {
                    node.Children = new List<Result.CustomerHierarchyVM>();
                }
            }
        }
    }
}
public class GroupEnumerable
{
   
}