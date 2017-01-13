using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using Api.Domain.Base;
using Api.Domain.Enums;

namespace Api.Domain
{
    public class Campaign : Entity
    {
        /// <summary>The name of the Campaign</summary>
        //[Required]
        public string Name { get; set; }

        /// <summary>The first day of the campaign</summary>
        //[Range(typeof(DateTime), ValidationUtility.MinSystemDateTime, ValidationUtility.MaxSystemDateTime, ErrorMessageResourceName = nameof(Resources.ErrorMessages.DateTimeValidationError), ErrorMessageResourceType = typeof(Resources.ErrorMessages))]
        public DateTime StartDate { get; set; }

        /// <summary>The last day of the campaign</summary>
        //[Range(typeof(DateTime), ValidationUtility.MinSystemDateTime, ValidationUtility.MaxSystemDateTime, ErrorMessageResourceName = nameof(Resources.ErrorMessages.DateTimeValidationError), ErrorMessageResourceType = typeof(Resources.ErrorMessages))]
        public DateTime EndDate { get; set; }

        /// <summary>The date used when calculating discount prices (when a campaign overlaps with a planned product price change)</summary>
        //[Range(typeof(DateTime), ValidationUtility.MinSystemDateTime, ValidationUtility.MaxSystemDateTime, ErrorMessageResourceName = nameof(Resources.ErrorMessages.DateTimeValidationError), ErrorMessageResourceType = typeof(Resources.ErrorMessages))]
        public DateTime PriceDate { get; set; }

        /// <summary>A fixed amount for the customer for running the campaign</summary>
        public decimal Subsidy { get; set; }

        /// <summary>Indicates how far along the campaign is. draft, awaiting customer approval, approved, ...</summary>
        public CampaignStatus Status { get; set; }

        /// <summary>The customer node associated with the campaign</summary>
        public CustomerHierarchy Customer { get; set; }

        /// <summary>The Id of the customer hierarchy node</summary>
        public Guid? CustomerId { get; set; }

        /// <summary>Indicates when and what percentage of the products shoud be delivered (can be overridden at product level)</summary>
        private ICollection<CampaignDelivery> _deliveries { get; set; } = new List<CampaignDelivery>();

        public ReadOnlyCollection<CampaignDelivery> Deliveries
        {
            get
            {
                return _deliveries.ToList().AsReadOnly();
            }
        }

        /// <summary>A collection of products included in the campaign</summary>
        public ICollection<CampaignProductRelation> CampaignProductRelations { get; private set; } = new List<CampaignProductRelation>();

        public void AddProduct(Product product, int volume, int apoVolume, decimal onInvoiceValue, decimal offInvoiceValue, Currency currency)
        {
            var newRelation = new CampaignProductRelation(this, product, volume, apoVolume, onInvoiceValue, offInvoiceValue, currency);

            CampaignProductRelations.Add(newRelation);
        }

        public void AddDelivery(CampaignDelivery delivery)
        {
            _deliveries.Add(delivery);
        }
    }
}