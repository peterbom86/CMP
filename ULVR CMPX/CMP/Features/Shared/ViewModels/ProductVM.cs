using System;

namespace CMP.Features.Shared.ViewModels
{
    public class ProductVM
    {
        public string Name { get; set; }
        public string ProductCode { get; set; }
        public string ProductGroupName { get; set; }
        public string ProductGroupProductCategoryName { get; set; }
        public Guid Id { get; set; }
        public Guid ProductGroupId { get; set; }
    }
}