namespace Api.Domain.Enums
{
    public class DiscountValueType : Enumeration
    {
        public static readonly DiscountValueType Amount
        = new DiscountValueType(1, "Discount is in monetary units");

        public static readonly DiscountValueType Percent
        = new DiscountValueType(2, "Discount is in percent");

        public DiscountValueType() { }
        private DiscountValueType(int value, string displayName) : base(value, displayName) { }
    }
}