using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using Api.Domain;
using Api.Domain.Enums;
using AutoMapper;
using CMP.Features.Campaigns.Commands;
using CMP.Features.Campaigns.ViewModels;
using FluentValidation;
using Infrastructure;
using MediatR;

namespace CMP.Features.Campaigns
{
    public class Update
    {
        public class Command : CreateUpdateCommand<Result>
        {
            public Guid Id { get; set; }
        }

        public class CommandValidator : AbstractValidator<Command>
        {
            public CommandValidator()
            {
                RuleFor(c => c.Name).NotEmpty();
                RuleFor(c => c.Name).Length(5, 250);
                RuleFor(c => c.StartDate).GreaterThan(DateTime.Today);
                RuleFor(c => c.EndDate).GreaterThan(DateTime.Today);
                RuleFor(c => c.EndDate).GreaterThan(x => x.StartDate);
                RuleFor(c => c.PriceDate).GreaterThan(DateTime.Today);
                RuleFor(c => c.CustomerId).NotEmpty();
                RuleFor(c => c.Status).NotEmpty();
                RuleFor(c => c.Subsidy).NotEmpty();
            }
        }

        public class Result : CreateUpdateResult
        {
            public string CustomerName { get; set; }
            public List<CampaignProductRelationVM> CampaignProductRelations { get; set; }

            public class CampaignProductRelationVM
            {
                public string ProductName { get; set; }
            }
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
                var campaign = _context.Campaigns
                    .Include(c => c.CampaignProductRelations.Select(r => r.Product))
                    .Include(c => c.Customer)
                    .Single(c => c.Id == command.Id);

                campaign.Name = command.Name;
                campaign.StartDate = command.StartDate;
                campaign.EndDate = command.EndDate;
                campaign.PriceDate = command.PriceDate;
                campaign.CustomerId = command.CustomerId;
                campaign.Subsidy = command.Subsidy;
                campaign.Status = Enumeration.FromValue<CampaignStatus>(command.Status);

                _context.SaveChanges();

                var mapper = _config.CreateMapper();
                var result = mapper.Map<Campaign, Result>(campaign);

                return result;
            }
        }
    }
}