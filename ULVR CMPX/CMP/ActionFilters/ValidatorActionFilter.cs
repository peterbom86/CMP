using System;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;

namespace CMP.ActionFilters
{
    public class ValidatorActionFilter : IActionFilter
    {
        public bool AllowMultiple
        {
            get
            {
                throw new NotImplementedException();
            }
        }

        public async Task<HttpResponseMessage> ExecuteActionFilterAsync(HttpActionContext actionContext, CancellationToken cancellationToken, Func<Task<HttpResponseMessage>> continuation)
        {
            if (!actionContext.ModelState.IsValid)
            {
                if (actionContext.Request.Method.Method == "GET")
                {
                    actionContext.Response = new HttpResponseMessage(HttpStatusCode.BadRequest);
                    return actionContext.Response;
                }
                else
                {
                    actionContext.Response = actionContext.Request.CreateErrorResponse(
                        HttpStatusCode.BadRequest, actionContext.ModelState);

                    return actionContext.Response;
                }
            }

            var response = await continuation();
            var executedContext = new HttpActionExecutedContext(actionContext, null)
            {
                Response = response
            };

            return response;
        }
    }
}