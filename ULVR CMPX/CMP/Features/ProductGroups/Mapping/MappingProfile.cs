using Api.Domain;
using CMP.MappingBase;

namespace CMP.Features.ProductGroups
{
    public class MappingProfile : BaseProfile
    {
        protected override void CreateMaps()
        {
            CreateMap<ProductGroup, ProductGroupSearch.Result.ProductGroupVM>();
        }
    }
}