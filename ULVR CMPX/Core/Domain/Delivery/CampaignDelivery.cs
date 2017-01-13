namespace Api.Domain
{
    /// <summary>Information about delivery at campaign level</summary>
    public class CampaignDelivery : Delivery
    {
        /// <summary>The campaign associated with this delivery</summary>
        public Campaign Campaign { get; private set; }

        protected CampaignDelivery()
        {
        }

        public CampaignDelivery(Campaign campaign, int deliveryDateOffset, decimal percent)
        {
            Campaign = campaign;
            DeliveryDateOffset = deliveryDateOffset;
            Percent = percent;
        }
    }
}