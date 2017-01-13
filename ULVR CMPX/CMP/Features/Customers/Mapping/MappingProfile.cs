using Api.Domain;
using CMP.MappingBase;

namespace CMP.Features.Customers
{
    public class MappingProfile : BaseProfile
    {
        protected override void CreateMaps()
        {
            CreateMap<CustomerHierarchy, CustomerDetails.Result.CustomerHierarchyVM>()
                .ForMember(dto => dto.Children, opt => opt.Ignore());
        }
    }
}