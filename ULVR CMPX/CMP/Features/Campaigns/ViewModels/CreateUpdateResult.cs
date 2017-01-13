using System;

namespace CMP.Features.Campaigns.ViewModels
{
    public class CreateUpdateResult
    {
        public string Name { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public DateTime PriceDate { get; set; }
        public decimal Subsidy { get; set; }
        public Guid? CustomerId { get; set; }
        public int Status { get; set; }
    }
}