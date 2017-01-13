using System;
using System.Data.Entity;
using System.Linq;
using Api.Domain;
using AutoMapper;
using CMP.MappingBase;
using Infrastructure;
using Moq;
using Ploeh.AutoFixture;

namespace CMP.Tests.Initialization
{
    public class Init
    {
        private Fixture _fixture;
        private Mock<CmpContext> _mockContext;

        public Init()
        {
            _fixture = new Fixture();

            _fixture.Behaviors.OfType<ThrowingRecursionBehavior>().ToList()
                .ForEach(b => _fixture.Behaviors.Remove(b));

            _fixture.Behaviors.Add(new OmitOnRecursionBehavior());

            _mockContext = new Mock<CmpContext>();
        }

        public static IConfigurationProvider AutomapperProfiles()
        {
            // Automapper profiles
            var profileTypes = typeof(BaseProfile).Assembly.GetTypes().Where(type => type.IsSubclassOf(typeof(BaseProfile)));
            var config = new MapperConfiguration(cfg => new MapperConfiguration(x =>
            {
                foreach (var type in profileTypes)
                {
                    var profile = (BaseProfile)Activator.CreateInstance(type);
                    cfg.AddProfile(profile);
                }
            }));

            return config;
        }

        public void SetupProductGroupData()
        {
            var data = _fixture.CreateMany<ProductGroup>().ToList();

            var set = new Mock<DbSet<ProductGroup>>()
                .SetupData(data);

            _mockContext.Setup(c => c.ProductGroups).Returns(set.Object);
        }

        public void SetupCampaignData()
        {
            var data = _fixture.CreateMany<Campaign>().ToList();

            var set = new Mock<DbSet<Campaign>>()
                .SetupData(data);

            _mockContext.Setup(c => c.Campaigns).Returns(set.Object);
        }

        public CmpContext GetContext()
        {
            return _mockContext.Object;
        }

        public Fixture GetFixture()
        {
            return _fixture;
        }
    }
}