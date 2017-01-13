using Api.Domain.Base;

namespace Api.Domain
{
    /// <summary>Indicates dip in sales after a product has been part of a campaign</summary>
    public class Dip : Entity
    {
        /// <summary>Indicates the week offset this dip covers (-1, -2, -3, -4, -5)</summary>
        public int WeekOffset { get; set; }

        /// <summary>The dip value in percent (i.e. 20)</summary>
        public decimal Value { get; set; }
    }
}