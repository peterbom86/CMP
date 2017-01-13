namespace Infrastructure.Migrations
{
    using System;
    using System.Data.Entity.Migrations;
    
    public partial class campaignStatus : DbMigration
    {
        public override void Up()
        {
            DropForeignKey("dbo.Campaign", "Status_Id", "dbo.CampaignStatus");
            DropIndex("dbo.Campaign", new[] { "Status_Id" });
            AddColumn("dbo.Campaign", "Status_Value", c => c.Int(nullable: false));
            DropColumn("dbo.Campaign", "Status_Id");
            DropTable("dbo.CampaignStatus");
        }
        
        public override void Down()
        {
            CreateTable(
                "dbo.CampaignStatus",
                c => new
                    {
                        Id = c.Guid(nullable: false),
                        TenantId = c.Guid(nullable: false),
                    })
                .PrimaryKey(t => t.Id);
            
            AddColumn("dbo.Campaign", "Status_Id", c => c.Guid());
            DropColumn("dbo.Campaign", "Status_Value");
            CreateIndex("dbo.Campaign", "Status_Id");
            AddForeignKey("dbo.Campaign", "Status_Id", "dbo.CampaignStatus", "Id");
        }
    }
}
