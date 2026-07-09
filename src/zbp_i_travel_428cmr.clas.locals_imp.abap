CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.

    METHODS setTravelNumber FOR DETERMINE ON SAVE
      IMPORTING keys FOR Travel~setTravelNumber.

    METHODS setInitialValue FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~setInitialValue.
    METHODS acceptTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~acceptTravel RESULT result.

    METHODS rejectTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~rejectTravel RESULT result.

    METHODS validateAgency FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateAgency.

    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateCustomer.

    METHODS validateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateDates.

    METHODS validateBookingFee FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateBookingFee.

    METHODS deductDiscount FOR MODIFY
      IMPORTING keys FOR ACTION Travel~deductDiscount RESULT result.

    CONSTANTS: BEGIN OF travel_status,
                 open     TYPE c LENGTH 1 VALUE 'O',
                 accepted TYPE c LENGTH 1 VALUE 'A',
                 rejected TYPE c LENGTH 1 VALUE 'X',
               END OF TRAVEL_status,

               BEGIN OF travel_criticality,
                 neutral     TYPE i VALUE 0,
                 negative    TYPE i VALUE 1,
                 positive    TYPE i VALUE 3,
                 information TYPE i VALUE 5,
               END OF TRAVEL_criticality.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD get_features.
*   01.07.2026: Set the features for the travel entity
    READ ENTITIES OF zi_travel_428cmr IN LOCAL MODE
           ENTITY Travel
           FIELDS ( OverallStatus )
             WITH CORRESPONDING #( keys )
           RESULT DATA(travels)
           FAILED failed.

    result = VALUE #( FOR travel IN travels ( %tky  = travel-%tky
                                              %field-BookingFee = COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                                          THEN if_abap_behv=>fc-f-read_only
                                                                          ELSE if_abap_behv=>fc-f-unrestricted )
                                              %action-acceptTravel = COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                                             THEN if_abap_behv=>fc-o-disabled
                                                                             ELSE if_abap_behv=>fc-o-enabled )
                                              %action-rejectTravel = COND #( WHEN travel-OverallStatus = travel_status-rejected
                                                                             THEN if_abap_behv=>fc-o-disabled
                                                                             ELSE if_abap_behv=>fc-o-enabled )
                                             %assoc-_Booking = COND #( WHEN travel-OverallStatus = travel_status-rejected
                                                                       THEN if_abap_behv=>fc-o-disabled
                                                                       ELSE if_abap_behv=>fc-o-enabled )

                                             %action-deductDiscount = COND #( WHEN travel-%is_draft = if_abap_behv=>mk-off AND
                                                                            ( travel-OverallStatus = travel_status-open OR
                                                                              travel-OverallStatus = travel_status-rejected )
                                                                              THEN if_abap_behv=>fc-o-enabled
                                                                              ELSE if_abap_behv=>fc-o-disabled ) ) ).

  ENDMETHOD.

  METHOD setTravelNumber.
*  29.06.2026: Number range object for travel number is ZTRAVEL
    READ ENTITIES OF zi_travel_428cmr IN LOCAL MODE
            ENTITY Travel
            FIELDS ( TravelID )
            WITH CORRESPONDING #( keys )
            RESULT DATA(travels).

    DELETE travels WHERE TravelID IS NOT INITIAL.
    CHECK travels IS NOT INITIAL.

    SELECT SINGLE FROM ztravel_428cmr FIELDS MAX( travel_id ) INTO @DATA(max_travelid).

    MODIFY ENTITIES OF zi_travel_428cmr IN LOCAL MODE
     ENTITY Travel
     UPDATE FIELDS ( TravelID )
       WITH VALUE #( FOR travel IN travels INDEX INTO i ( %tky = travel-%tky TravelID = max_travelid + i ) ).
  ENDMETHOD.

  METHOD setInitialValue.
