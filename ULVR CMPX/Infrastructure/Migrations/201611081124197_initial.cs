namespace Infrastructure.Migrations
{
    using System;
    using System.Data.Entity.Migrations;
    
    public partial class initial : DbMigration
    {
        public override void Up()
        {
            CreateTable(
                "dbo.Campaign",
                c => new
                    {
                        Id = c.Guid(nullable: false),
                        Name = c.String(),
                        StartDate = c.DateTime(nullable: false, precision: 7, storeType: "datetime2"),
                        EndDate = c.DateTime(nullable: false, precision: 7, storeType: "datetime2"),
                        PriceDate = c.DateTime(nullable: false, precision: 7, storeType: "datetime2"),
                        Subsidy = c.Decimal(nullable: false, precision: 18, scale: 2),
                        CustomerId = c.Guid(),
                        TenantId = c.Guid(nullable: false),
                        Status_Id = c.Guid(),
                    })
                .PrimaryKey(t => t.Id)
                .ForeignKey("dbo.CustomerHierarchy", t => t.CustomerId)
                .ForeignKey("dbo.CampaignStatus", t => t.Status_Id)
                .Index(t => t.CustomerId)
                .Index(t => t.Status_Id);
            
            CreateTable(
                "dbo.CampaignProductRelation",
                c => new
                    {
                        Id = c.Guid(nullable: false),
                        CampaignId = c.Guid(nullable: false),
                        ProductId = c.Guid(nullable: false),
                        Volume = c.Int(nullable: false),
                        ApoVolume = c.Int(nullable: false),
                        OnInvoiceValue = c.Decimal(nullable: false, precision: 18, scale: 2),
                        OffInvoiceValue = c.Decimal(nullable: false, precision: 18, scale: 2),
                        Currency_Value = c.Int(nullable: false),
                        TenantId = c.Guid(nullable: false),
                    })
                .PrimaryKey(t => t.Id)
                .ForeignKey("dbo.Campaign", t => t.CampaignId)
                .ForeignKey("dbo.Product", t => t.ProductId)
                .Index(t => t.CampaignId)
                .Index(t => t.ProductId);
            
            CreateTable(
                "dbo.ProductDelivery",
                c => new
                    {
                        Id = c.Guid(nullable: false),
                        DeliveryDateOffset = c.Int(nullable: false),
                        Percent = c.Decimal(nullable: false, precision: 18, scale: 2),
                        TenantId = c.Guid(nullable: false),
                        CampaignProductRelation_Id = c.Guid(),
                    })
                .PrimaryKey(t => t.Id)
                .ForeignKey("dbo.CampaignProductRelation", t => t.CampaignProductRelation_Id)
                .Index(t => t.CampaignProductRelation_Id);
            
            CreateTable(
                "dbo.Product",
                c => new
                    {
                        Id = c.Guid(nullable: false),
                        Name = c.String(),
                        ProductCode = c.String(),
                        TenantId = c.Guid(nullable: false),
                        ProductGroup_Id = c.Guid(),
                    })
                .PrimaryKey(t => t.Id)
                .ForeignKey("dbo.ProductGroup", t => t.ProductGroup_Id)
                .Index(t => t.ProductGroup_Id);
            
            CreateTable(
                "dbo.Assortment",
                c => new
                    {
                        Id = c.Guid(nullable: false),
                        CustomerId = c.Guid(nullable: false),
                        FromDate = c.DateTime(nullable: false, precision: 7, storeType: "datetime2"),
                        ToDate = c.DateTime(nullable: false, precision: 7, storeType: "datetime2"),
                        Status = c.Int(nullable: false),
                        TenantId = c.Guid(nullable: false),
                        Product_Id = c.Guid(),
                    })
                .PrimaryKey(t => t.Id)
                .ForeignKey("dbo.CustomerHierarchy", t => t.CustomerId)
                .ForeignKey("dbo.Product", t => t.Product_Id)
                .Index(t => t.CustomerId)
                .Index(t => t.Product_Id);
            
            CreateTable(
                "dbo.CustomerHierarchy",
                c => new
                    {
                        Id = c.Guid(nullable: false),
                        HierarchyLevel = c.Int(nullable: false),
                        ParentId = c.Guid(),
                        Name = c.String(),
                        Node = c.String(),
                        TenantId = c.Guid(nullable: false),
                    })
                .PrimaryKey(t => t.Id)
                .ForeignKey("dbo.CustomerHierarchy", t => t.ParentId)
                .Index(t => t.ParentId);
            
            CreateTable(
                "dbo.ProductGroup",
                c => new
                    {
                        Id = c.Guid(nullable: false),
                        Name = c.String(),
                        TenantId = c.Guid(nullable: false),
                        ProductCategory_Id = c.Guid(),
                    })
                .PrimaryKey(t => t.Id)
                .ForeignKey("dbo.ProductCategory", t => t.ProductCategory_Id)
                .Index(t => t.ProductCategory_Id);
            
            CreateTable(
                "dbo.BaselineDip",
                c => new
                    {
                        Id = c.Guid(nullable: false),
                        CustomerId = c.Guid(nullable: false),
                        ProductGroupId = c.Guid(nullable: false),
                        TenantId = c.Guid(nullable: false),
                    })
                .PrimaryKey(t => t.Id)
                .ForeignKey("dbo.CustomerHierarchy", t => t.CustomerId)
                .ForeignKey("dbo.ProductGroup", t => t.ProductGroupId)
                .Index(t => t.CustomerId)
                .Index(t => t.ProductGroupId);
            
            CreateTable(
                "dbo.Dip",
                c => new
                    {
                        Id = c.Guid(nullable: false),
                        WeekOffset = c.Int(nullable: false),
                        Value = c.Decimal(nullable: false, precision: 18, scale: 2),
                        TenantId = c.Guid(nullable: false),
                        BaselineDip_Id = c.Guid(),
                    })
                .PrimaryKey(t => t.Id)
                .ForeignKey("dbo.BaselineDip", t => t.BaselineDip_Id)
                .Index(t => t.BaselineDip_Id);
            
            CreateTable(
                "dbo.ProductCategory",
                c => new
                    {
                        Id = c.Guid(nullable: false),
                        Name = c.String(),
                        TenantId = c.Guid(nullable: false),
                    })
                .PrimaryKey(t => t.Id);
            
            CreateTable(
                "dbo.CampaignDelivery",
                c => new
                    {
                        Id = c.Guid(nullable: false),
                        DeliveryDateOffset = c.Int(nullable: false),
                        Percent = c.Decimal(nullable: false, precision: 18, scale: 2),
                        TenantId = c.Guid(nullable: false),
                        Campaign_Id = c.Guid(),
                    })
                .PrimaryKey(t => t.Id)
                .ForeignKey("dbo.Campaign", t => t.Campaign_Id)
                .Index(t => t.Campaign_Id);
            
            CreateTable(
                "dbo.CampaignStatus",
                c => new
                    {
                        Id = c.Guid(nullable: false),
                        TenantId = c.Guid(nullable: false),
                    })
                .PrimaryKey(t => t.Id);
            
        }
        
        public override void Down()
        {
            DropForeignKey("dbo.Campaign", "Status_Id", "dbo.CampaignStatus");
            DropForeignKey("dbo.CampaignDelivery", "Campaign_Id", "dbo.Campaign");
            DropForeignKey("dbo.Campaign", "CustomerId", "dbo.CustomerHierarchy");
            DropForeignKey("dbo.Product", "ProductGroup_Id", "dbo.ProductGroup");
            DropForeignKey("dbo.ProductGroup", "ProductCategory_Id", "dbo.ProductCategory");
            DropForeignKey("dbo.BaselineDip", "ProductGroupId", "dbo.ProductGroup");
            DropForeignKey("dbo.Dip", "BaselineDip_Id", "dbo.BaselineDip");
            DropForeignKey("dbo.BaselineDip", "CustomerId", "dbo.CustomerHierarchy");
            DropForeignKey("dbo.CampaignProductRelation", "ProductId", "dbo.Product");
            DropForeignKey("dbo.Assortment", "Product_Id", "dbo.Product");
            DropForeignKey("dbo.Assortment", "CustomerId", "dbo.CustomerHierarchy");
            DropForeignKey("dbo.CustomerHierarchy", "ParentId", "dbo.CustomerHierarchy");
            DropForeignKey("dbo.ProductDelivery", "CampaignProductRelation_Id", "dbo.CampaignProductRelation");
            DropForeignKey("dbo.CampaignProductRelation", "CampaignId", "dbo.Campaign");
            DropIndex("dbo.CampaignDelivery", new[] { "Campaign_Id" });
            DropIndex("dbo.Dip", new[] { "BaselineDip_Id" });
            DropIndex("dbo.BaselineDip", new[] { "ProductGroupId" });
            DropIndex("dbo.BaselineDip", new[] { "CustomerId" });
            DropIndex("dbo.ProductGroup", new[] { "ProductCategory_Id" });
            DropIndex("dbo.CustomerHierarchy", new[] { "ParentId" });
            DropIndex("dbo.Assortment", new[] { "Product_Id" });
            DropIndex("dbo.Assortment", new[] { "CustomerId" });
            DropIndex("dbo.Product", new[] { "ProductGroup_Id" });
            DropIndex("dbo.ProductDelivery", new[] { "CampaignProductRelation_Id" });
            DropIndex("dbo.CampaignProductRelation", new[] { "ProductId" });
            DropIndex("dbo.CampaignProductRelation", new[] { "CampaignId" });
            DropIndex("dbo.Campaign", new[] { "Status_Id" });
            DropIndex("dbo.Campaign", new[] { "CustomerId" });
            DropTable("dbo.CampaignStatus");
            DropTable("dbo.CampaignDelivery");
            DropTable("dbo.ProductCategory");
            DropTable("dbo.Dip");
            DropTable("dbo.BaselineDip");
            DropTable("dbo.ProductGroup");
            DropTable("dbo.CustomerHierarchy");
            DropTable("dbo.Assortment");
            DropTable("dbo.Product");
            DropTable("dbo.ProductDelivery");
            DropTable("dbo.CampaignProductRelation");
            DropTable("dbo.Campaign");
        }
    }
}
