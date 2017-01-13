using System.ComponentModel.DataAnnotations.Schema;

namespace Api.Domain.Enums
{
    public class CampaignStatus : Enumeration
    {
        public static readonly CampaignStatus
            Reservation = new ReservationStatus(),
            Planned = new PlannedStatus(),
            Confirmed = new CampaignStatus(),
            Settled = new CampaignStatus(),
            PartiallySettled = new CampaignStatus(),
            Cancelled = new CampaignStatus();

        public CampaignStatus()
        {
        }

        public CampaignStatus(int value, string displayName) : base(value, displayName)
        {
        }

        [NotMapped]
        public bool IsVisibleToCustomerServiceStaff { get; set; }

        public class ReservationStatus : CampaignStatus
        {
            public ReservationStatus() : base(1, "Draft Status")
            {
                IsVisibleToCustomerServiceStaff = false;
            }
        }

        public class PlannedStatus : CampaignStatus
        {
            public PlannedStatus() : base(2, "Awaiting approval")
            {
                IsVisibleToCustomerServiceStaff = true;
            }
        }

        public class ConfirmedStatus : CampaignStatus
        {
            public ConfirmedStatus() : base(3, "Good to go, product should be ordered and scheduled")
            {
                IsVisibleToCustomerServiceStaff = true;
            }
        }

        public class SettledStatus : CampaignStatus
        {
            public SettledStatus() : base(4, "Discounts, subsidies, etc have been paid")
            {
                IsVisibleToCustomerServiceStaff = true;
            }
        }

        public class PartiallySettledStatus : CampaignStatus
        {
            public PartiallySettledStatus() : base(5, "Some discounts, subsidies, etc have yet to be sorted")
            {
                IsVisibleToCustomerServiceStaff = true;
            }
        }

        public class CancelledStatus : CampaignStatus
        {
            public CancelledStatus() : base(6, "Campaign will not happen")
            {
                IsVisibleToCustomerServiceStaff = false;
            }
        }
    }
}