*  29.06.2026: Set initial value for travel status and criticality
    READ ENTITIES OF zi_travel_428cmr IN LOCAL MODE
           ENTITY Travel
           FIELDS ( OverallStatus OverallStatusCriticality CurrencyCode  )
             WITH CORRESPONDING #( keys )
           RESULT DATA(travels).

    DELETE travels WHERE OverallStatus IS NOT INITIAL AND CurrencyCode IS NOT INITIAL.
    CHECK travels IS NOT INITIAL.

    MODIFY ENTITIES OF zi_travel_428cmr IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( OverallStatus OverallStatusCriticality CurrencyCode  )
      WITH VALUE #( FOR travel IN travels ( %tky = travel-%tky
                                            OverallStatus = COND #( WHEN travel-OverallStatus IS INITIAL
                                                                    THEN travel_status-open
                                                                    ELSE travel-OverallStatus )
                                            OverallStatusCriticality = COND #( WHEN travel-OverallStatus IS INITIAL
                                                                               THEN travel_criticality-information
                                                                               ELSE travel-OverallStatusCriticality )
                                            CurrencyCode = COND #( WHEN travel-CurrencyCode IS INITIAL
                                                                   THEN 'USD'
                                                                   ELSE travel-CurrencyCode ) ) ).
  ENDMETHOD.

  METHOD acceptTravel.
*  29.06.2026: Set travel status to accepted and criticality to positive
    MODIFY ENTITIES OF zi_travel_428cmr IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( OverallStatus OverallStatusCriticality )
     WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                     OverallStatus = travel_status-accepted
                                     OverallStatusCriticality = travel_criticality-positive ) ).

    READ ENTITIES OF zi_travel_428cmr IN LOCAL MODE
           ENTITY Travel
              ALL FIELDS WITH CORRESPONDING #( keys )
           RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels ( %tky = travel-%tky
                                              %param = travel ) ).
  ENDMETHOD.

  METHOD rejectTravel.
*  29.06.2026: Set travel status to rejected and criticality to negative
    MODIFY ENTITIES OF zi_travel_428cmr IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( OverallStatus OverallStatusCriticality )
      WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                     OverallStatus = travel_status-rejected
                                     OverallStatusCriticality = travel_criticality-negative ) ).

    READ ENTITIES OF zi_travel_428cmr IN LOCAL MODE
           ENTITY Travel
              ALL FIELDS WITH CORRESPONDING #( keys )
           RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels ( %tky = travel-%tky
                                              %param = travel ) ).
  ENDMETHOD.

  METHOD validateAgency.
*  30.06.2026: Validate that the agency is not empty when saving a travel
    READ ENTITIES OF zi_travel_428cmr IN LOCAL MODE
         ENTITY Travel
         FIELDS ( AgencyID )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    DATA agencies TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY agency_id.
    agencies = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING agency_id = AgencyID EXCEPT * ).
    DELETE agencies WHERE agency_id IS INITIAL.

    IF agencies IS NOT INITIAL.
      SELECT FROM /dmo/agency FIELDS agency_id
         FOR ALL ENTRIES IN @agencies
       WHERE agency_id = @agencies-agency_id
        INTO TABLE @DATA(valid_agencies).
    ENDIF.

    LOOP AT travels INTO DATA(travel).
*    clear the messages
      APPEND VALUE #( %tky = travel-%tky %state_area = 'VALIDATE_AGENCY' ) TO reported-travel.

      IF travel-AgencyID IS INITIAL.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                        %state_area = 'VALIDATE_AGENCY'
                        %msg = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_agency_id
                                                            severity = if_abap_behv_message=>severity-error )
                        %element-AgencyID = if_abap_behv=>mk-on
                      ) TO reported-travel.

      ELSEIF NOT line_exists( valid_agencies[ agency_id = travel-AgencyID ] ).
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                        %state_area = 'VALIDATE_AGENCY'
                        %msg = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>agency_unkown
                                                            severity = if_abap_behv_message=>severity-error )
                        %element-AgencyID = if_abap_behv=>mk-on
                      ) TO reported-travel.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateCustomer.
