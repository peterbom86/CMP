using System;
using System.Collections.Generic;
using Api.Domain;
using Api.Domain.Enums;
using AutoMapper;
using FluentValidation;
using Infrastructure;
using MediatR;

namespace CMP.Features.Assortments
{
    public class Create
    {
        public class Command : IRequest<Result>
        {
            public List<Guid> ProductIds { get; set; }
            public Guid CustomerId { get; set; }
            public DateTime FromDate { get; set; }
            public DateTime ToDate { get; set; }
            public AssortmentStatus Status { get; set; }
        }

        public class QueryValidator : AbstractValidator<Command>
        {
            public QueryValidator()
            {
                RuleFor(x => x.ProductIds).NotEmpty();
                RuleFor(x => x.CustomerId).NotEmpty();
                RuleFor(x => x.FromDate).NotEmpty();
                RuleFor(x => x.ToDate).NotEmpty();
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
                foreach (var productId in command.ProductIds)
                {
                    var assortment = new Assortment(productId, command.CustomerId, command.FromDate, command.ToDate, command.Status);
                    _context.Assortments.Add(assortment);
                }

                _context.SaveChanges();

                return new Result { Success = true };
            }
        }
    }
}