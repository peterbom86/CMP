using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using Api.Domain.Base;

namespace Api.Domain
{
    public class ProductGroup : Entity
    {
        /// <summary>Name of product group</summary>
        public string Name { get; set; }

        /// <summary>The product category this product group belongs to</summary>
        public ProductCategory ProductCategory { get; set; }

        /// <summary>The products assigned to this group</summary>
        public ICollection<Product> Products { get; set; } = new List<Product>();

        private ICollection<BaselineDip> _baselineDips { get; set; } = new List<BaselineDip>();

        /// <summary>Dib information for product group</summary>
        public ReadOnlyCollection<BaselineDip> BaselineDips
        {
            get
            {
                return _baselineDips.ToList().AsReadOnly();
            }
        }

        public void AddBaseLineDip(BaselineDip baselineDip)
        {
            _baselineDips.Add(baselineDip);
        }
    }
}