*  30.06.2026: Validate that the customer is not empty when saving a travel
    READ ENTITIES OF zi_travel_428cmr IN LOCAL MODE
         ENTITY Travel
         FIELDS ( CustomerID )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    DATA customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.
    customers = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING customer_id = CustomerID EXCEPT * ).
    DELETE customers WHERE customer_id IS INITIAL.

    IF customers IS NOT INITIAL.
      SELECT FROM /dmo/customer FIELDS customer_id
         FOR ALL ENTRIES IN @customers
       WHERE customer_id = @customers-customer_id
        INTO TABLE @DATA(valid_customers).
    ENDIF.

    LOOP AT travels INTO DATA(travel).
      APPEND VALUE #( %tky = travel-%tky %state_area = 'VALIDATE_CUSTOMER' ) TO reported-travel.

      IF travel-CustomerID IS INITIAL.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                        %state_area = 'VALIDATE_CUSTOMER'
                        %msg = NEW /dmo/cm_flight_messages( textid = /dmo/cm_flight_messages=>enter_customer_id
                                                            severity = if_abap_behv_message=>severity-error )
                        %element-CustomerID = if_abap_behv=>mk-on
                      ) TO reported-travel.

      ELSEIF NOT line_exists( valid_customers[ customer_id = travel-CustomerID ] ).

        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                        %state_area = 'VALIDATE_CUSTOMER'
                        %msg = NEW /dmo/cm_flight_messages( customer_id = travel-CustomerID
                                                            textid = /dmo/cm_flight_messages=>customer_unkown
                                                            severity = if_abap_behv_message=>severity-error )
                       %element-CustomerID = if_abap_behv=>mk-on
                     ) TO reported-travel.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateDates.
*    30.06.2026: Validate that the start date is not after the end date when saving a travel
    READ ENTITIES OF zi_travel_428cmr IN LOCAL MODE
        ENTITY Travel
          FIELDS ( BeginDate EndDate )
          WITH CORRESPONDING #( keys )
        RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).

      " Limpia mensajes previos de ESTA validación
      APPEND VALUE #( %tky = travel-%tky %state_area = 'VALIDATE_DATES' ) TO reported-travel.

      " a) fecha de inicio vacía
      IF travel-BeginDate IS INITIAL.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_begin_date
                                                                          severity = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.

      " b) fecha fin vacía
      IF travel-EndDate IS INITIAL.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky             = travel-%tky
                        %state_area      = 'VALIDATE_DATES'
                        %msg             = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_end_date
                                                                        severity = if_abap_behv_message=>severity-error )
                        %element-EndDate = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.

      " c) fin anterior a inicio
      IF travel-BeginDate IS NOT INITIAL AND travel-EndDate IS NOT INITIAL
                                         AND travel-EndDate < travel-BeginDate.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = NEW /dmo/cm_flight_messages( textid     = /dmo/cm_flight_messages=>begin_date_bef_end_date
                                                                          begin_date = travel-BeginDate
                                                                          end_date   = travel-EndDate
                                                                          severity   = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on
                        %element-EndDate   = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.

      " d) inicio en el pasado
      IF travel-BeginDate IS NOT INITIAL AND travel-BeginDate < cl_abap_context_info=>get_system_date( ).
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = NEW /dmo/cm_flight_messages( textid     = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
                                                                          begin_date = travel-BeginDate
                                                                          severity   = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateBookingFee.
*  30.06.2026: Validate that the booking fee is not negative when saving a travel
    READ ENTITIES OF zi_travel_428cmr IN LOCAL MODE
           ENTITY Travel
           FIELDS ( BookingFee )
             WITH CORRESPONDING #( keys )
           RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).
      APPEND VALUE #( %tky = travel-%tky  %state_area = 'VALIDATE_BOOKINGFEE' ) TO reported-travel.

      IF travel-BookingFee < 0.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky                = travel-%tky
                        %state_area         = 'VALIDATE_BOOKINGFEE'
                        %msg                = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>booking_fee_invalid
                                                                           severity = if_abap_behv_message=>severity-error )
                        %element-BookingFee = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD deductDiscount.
