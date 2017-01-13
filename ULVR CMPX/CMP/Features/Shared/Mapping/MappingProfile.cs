using Api.Domain;
using CMP.Features.Shared.ViewModels;
using CMP.MappingBase;

namespace CMP.Features.Shared.Mapping
{
    public class MappingProfile : BaseProfile
    {
        protected override void CreateMaps()
        {
            CreateMap<Product, ProductVM>();
        }
    }
}