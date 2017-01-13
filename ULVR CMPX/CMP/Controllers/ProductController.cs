using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Cors;
using CMP.Features;
using CMP.Features.Products;
using MediatR;

namespace Api.Controllers
{
    [RoutePrefix("api/products")]
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    public class ProductController : ApiController
    {
        private readonly IMediator _mediator;

        public ProductController(IMediator mediator)
        {
            _mediator = mediator;
        }

        [HttpGet]
        [Route("search/{searchText}/{max}")]
        public async Task<ProductSearch.Result> Search(string searchText, int max)
        {
            var query = new ProductSearch.Query
            {
                SearchText = searchText,
                Max = max
            };

            var result = await _mediator.SendAsync(query);

            return result;
        }

        [HttpGet]
        [Route("{id}")]
        public ProductDetails.Result Get([FromUri]ProductDetails.Query query)
        {
            var data = _mediator.Send(query);

            return data;
        }

        [HttpPost]
        [Route("update")]
        public ProductUpdate.Result Update(ProductUpdate.Command command)
        {
            return _mediator.Send(command);
        }
    }
}