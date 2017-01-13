namespace Infrastructure.Migrations
{
    using System;
    using System.Data.Entity.Migrations;
    
    public partial class assortment : DbMigration
    {
        public override void Up()
        {
            DropIndex("dbo.Assortment", new[] { "Product_Id" });
            RenameColumn(table: "dbo.Assortment", name: "Product_Id", newName: "ProductId");
            AlterColumn("dbo.Assortment", "ProductId", c => c.Guid(nullable: false));
            CreateIndex("dbo.Assortment", "ProductId");
        }
        
        public override void Down()
        {
            DropIndex("dbo.Assortment", new[] { "ProductId" });
            AlterColumn("dbo.Assortment", "ProductId", c => c.Guid());
            RenameColumn(table: "dbo.Assortment", name: "ProductId", newName: "Product_Id");
            CreateIndex("dbo.Assortment", "Product_Id");
        }
    }
}
