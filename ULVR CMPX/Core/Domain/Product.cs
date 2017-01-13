using System.Collections.Generic;
using Api.Domain.Base;

namespace Api.Domain
{
    public class Product : Entity
    {
        /// <summary>The name of the product</summary>
        public string Name { get; set; }

        /// <summary>Product code of the product</summary>
        public string ProductCode { get; set; }

        /// <summary>The product group this product belongs to</summary>
        public ProductGroup ProductGroup { get; set; }

        /// <summary>Information about which campaigns have included this product</summary>
        public ICollection<CampaignProductRelation> CampaignProductRelations { get; set; } = new List<CampaignProductRelation>();

        /// <summary>Information about which assortments (product grouping) this product is part of</summary>
        public ICollection<Assortment> Assortments { get; set; } = new List<Assortment>();
    }
}