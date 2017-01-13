namespace Api.Domain.Enums
{
    public class AssortmentStatus : Enumeration
    {
        public static readonly AssortmentStatus Listed
        = new AssortmentStatus(1, "Discount is in monetary units");

        public static readonly AssortmentStatus Delisted
        = new AssortmentStatus(2, "Discount is in percent");

        public AssortmentStatus() { }
        private AssortmentStatus(int value, string displayName) : base(value, displayName) { }
    }
}