@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking - Interface Entity'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_BOOKING_428CMR
  as select from zbooking_428cmr
  association to parent ZI_TRAVEL_428CMR  as _Travel on  $projection.TravelUUID = _Travel.TravelUUID
  composition [0..*] of ZI_BSUPPL_428CMR         as _BookingSupplement
  association [1..1] to /DMO/I_Customer          as _Customer      on  $projection.CustomerID = _Customer.CustomerID
  association [1..1] to /DMO/I_Carrier           as _Carrier       on  $projection.AirlineID = _Carrier.AirlineID
  association [1..1] to /DMO/I_Connection        as _Connection    on  $projection.AirlineID    = _Connection.AirlineID
                                                                   and $projection.ConnectionId = _Connection.ConnectionID
  association [1..1] to /DMO/I_Booking_Status_VH as _BookingStatus on  $projection.BookingStatus = _BookingStatus.BookingStatus
  association [1..1] to I_Currency               as _Currency      on  $projection.CurrencyCode = _Currency.Currency
{
  key booking_uuid          as BookingUUID,
      parent_uuid           as TravelUUID,
      booking_id            as BookingID,
      booking_date          as BookingDate,
      customer_id           as CustomerID,
      concat_with_space(_Customer.FirstName, _Customer.LastName, 1) as CustomerName,
      carrier_id            as AirlineID,
      _Carrier.Name         as AirlineName,
      connection_id         as ConnectionId,
      concat_with_space(_Connection.DepartureAirport, _Connection.DestinationAirport, 1) as ConnectionRoute,
      flight_date           as FlightDate,
      currency_code         as CurrencyCode,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      flight_price          as FlightPrice,
      booking_status        as BookingStatus,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      /** Associatons*/
      _Travel,
      _Customer,
      _Carrier,
      _Connection,
      _BookingStatus,
      _Currency,
      _BookingSupplement
}