*  06.07.2026: Deduct the discount from the booking fee when saving a travel
    DATA travels_for_update TYPE TABLE FOR UPDATE zi_travel_428cmr.
    DATA(keys_with_valid_discount) = keys.

    LOOP AT keys_with_valid_discount ASSIGNING FIELD-SYMBOL(<key_invalid>)
                                         WHERE %param-discount_percent IS INITIAL
                                            OR %param-discount_percent > 100
                                            OR %param-discount_percent <= 0.

      APPEND VALUE #( %tky = <key_invalid>-%tky ) TO failed-travel.

      APPEND VALUE #( %tky = <key_invalid>-%tky
                      %msg = NEW /dmo/cm_flight_messages( textid = /dmo/cm_flight_messages=>discount_invalid
                                                          severity = if_abap_behv_message=>severity-error )
                     %element-BookingFee = if_abap_behv=>mk-on
                     %op-%action-deductDiscount = if_abap_behv=>mk-on ) TO reported-travel.

      DELETE keys_with_valid_discount.
    ENDLOOP.

    CHECK keys_with_valid_discount IS NOT INITIAL.

    READ ENTITIES OF zi_travel_428cmr IN LOCAL MODE
           ENTITY Travel
           FIELDS ( BookingFee )
             WITH CORRESPONDING #( keys_with_valid_discount )
           RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
*     08.07.2026: Deduct the discount from the booking fee
      DATA(ls_param) = keys_with_valid_discount[ KEY id %tky = <travel>-%tky ]-%param.
*      DATA percentage TYPE decfloat16.
      DATA(percentage) = CONV decfloat16( ls_param-discount_percent / 100 ).

*     08.07.2026: Add Adjustment Percentage based on Adjustment Type (D = Discount, A = Adjustment)
      DATA(amount) = <travel>-BookingFee * percentage.
      IF ls_param-discount_type = 'A'.
        DATA(new_fee) = <travel>-BookingFee + amount.
      ELSE.
        new_fee = <travel>-BookingFee - amount.
      ENDIF.

      APPEND VALUE #( %tky = <travel>-%tky BookingFee = new_fee ) TO travels_for_update.
*      DATA(discount_percent) = keys_with_valid_discount[ KEY id %tky = <travel>-%tky ]-%param-discount_percent.
*      percentage = discount_percent / 100.
*      DATA(reduced_fee) = <travel>-BookingFee * ( 1 - percentage ).

*      APPEND VALUE #( %tky = <travel>-%tky
*                      BookingFee = reduced_fee ) TO travels_for_update.
    ENDLOOP.

    MODIFY ENTITIES OF zi_travel_428cmr IN LOCAL MODE
        ENTITY Travel
        UPDATE FIELDS ( BookingFee )
        WITH travels_for_update.

    READ ENTITIES OF zi_travel_428cmr IN LOCAL MODE
        ENTITY Travel
        ALL FIELDS WITH CORRESPONDING #( keys_with_valid_discount )
        RESULT DATA(travels_after).

* 08.07.2026: Mapping the result from database table already in memory
    result = VALUE #( FOR travel IN travels
                      LET updated_fee = travels_for_update[ %tky = travel-%tky ]-BookingFee
                       IN ( %tky = travel-%tky
                            %param = VALUE #( BASE travel BookingFee = updated_fee ) ) ).

*    result = VALUE #( FOR travel IN travels_after ( %tky = travel-%tky
*                                                    %param = travel ) ).

  ENDMETHOD.

ENDCLASS.
