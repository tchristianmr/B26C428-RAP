@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking - Consumption Entity'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZC_BOOKING_428CMR as projection on ZI_BOOKING_428CMR
{
    key BookingUUID,
    TravelUUID,
    BookingID,
    BookingDate,
    @ObjectModel.text.element: [ 'CustomerName' ]
    CustomerID,
    CustomerName,
    @ObjectModel.text.element: [ 'AirlineName' ]
    AirlineID,
    AirlineName,
    @ObjectModel.text.element: [ 'ConnectionRoute' ]
    ConnectionId,
    ConnectionRoute,
    FlightDate,
    CurrencyCode,
    @Semantics.amount.currencyCode: 'CurrencyCode'
    FlightPrice,
    @ObjectModel.text.element: [ 'BookingStatusText' ]
    BookingStatus,
    _BookingStatus._Text.Text as BookingStatusText : localized,
    @Semantics.systemDateTime.localInstanceLastChangedAt: true
    LocalLastChangedAt,
    /* Associations */
    _BookingStatus,
    _BookingSupplement : redirected to composition child ZC_BSUPPL_428CMR,
    _Carrier,
    _Connection,
    _Currency,
    _Customer,
    _Travel : redirected to parent ZC_TRAVEL_428CMR
}
