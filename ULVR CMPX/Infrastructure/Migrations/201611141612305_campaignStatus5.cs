namespace Infrastructure.Migrations
{
    using System;
    using System.Data.Entity.Migrations;
    
    public partial class campaignStatus5 : DbMigration
    {
        public override void Up()
        {
            RenameColumn(table: "dbo.Campaign", name: "Status", newName: "Status_Value");
            RenameColumn(table: "dbo.Assortment", name: "Status", newName: "Status_Value");
        }
        
        public override void Down()
        {
            RenameColumn(table: "dbo.Assortment", name: "Status_Value", newName: "Status");
            RenameColumn(table: "dbo.Campaign", name: "Status_Value", newName: "Status");
        }
    }
}
