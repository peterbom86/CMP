namespace Api.Domain.Enums
{
    /// <summary>
    /// Enum of currencies, using ISO 4217
    /// https://en.wikipedia.org/wiki/ISO_4217
    /// </summary>
    public class Currency : Enumeration
    {
        public static readonly Currency
            DKK = new Currency(208, "Danish krone"),
            NOK = new Currency(578, "Norwegian krone"),
            SEK = new Currency(752, "Swedish krona"),
            GBP = new Currency(826, "Pound sterling"),
            USD = new Currency(840, "United States dollar"),
            EUR = new Currency(978, "Euro");

        public Currency()
        {
        }

        private Currency(int value, string displayName) : base(value, displayName)
        {
        }
    }
}