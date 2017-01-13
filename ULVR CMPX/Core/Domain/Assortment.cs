using System;
using Api.Domain.Base;
using Api.Domain.Enums;

namespace Api.Domain
{
    public class Assortment : Entity
    {
        /// <summary>The product sold</summary>
        public Product Product { get; set; }

        public Guid ProductId { get; set; }

        /// <summary>The customer node that can purchase the product</summary>
        public CustomerHierarchy Customer { get; set; }

        /// <summary>The id of the customer node</summary>
        public Guid CustomerId { get; set; }

        /// <summary>The date the product is available for purchase</summary>
        public DateTime FromDate { get; set; }

        /// <summary>The date after which the product is no longer available for purchase</summary>
        public DateTime ToDate { get; set; }

        /// <summary>A status state for the assortment indicating availability for campaign, sales, production, ...</summary>
        public AssortmentStatus Status { get; set; }

        private Assortment()
        {
        }

        public Assortment(Guid productId, Guid customerId, DateTime fromDate, DateTime toDate, AssortmentStatus status)
        {
            ProductId = productId;
            CustomerId = customerId;
            FromDate = fromDate;
            ToDate = toDate;
            Status = status;
        }
    }
}