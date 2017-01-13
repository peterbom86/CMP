using System.Collections.Generic;
using Api.Domain.Base;

namespace Api.Domain
{
    public class ProductCategory : Entity
    {
        /// <summary>Name of product category</summary>
        public string Name { get; set; }

        /// <summary>The products assigned to this group</summary>
        public ICollection<ProductGroup> ProductGroups { get; set; } = new List<ProductGroup>();
    }
}