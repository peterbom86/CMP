using System;
using System.Collections.Generic;
using Api.Domain.Base;
using Api.Domain.Enums;

namespace Api.Domain
{
    public class CampaignProductRelation : Entity
    {
        /// <summary>The id of the campaign</summary>
        public Guid CampaignId { get; set; }

        /// <summary>The campaign the product is used in</summary>
        public Campaign Campaign { get; set; }

        /// <summary>The id of the product</summary>
        public Guid ProductId { get; set; }

        /// <summary>The product that is part of the campaign</summary>
        public Product Product { get; set; }

        /// <summary>How many products does producer expect to sell during campaign</summary>
        public int Volume { get; set; }

        /// <summary>How many products does the customer expect to sell during the campaign</summary>
        public int ApoVolume { get; set; }

        /// <summary>Indicates if on invoice discount is in percent or absolute currency value</summary>
        //public DiscountValueType OnInvoiceValueType { get; set; }

        /// <summary>The amount of on invoice discount given, can be a percentage or currency value</summary>
        public decimal OnInvoiceValue { get; set; }

        /// <summary>Indicates if off invoice discount is in percent or absolute currency value</summary>
        //public DiscountValueType OffInvoiceValueType { get; set; }

        /// <summary>The amount of off invoice discount given, can be a percentage or currency value</summary>
        public decimal OffInvoiceValue { get; set; }

        /// <summary>
        /// Allows overriding delivery information for campaign, to be product specific.
        /// Indicates when and how many percent to deliver of this product
        /// </summary>
        public ICollection<ProductDelivery> Deliveries { get; set; } = new List<ProductDelivery>();

        /// <summary>Indicates the currency when working with currency value discounts</summary>
        public Currency Currency { get; set; }

        // For EF
        public CampaignProductRelation()
        { }

        public CampaignProductRelation(
            Campaign campaign,
            Product product,
            int volume,
            int apoVolume,
            decimal onInvoiceValue,
            decimal offInvoiceValue,
            Currency currency)
        {
            Campaign = campaign;
            CampaignId = campaign.Id;
            Product = product;
            ProductId = product.Id;
            Volume = volume;
            ApoVolume = apoVolume;
            OnInvoiceValue = onInvoiceValue;
            OffInvoiceValue = offInvoiceValue;
            Currency = currency;
        }
    }
}