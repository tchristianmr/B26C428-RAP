@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Suplemment - Consumption Entity'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZC_BSUPPL_428CMR as projection on ZI_BSUPPL_428CMR
{
    key BooksupplUUID,
    TravelUUID,
    BookingUUID,
    BookingSupplementID,
    @ObjectModel.text.element: [ 'SupplementDescription' ]
    SupplementID,
    _SupplementText.Description as SupplementDescription : localized,
    CurrencyCode,
    @Semantics.amount.currencyCode: 'CurrencyCode'
    Price,
    @Semantics.systemDateTime.localInstanceLastChangedAt: true
    LocalLastChangedAt,
    /* Associations */
    _Booking : redirected to parent ZC_BOOKING_428CMR,
    _Currency,
    _Product,
    _SupplementText,
    _Travel : redirected to ZC_TRAVEL_428CMR
}
