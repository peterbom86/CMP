using Api.Domain;
using CMP.MappingBase;

namespace CMP.Features.Products
{
    public class MappingProfile : BaseProfile
    {
        protected override void CreateMaps()
        {
            CreateMap<Product, ProductDetails.Result>();
            CreateMap<Product, ProductUpdate.Result>();
        }
    }
}