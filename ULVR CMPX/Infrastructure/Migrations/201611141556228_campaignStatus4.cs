namespace Infrastructure.Migrations
{
    using System;
    using System.Data.Entity.Migrations;
    
    public partial class campaignStatus4 : DbMigration
    {
        public override void Up()
        {
            DropColumn("dbo.Campaign", "Status_IsVisibleToCustomers");
        }
        
        public override void Down()
        {
            AddColumn("dbo.Campaign", "Status_IsVisibleToCustomers", c => c.Boolean(nullable: false));
        }
    }
}
