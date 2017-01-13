using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using AutoMapper;
using Infrastructure;
using MediatR;
using CMP.Features.Campaigns.ViewModels;

namespace CMP.Features
{
    public class CampaignSearch
    {
        public class Query : IAsyncRequest<Result>
        {
            public string SearchText { get; set; }
            public int Max { get; set; }
        }

        public class Result
        {
            public List<CreateUpdateResult> Items { get; set; }

            public MetaContainer Meta { get; set; }

            public class MetaContainer
            {
                public int TotalItemCount { get; set; }
            }
        }

        public class Handler : IAsyncRequestHandler<Query, Result>
        {
            private readonly CmpContext _context;
            private IConfigurationProvider _config;

            public Handler(CmpContext context, IConfigurationProvider config)
            {
                _context = context;
                _config = config;
            }

            public async Task<Result> Handle(Query query)
            {
                var campaigns = _context.Campaigns
                    .Where(x => x.Name.Contains(query.SearchText));

                var results = await campaigns
                    .Take(query.Max)
                    .ProjectToListAsync<CreateUpdateResult>(_config);

                var totalItemCount = campaigns.Count();

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