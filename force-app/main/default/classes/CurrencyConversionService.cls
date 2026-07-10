public with sharing class CurrencyConversionService {

    // Cache of currency rates for this transaction, avoids repeated queries
    private static Map<String, Decimal> currencyRateCache;

    public static Decimal convertAmount(Decimal originalAmount, String fromCurrency, String toCurrency) {

        if (originalAmount == null || String.isBlank(fromCurrency) || String.isBlank(toCurrency)) {
            return originalAmount;
        }

        if (fromCurrency == toCurrency) {
            return originalAmount;
        }

        Map<String, Decimal> rates = getCurrencyRates();

        Decimal fromRate = rates.get(fromCurrency);
        Decimal toRate = rates.get(toCurrency);

        if (fromRate == null || toRate == null || fromRate == 0) {
            return originalAmount; // missing rate — fall back to original amount rather than erroring out
        }

        // Convert: amount -> corporate currency base -> target currency
        Decimal amountInCorporateCurrency = originalAmount / fromRate;
        Decimal convertedAmount = amountInCorporateCurrency * toRate;

        return convertedAmount.setScale(2);
    }

    private static Map<String, Decimal> getCurrencyRates() {
        if (currencyRateCache != null) {
            return currencyRateCache;
        }

        currencyRateCache = new Map<String, Decimal>();

        for (CurrencyType ct : [SELECT IsoCode, ConversionRate FROM CurrencyType WHERE IsActive = true]) {
            currencyRateCache.put(ct.IsoCode, ct.ConversionRate);
        }

        return currencyRateCache;
    }
}