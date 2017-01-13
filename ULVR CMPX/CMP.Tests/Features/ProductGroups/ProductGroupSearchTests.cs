using System.Linq;
using AutoMapper;
using CMP.Features.ProductGroups;
using Infrastructure;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace CMP.Tests.Features.ProductGroups
{
    [TestClass]
    public class ProductGroupSearchTests
    {
        private IConfigurationProvider _config;
        private CmpContext _context;

        [TestInitialize]
        public void Initialize()
        {
            var init = new Initialization.Init();

            _config = Initialization.Init.AutomapperProfiles();
            init.SetupProductGroupData();
            _context = init.GetContext();
        }

        [TestMethod]
        public void ShouldFindProductGroups()
        {
            var request = new ProductGroupSearch.Query
            {
                SearchText = "",
                MaxItems = 2
            };

            var handler = new ProductGroupSearch.Handler(_context, _config);

            var result = handler.Handle(request);

            Assert.AreEqual(3, result.Meta.TotalItemCount);
            Assert.AreEqual(2, result.Items.Count);
            Assert.IsTrue(result.Items.All(i => i.Name.Contains(request.SearchText)));
        }
    }
}