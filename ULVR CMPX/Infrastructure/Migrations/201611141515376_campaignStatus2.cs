namespace Infrastructure.Migrations
{
    using System;
    using System.Data.Entity.Migrations;
    
    public partial class campaignStatus2 : DbMigration
    {
        public override void Up()
        {
            AddColumn("dbo.Campaign", "Status_IsVisibleToCustomers", c => c.Boolean(nullable: false));
        }
        
        public override void Down()
        {
            DropColumn("dbo.Campaign", "Status_IsVisibleToCustomers");
        }
    }
}
