using System;
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
    public class Create
    {
        public class Command : CreateUpdateCommand<Result>
        {
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
                var campaign = new Campaign
                {
                    Name = command.Name,
                    StartDate = command.StartDate,
                    EndDate = command.EndDate,
                    PriceDate = command.PriceDate,
                    Subsidy = command.Subsidy,
                    CustomerId = command.CustomerId,
                    Status = Enumeration.FromValue<CampaignStatus>(command.Status)
                };

                _context.Campaigns.Add(campaign);
                _context.SaveChanges();

                var mapper = _config.CreateMapper();
                var result = mapper.Map<Campaign, Result>(campaign);

                return result;
            }
        }
    }
}