using System.Web.Http;
using System.Web.Http.Cors;
using CMP.Features.ProductGroups;
using MediatR;

namespace CMP.Controllers
{
    [RoutePrefix("api/productGroups")]
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    public class ProductGroupController : ApiController
    {
        private readonly IMediator _mediator;

        public ProductGroupController(IMediator mediator)
        {
            _mediator = mediator;
        }

        [HttpGet]
        [Route("search/{searchText}/{max}")]
        public ProductGroupSearch.Result Search(string searchText, int max)
        {
            var query = new ProductGroupSearch.Query
            {
                SearchText = searchText,
                MaxItems = max
            };

            var result = _mediator.Send(query);

            return result;
        }
    }
}