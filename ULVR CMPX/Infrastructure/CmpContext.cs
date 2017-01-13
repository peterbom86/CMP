using System;
using System.Data.Entity;
using System.Data.Entity.ModelConfiguration.Conventions;
using Api.Domain;
using Api.Domain.Enums;
using Infrastructure.Migrations;

namespace Infrastructure
{
    /// <summary>Context used to access data</summary>
    public class CmpContext : DbContext
    {
        /// <summary>Initializes a new instance of the <see cref="CmpContext" /> class.</summary>
        public CmpContext() : base()
        {
            Configuration.LazyLoadingEnabled = false;
        }

        #region DbSets

        //public virtual DbSet<Event> Events { get; set; }

        /// <summary>The Campaigns.</summary>
        public virtual DbSet<Campaign> Campaigns { get; set; }

        /// <summary>Products that can be included in campaigns</summary>
        public virtual DbSet<Product> Products { get; set; }

        /// <summary>Group for products</summary>
        public virtual DbSet<ProductGroup> ProductGroups { get; set; }

        /// <summary>Categories for products groups</summary>
        public virtual DbSet<ProductCategory> ProductCategories { get; set; }

        /// <summary>Hierarchy of customer data</summary>
        public virtual DbSet<CustomerHierarchy> CustomerHierarchies { get; set; }

        public virtual DbSet<Assortment> Assortments { get; set; }

        #endregion DbSets

        /// <summary>
        /// This method is called when the model for a derived context has been initialized,
        /// but before the model has been locked down and used to initialize the context.
        /// </summary>
        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            modelBuilder.Properties<DateTime>().Configure(a => a.HasColumnType("DateTime2"));
            modelBuilder.Conventions.Remove<PluralizingTableNameConvention>();
            modelBuilder.Conventions.Remove<OneToManyCascadeDeleteConvention>();

            modelBuilder.ComplexType<AssortmentStatus>().Ignore(a => a.DisplayName);
            modelBuilder.Types<Assortment>().Configure(t => t.Property(bt => bt.Status.Value).HasColumnName("Status").HasColumnType("int"));

            BuildCampaignStatusEnums(modelBuilder, "Status");

            Database.SetInitializer(new MigrateDatabaseToLatestVersion<CmpContext, Configuration>());
        }

        private void BuildCampaignStatusEnums(DbModelBuilder modelBuilder, string columnName)
        {
            BuildEnumeration<CampaignStatus>(modelBuilder, columnName);
            BuildEnumeration<CampaignStatus.ReservationStatus>(modelBuilder, columnName);
            BuildEnumeration<CampaignStatus.PlannedStatus>(modelBuilder, columnName);
            BuildEnumeration<CampaignStatus.ConfirmedStatus>(modelBuilder, columnName);
            BuildEnumeration<CampaignStatus.SettledStatus>(modelBuilder, columnName);
            BuildEnumeration<CampaignStatus.PartiallySettledStatus>(modelBuilder, columnName);
            BuildEnumeration<CampaignStatus.CancelledStatus>(modelBuilder, columnName);
        }

        private void BuildEnumeration<T>(DbModelBuilder modelBuilder, string columnName) where T : Enumeration
        {
            modelBuilder.ComplexType<T>().Ignore(a => a.DisplayName);
            modelBuilder.Types<T>().Configure(t => t.Property(bt => bt.Value).HasColumnName(columnName).HasColumnType("int"));
        }
    }
}