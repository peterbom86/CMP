using AutoMapper;

namespace CMP.MappingBase
{
    public abstract class BaseProfile : Profile
    {
        protected BaseProfile()
        {
            CreateMaps();
        }

        protected abstract void CreateMaps();
    }
}