using Api.Domain.Base;

namespace Api.Domain
{
    /// <summary>Information about when and how many percent of product volume to deliver</summary>
    public class Delivery : Entity
    {
        /// <summary>How many days before campaign start to deliver products (e.g. -7)</summary>
        public int DeliveryDateOffset { get; protected set; }

        /// <summary>The percentage of product volume to deliver</summary>
        public decimal Percent { get; protected set; }
    }
}