@EndUserText.label: 'Abstract Entity For Deducting Discount'
define abstract entity ZA_TRAVEL_DISCOUNT_428CMR
{
    @EndUserText.label: 'Adjustment Type'
    @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_DISCOUNT_TYPE_VH', element: 'DiscountType' } }]
    @UI.lineItem: [{ position: 10 }]
    @UI.identification: [{ position: 10 }]
    discount_type : abap.char(1);
    
    @EndUserText.label: 'Adjustment Percentage'
    @UI.lineItem: [{ position: 20 }]
    @UI.identification: [{ position: 20 }]
    discount_percent : abap.int1;    
}
