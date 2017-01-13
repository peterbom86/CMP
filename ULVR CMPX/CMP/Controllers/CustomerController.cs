using System.Web.Http;
using System.Web.Http.Cors;
using CMP.Features.Customers;
using MediatR;

namespace CMP.Controllers
{
    [RoutePrefix("api/customers")]
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    public class CustomerController : ApiController
    {
        private readonly IMediator _mediator;

        public CustomerController(IMediator mediator)
        {
            _mediator = mediator;
        }
        [HttpGet]
        [Route("")]
        public CustomerDetails.Result GetAll()
        {
            var query = new CustomerDetails.Query
            {
            };

            var result = _mediator.Send(query);

            return result;
        }
        [HttpGet]
        [Route("search/{searchText}")]
        public CustomerSearch.Result Search(string searchText)
        {
            var query = new CustomerSearch.Query
            {
                SearchText = searchText
            };

            var result = _mediator.Send(query);

            return result;
        }
    }
}
