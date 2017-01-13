using System.Web.Http;
using System.Web.Http.Cors;
using CMP.Features.Assortments;
using MediatR;

namespace CMP.Controllers
{
    [RoutePrefix("api/campaigns")]
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    public class AssortmentController : ApiController
    {
        private readonly IMediator _mediator;
        public AssortmentController(IMediator mediator)
        {
            _mediator = mediator;
        }

        [HttpPost]
        [Route("create")]
        public Create.Result Create(Create.Command command)
        {
            var result = _mediator.Send(command);

            return result;
        }
    }
}
