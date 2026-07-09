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
    @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Customer_StdVH', element: 'CustomerID' } }]
    CustomerID,
    CustomerName,
    @ObjectModel.text.element: [ 'AirlineName' ]
    @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Carrier_StdVH', element: 'AirlineID' } }]
    AirlineID,
    _Carrier.Name as AirlineName,
    @ObjectModel.text.element: [ 'ConnectionRoute' ]
    @Consumption.valueHelpDefinition: [{ 
            entity: { 
                name: '/DMO/I_Flight_StdVH', 
                element:'ConnectionID' 
            },
            additionalBinding: [
                {  
                    localElement: 'ConnectionID',
                    element: 'ConnectionID',
                    usage: #FILTER_AND_RESULT
                },
                {
                    localElement: 'FlightDate',
                    element: 'FlightDate',
                    usage: #RESULT
                },
                {
                    localElement: 'FlightPrice',
                    element: 'Price',
                    usage: #RESULT
                },
                {
                    localElement: 'CurrencyCode',
                    element: 'CurrencyCode',
                    usage: #RESULT
                }
            ]
      }]
    ConnectionId,
    ConnectionRoute,
    FlightDate,
    @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CurrencyStdVH', element: 'Currency' } }]
    CurrencyCode,
    @Semantics.amount.currencyCode: 'CurrencyCode'
    FlightPrice,
    @ObjectModel.text.element: [ 'BookingStatusText' ]
    @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Booking_Status_VH', element: 'BookingStatus' } }]
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
