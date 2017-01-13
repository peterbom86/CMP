namespace Infrastructure.Migrations
{
    using System.Data.Entity.Migrations;
    using System.Linq;
    using Api.Domain.Base;
    using Seed_data;

    internal sealed class Configuration : DbMigrationsConfiguration<CmpContext>
    {
        public Configuration()
        {
            AutomaticMigrationsEnabled = false;
        }

        protected override void Seed(CmpContext context)
        {
            if (context.Products.Any() == false)
            {
                var productCategories = SeedData.GetProductCategorySeed();
                productCategories.ForEach(c => c.TenantId = Entity.Tenant1Id);
                productCategories.ForEach(c => c.ProductGroups.ToList().ForEach(g => g.TenantId = Entity.Tenant1Id));
                productCategories.ForEach(c => c.ProductGroups.ToList().ForEach(g => g.Products.ToList().ForEach(p => p.TenantId = Entity.Tenant1Id)));

                context.ProductCategories.AddRange(productCategories);
            }

            if (context.CustomerHierarchies.Any() == false)
            {
                var customer = SeedData.GetCustomerHierarchySeed();

                // Relationship is currently only one way, via children, assign parent relationship before saving
                RecursiveParentAssign(customer, null);

                context.CustomerHierarchies.Add(customer);
            }

            base.Seed(context);
        }

        /// <summary>Customer seed data only contains child navigation props, resolve parent navigation props also, recursively</summary>
        private void RecursiveParentAssign(Api.Domain.CustomerHierarchy customer, Api.Domain.CustomerHierarchy parent)
        {
            foreach (var child in customer.Children)
            {
                RecursiveParentAssign(child, customer);
            }

            if (parent != null)
            {
                customer.Parent = parent;
            }
        }
    }
}
