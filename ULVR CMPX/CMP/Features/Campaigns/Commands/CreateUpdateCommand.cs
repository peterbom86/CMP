using System;
using MediatR;

namespace CMP.Features.Campaigns.Commands
{
    public class CreateUpdateCommand<T> : IRequest<T>
    {
        public string Name { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public DateTime PriceDate { get; set; }
        public decimal Subsidy { get; set; }
        public Guid CustomerId { get; set; }
        public int Status { get; set; }
    }
}