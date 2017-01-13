using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Cors;
using CMP.Features;
using CMP.Features.Campaigns;
using MediatR;

namespace CMP.Controllers
{
    [RoutePrefix("api/campaigns")]
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    public class CampaignController : ApiController
    {
        private readonly IMediator _mediator;
        public CampaignController(IMediator mediator)
        {
            _mediator = mediator;
        }

        [HttpPost]
        [Route("")]
        public Create.Result Post(Create.Command command)
        {
            var result = _mediator.Send(command);

            return result;
        }

        [HttpPost]
        [Route("update")]
        public Update.Result Update(Update.Command command)
        {
            var result = _mediator.Send(command);

            return result;
        }

        [HttpPost]
        [Route("AddProductToCampaign")]
        public AddProductToCampaign.Result AddProductToCampaign(AddProductToCampaign.Command command)
        {
            var result = _mediator.Send(command);

            return result;
        }

        [HttpPost]
        [Route("AddProductGroupsToCampaign")]
        public AddProductToCampaign.Result AddProductGroupToCampaign(AddProductToCampaign.Command command)
        {
            var result = _mediator.Send(command);

            return result;
        }

        [HttpPost]
        [Route("AddDeliveryProfile")]
        public AddDeliveryProfile.Result AddDeliveryProfile(AddDeliveryProfile.Command command)
        {
            var result = _mediator.Send(command);

            return result;
        }
        [HttpGet]
        [Route("search/{searchText}/{max}")]
        public async Task<CampaignSearch.Result> Search(string searchText, int max)
        {
            var query = new CampaignSearch.Query
            {
                SearchText = searchText,
                Max = max
            };

            var result = await _mediator.SendAsync(query);

            return result;
        }
    }
}
