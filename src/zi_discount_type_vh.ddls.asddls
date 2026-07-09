@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value help for Discount Type'
@Metadata.ignorePropagatedAnnotations: true
define view entity zi_discount_type_vh as select from /dmo/carrier
{
  key cast('A' as abap.char(1))    as DiscountType,
      cast('Add' as abap.char(10)) as Description
}
where carrier_id = 'AA'

union all

select from /dmo/carrier
{
  key cast('D' as abap.char(1))         as DiscountType,
      cast('Discount' as abap.char(10)) as Description
}
where carrier_id = 'AA'
