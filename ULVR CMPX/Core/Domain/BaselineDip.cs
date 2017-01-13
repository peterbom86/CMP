using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using Api.Domain.Base;

namespace Api.Domain
{
    /// <summary>When a product has been part of a campaign, the sales of this and others in the group will take a dip in sales the following weeks</summary>
    public class BaselineDip : Entity
    {
        /// <summary>The customer node these dip values cover</summary>
        public CustomerHierarchy Customer { get; set; }

        /// <summary>Id of the customer hierarchy node</summary>
        public Guid CustomerId { get; set; }

        /// <summary>The product group covered by the dip values</summary>
        public ProductGroup ProductGroup { get; set; }

        /// <summary>Id of the product group</summary>
        public Guid ProductGroupId { get; set; }

        private ICollection<Dip> _dips { get; set; } = new List<Dip>();

        /// <summary>The dip values for the next x weeks (typically 5 weeks)</summary>
        public ReadOnlyCollection<Dip> Dips
        {
            get
            {
                return _dips.ToList().AsReadOnly();
            }
        }

        public void AddDip(Dip dip)
        {
            _dips.Add(dip);
        }
    }
}