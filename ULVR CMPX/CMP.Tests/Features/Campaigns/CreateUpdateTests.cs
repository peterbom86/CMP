using System.Linq;
using Api.Domain;
using AutoMapper;
using CMP.Features.Campaigns;
using CMP.Features.Campaigns.ViewModels;
using Infrastructure;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Ploeh.AutoFixture;

namespace CMP.Tests.Features.Campaigns
{
    [TestClass]
    public class CreateUpdateTests
    {
        private IConfigurationProvider _config;
        private CmpContext _context;
        private Fixture _fixture;

        [TestInitialize]
        public void Initialize()
        {
            var init = new Initialization.Init();

            _config = Initialization.Init.AutomapperProfiles();
            init.SetupCampaignData();
            _context = init.GetContext();
            _fixture = init.GetFixture();
        }

        [TestMethod]
        public void ShouldCreateCampaign()
        {
            var newCampaign = _fixture.Create<Campaign>();

            var command = new Create.Command
            {
                CustomerId = newCampaign.CustomerId.Value,
                EndDate = newCampaign.EndDate,
                Name = newCampaign.Name,
                PriceDate = newCampaign.PriceDate,
                StartDate = newCampaign.StartDate,
                Status = newCampaign.Status.Value,
                Subsidy = newCampaign.Subsidy
            };

            var handler = new Create.Handler(_context, _config);
            var result = handler.Handle(command);

            var mapper = _config.CreateMapper();
            var expectedResult = mapper.Map<Campaign, CreateUpdateResult>(newCampaign);

            Assert.AreEqual(expectedResult.ToString(), result.ToString());
        }

        [TestMethod]
        public void ShouldUpdateCampaign()
        {
            var idToUpdate = _context.Campaigns.First().Id;

            var updatedCampaign = _fixture.Create<Campaign>();

            var command = new Update.Command
            {
                CustomerId = updatedCampaign.CustomerId.Value,
                EndDate = updatedCampaign.EndDate,
                Name = updatedCampaign.Name,
                PriceDate = updatedCampaign.PriceDate,
                StartDate = updatedCampaign.StartDate,
                Status = updatedCampaign.Status.Value,
                Subsidy = updatedCampaign.Subsidy,
                Id = idToUpdate
            };

            var handler = new Update.Handler(_context, _config);

            var result = handler.Handle(command);

            var mapper = _config.CreateMapper();
            var expectedResult = mapper.Map<Campaign, CreateUpdateResult>(updatedCampaign);

            Assert.AreEqual(expectedResult.ToString(), result.ToString());
        }
    }
}