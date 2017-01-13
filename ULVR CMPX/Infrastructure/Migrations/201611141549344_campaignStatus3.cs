namespace Infrastructure.Migrations
{
    using System;
    using System.Data.Entity.Migrations;
    
    public partial class campaignStatus3 : DbMigration
    {
        public override void Up()
        {
            RenameColumn(table: "dbo.Campaign", name: "Status_Value", newName: "Status");
        }
        
        public override void Down()
        {
            RenameColumn(table: "dbo.Campaign", name: "Status", newName: "Status_Value");
        }
    }
}
