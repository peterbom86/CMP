using Api.Domain;
using CMP.Features.Campaigns.ViewModels;
using CMP.MappingBase;

namespace CMP.Features.Campaigns
{
    public class MappingProfile : BaseProfile
    {
        protected override void CreateMaps()
        {
            CreateMap<Campaign, Create.Result>().ForMember(m => m.Status, opt => opt.MapFrom(x => x.Status.Value));
            CreateMap<Campaign, Update.Result>().ForMember(m => m.Status, opt => opt.MapFrom(x => x.Status.Value));
            CreateMap<Campaign, CreateUpdateResult>().ForMember(m => m.Status, opt => opt.MapFrom(x => x.Status.Value));
            CreateMap<CampaignProductRelation, Update.Result.CampaignProductRelationVM>();
        }
    }
}