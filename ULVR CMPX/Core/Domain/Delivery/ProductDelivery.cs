namespace Api.Domain
{
    /// <summary>Information about delivery at product level</summary>
    public class ProductDelivery : Delivery
    {
        /// <summary>The campaign product relation associated with this delivery</summary>
        public CampaignProductRelation CampaignProductRelation { get; set; }
    }
}
