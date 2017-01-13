using System;
using System.Collections.Generic;
using Api.Domain.Base;

namespace Api.Domain
{
    public class CustomerHierarchy : Entity
    {
        /// <summary>Indicates the depth in the hierarchy for the current object</summary>
        public int HierarchyLevel { get; set; }

        /// <summary>The parent object</summary>
        public CustomerHierarchy Parent { get; set; }

        /// <summary>The ID of the parent</summary>
        public Guid? ParentId { get; set; }

        /// <summary>Child objects of current object</summary>
        public virtual ICollection<CustomerHierarchy> Children { get; set; } = new List<CustomerHierarchy>();

        /// <summary>The name of the customer</summary>
        public string Name { get; set; }

        /// <summary>Identifier used for the customer in external system</summary>
        public string Node { get; set; }
    }
}