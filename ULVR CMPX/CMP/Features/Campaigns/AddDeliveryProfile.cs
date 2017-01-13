using System;
using System.Collections.Generic;
using System.Linq;
using Api.Domain;
using AutoMapper;
using FluentValidation;
using Infrastructure;
using MediatR;

namespace CMP.Features.Campaigns
{
    public class AddDeliveryProfile
    {

        public class Command : IRequest<Result>
        {
            public Guid CampaignId { get; set; }

            public List<CampaignDeliveryInput> CampaignDeliveries { get; set; }

            public class CampaignDeliveryInput
            {
                public int DeliveryDateOffSet { get; set; }
                public decimal Percent { get; set; }
            }
        }

        public class QueryValidator : AbstractValidator<Command>
        {
            public QueryValidator()
            {
                RuleFor(x => x.CampaignId).NotEmpty();
                RuleFor(x => x.CampaignDeliveries).SetCollectionValidator(new CampaignDeliveryProfileValidator());
                RuleFor(x => x.CampaignDeliveries.Sum(p => p.Percent)).InclusiveBetween(100, 100)
                    .WithName("CampaignDeliveryProfiles.Percent")
                    .WithMessage("Summen af leveringsprofilers procent skal give præcist 100%");
            }

            public class CampaignDeliveryProfileValidator : AbstractValidator<Command.CampaignDeliveryInput>
            {
                public CampaignDeliveryProfileValidator()
                {
                    RuleFor(x => x.DeliveryDateOffSet).InclusiveBetween(-10, 10);
                    RuleFor(x => x.Percent).InclusiveBetween(0, 100);
                }
            }
        }

        public class Result
        {
            public bool Success { get; set; }
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
                var campaign = _context.Campaigns.Single(c => c.Id == command.CampaignId);

                foreach (var item in command.CampaignDeliveries)
                {
                    var delivery = new CampaignDelivery(campaign, item.DeliveryDateOffSet, item.Percent);
                    campaign.AddDelivery(delivery);
                }

                _context.SaveChanges();

                var result = new Result { Success = true };
                return result;
            }
        }
    }
}