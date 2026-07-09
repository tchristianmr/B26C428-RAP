CLASS lhc_booking DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS setBookingNumber FOR DETERMINE ON SAVE
      IMPORTING keys FOR Booking~setBookingNumber.

    METHODS setBookingDate FOR DETERMINE ON SAVE
      IMPORTING keys FOR Booking~setBookingDate.

    METHODS setInitialStatusBooking FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Booking~setInitialStatusBooking.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Booking RESULT result.

    METHODS validateConnection FOR VALIDATE ON SAVE
      IMPORTING keys FOR Booking~validateConnection.

    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Booking~validateCustomer.

    METHODS validateFlightPrice FOR VALIDATE ON SAVE
      IMPORTING keys FOR Booking~validateFlightPrice.

    CONSTANTS:
      BEGIN OF booking_status,
        new      TYPE c LENGTH 1 VALUE 'N',   " New
        booked   TYPE c LENGTH 1 VALUE 'B',   " Booked
        canceled TYPE c LENGTH 1 VALUE 'X',   " Canceled
      END OF booking_status.
ENDCLASS.

CLASS lhc_booking IMPLEMENTATION.

  METHOD setBookingNumber.
*  07.07.2026:  SET BOOKING NUMBER
    DATA: max_bookingid   TYPE /dmo/booking_id,
          bookings_update TYPE TABLE FOR UPDATE zi_travel_428cmr\\Booking.

    READ ENTITIES OF zi_travel_428cmr IN LOCAL MODE
           ENTITY Booking BY \_Travel
           FIELDS ( TravelUUID )
             WITH CORRESPONDING #( keys )
           RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).
      READ ENTITIES OF zi_travel_428cmr IN LOCAL MODE
          ENTITY Travel BY \_Booking
          FIELDS ( BookingID )
          WITH VALUE #( ( %tky = travel-%tky ) )
          RESULT DATA(bookings).

      max_bookingid = '0000'.

      LOOP AT bookings INTO DATA(booking).
        IF booking-BookingID > max_bookingid.
          max_bookingid = booking-BookingID.
        ENDIF.
      ENDLOOP.

      LOOP AT bookings INTO booking WHERE BookingID IS INITIAL.
        max_bookingid += 1.
        APPEND VALUE #( %tky = booking-%tky BookingID = max_bookingid ) TO bookings_update.
      ENDLOOP.


      MODIFY ENTITIES OF zi_travel_428cmr IN LOCAL MODE
          ENTITY Booking
          UPDATE FIELDS ( BookingID )
          WITH bookings_update.

    ENDLOOP.
  ENDMETHOD.

  METHOD setBookingDate.
* 07.07.2026: SET BOOKING DATE
    READ ENTITIES OF zi_travel_428cmr IN LOCAL MODE
            ENTITY Booking
              FIELDS ( BookingDate )
              WITH CORRESPONDING #( keys )
            RESULT DATA(bookings).

    DELETE bookings WHERE BookingDate IS NOT INITIAL.
    CHECK bookings IS NOT INITIAL.

    LOOP AT bookings ASSIGNING FIELD-SYMBOL(<booking>).
      <booking>-BookingDate = cl_abap_context_info=>get_system_date( ).
    ENDLOOP.

    MODIFY ENTITIES OF zi_travel_428cmr IN LOCAL MODE
      ENTITY Booking
        UPDATE FIELDS ( BookingDate )
        WITH CORRESPONDING #( bookings ).
  ENDMETHOD.

  METHOD setInitialStatusBooking.
*  07.07.2026: SET INITIAL STATUS BOOKING
    READ ENTITIES OF zi_travel_428cmr IN LOCAL MODE
          ENTITY Booking
            FIELDS ( BookingStatus )
            WITH CORRESPONDING #( keys )
          RESULT DATA(bookings).

    DELETE bookings WHERE BookingStatus IS NOT INITIAL.
    CHECK bookings IS NOT INITIAL.

    MODIFY ENTITIES OF zi_travel_428cmr IN LOCAL MODE
      ENTITY Booking
        UPDATE FIELDS ( BookingStatus )
        WITH VALUE #( FOR booking IN bookings
                      ( %tky          = booking-%tky
                        BookingStatus = booking_status-new ) ).
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD validateConnection.
*  07.07.2026: VALIDATE CONNECTION
    READ ENTITIES OF zi_travel_428cmr IN LOCAL MODE
          ENTITY Booking
          FIELDS ( BookingID AirlineID ConnectionID FlightDate )
            WITH CORRESPONDING #( keys )
          RESULT DATA(bookings).

    READ ENTITIES OF zi_travel_428cmr IN LOCAL MODE
           ENTITY Booking BY \_Travel
             FROM CORRESPONDING #( bookings )
             LINK DATA(travel_booking_links).

    LOOP AT bookings ASSIGNING FIELD-SYMBOL(<booking>).

      APPEND VALUE #( %tky        = <booking>-%tky
                      %state_area = 'VALIDATE_CONNECTION' ) TO reported-booking.

      " a) aerolínea vacía
      IF <booking>-AirlineID IS INITIAL.
        APPEND VALUE #( %tky = <booking>-%tky ) TO failed-booking.
        APPEND VALUE #( %tky               = <booking>-%tky
                        %state_area        = 'VALIDATE_CONNECTION'
                        %msg               = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_airline_id
                                                                          severity = if_abap_behv_message=>severity-error )
                        %path              = VALUE #( travel-%tky = travel_booking_links[ KEY id source-%tky = <booking>-%tky ]-target-%tky )
                        %element-AirlineID = if_abap_behv=>mk-on )
                     TO reported-booking.
      ENDIF.

      " b) conexión vacía
      IF <booking>-ConnectionID IS INITIAL.
        APPEND VALUE #( %tky = <booking>-%tky ) TO failed-booking.
        APPEND VALUE #( %tky                  = <booking>-%tky
                        %state_area           = 'VALIDATE_CONNECTION'
                        %msg                  = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_connection_id
                                                                             severity = if_abap_behv_message=>severity-error )
                        %path                 = VALUE #( travel-%tky = travel_booking_links[ KEY id source-%tky = <booking>-%tky ]-target-%tky )
                        %element-ConnectionID = if_abap_behv=>mk-on )
                     TO reported-booking.
      ENDIF.

      " c) fecha de vuelo vacía
      IF <booking>-FlightDate IS INITIAL.
        APPEND VALUE #( %tky = <booking>-%tky ) TO failed-booking.
        APPEND VALUE #( %tky                = <booking>-%tky
                        %state_area         = 'VALIDATE_CONNECTION'
                        %msg                = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_flight_date
                                                                           severity = if_abap_behv_message=>severity-error )
                        %path               = VALUE #( travel-%tky = travel_booking_links[ KEY id source-%tky = <booking>-%tky ]-target-%tky )
                        %element-FlightDate = if_abap_behv=>mk-on )
                     TO reported-booking.
      ENDIF.

      " d) la terna completa debe existir como vuelo real
      IF <booking>-AirlineID    IS NOT INITIAL AND
         <booking>-ConnectionID IS NOT INITIAL AND
         <booking>-FlightDate   IS NOT INITIAL.

        SELECT SINGLE Carrier_ID, Connection_ID, Flight_Date
          FROM /dmo/flight
          WHERE carrier_id    = @<booking>-AirlineID
            AND connection_id = @<booking>-ConnectionID
            AND flight_date   = @<booking>-FlightDate
          INTO @DATA(flight).

        IF sy-subrc <> 0.
          APPEND VALUE #( %tky = <booking>-%tky ) TO failed-booking.
          APPEND VALUE #( %tky                  = <booking>-%tky
                          %state_area           = 'VALIDATE_CONNECTION'
                          %msg                  = NEW /dmo/cm_flight_messages( textid      = /dmo/cm_flight_messages=>no_flight_exists
                                                                               carrier_id  = <booking>-AirlineID
                                                                               flight_date = <booking>-FlightDate
                                                                               severity    = if_abap_behv_message=>severity-error )
                          %path                 = VALUE #( travel-%tky = travel_booking_links[ KEY id source-%tky = <booking>-%tky ]-target-%tky )
                          %element-FlightDate   = if_abap_behv=>mk-on
                          %element-AirlineID    = if_abap_behv=>mk-on
                          %element-ConnectionID = if_abap_behv=>mk-on )
                       TO reported-booking.
        ENDIF.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD validateCustomer.
*  07.07.2026: VALIDATE CUSTOMER
    " 1. Leer el CustomerID de las reservas implicadas
    READ ENTITIES OF zi_travel_428cmr IN LOCAL MODE
           ENTITY Booking
           FIELDS ( CustomerID )
           WITH CORRESPONDING #( keys )
           RESULT DATA(bookings).

    " 2. Resolver el viaje padre de cada reserva (solo la tabla de enlaces)
    READ ENTITIES OF zi_travel_428cmr IN LOCAL MODE
           ENTITY Booking BY \_Travel
           FROM CORRESPONDING #( bookings )
           LINK DATA(travel_booking_links).

    " 3. Comprobar la existencia en una sola lectura
    DATA customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.
    customers = CORRESPONDING #( bookings DISCARDING DUPLICATES MAPPING customer_id = CustomerID EXCEPT * ).
    DELETE customers WHERE customer_id IS INITIAL.

    IF customers IS NOT INITIAL.
      SELECT FROM /dmo/customer FIELDS customer_id
              FOR ALL ENTRIES IN @customers
            WHERE customer_id = @customers-customer_id
             INTO TABLE @DATA(valid_customers).
    ENDIF.

    " 4. Evaluar cada reserva, con la genealogía en cada mensaje
    LOOP AT bookings INTO DATA(booking).
      APPEND VALUE #( %tky = booking-%tky %state_area = 'VALIDATE_CUSTOMER' ) TO reported-booking.

      IF booking-CustomerID IS INITIAL.
        APPEND VALUE #( %tky = booking-%tky ) TO failed-booking.
        APPEND VALUE #( %tky                = booking-%tky
                        %state_area         = 'VALIDATE_CUSTOMER'
                        %msg                = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_customer_id
                                                                           severity = if_abap_behv_message=>severity-error )
                        %path               = VALUE #( travel-%tky = travel_booking_links[ KEY id source-%tky = booking-%tky ]-target-%tky )
                        %element-CustomerID = if_abap_behv=>mk-on ) TO reported-booking.

      ELSEIF NOT line_exists( valid_customers[ customer_id = booking-CustomerID ] ).
        APPEND VALUE #( %tky = booking-%tky ) TO failed-booking.
        APPEND VALUE #( %tky                = booking-%tky
                        %state_area         = 'VALIDATE_CUSTOMER'
                        %msg                = NEW /dmo/cm_flight_messages( customer_id = booking-CustomerID
                                                                           textid      = /dmo/cm_flight_messages=>customer_unkown
                                                                           severity    = if_abap_behv_message=>severity-error )
                        %path               = VALUE #( travel-%tky = travel_booking_links[ KEY id source-%tky = booking-%tky ]-target-%tky )
                        %element-CustomerID = if_abap_behv=>mk-on ) TO reported-booking.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateFlightPrice.
    READ ENTITIES OF zi_travel_428cmr IN LOCAL MODE
          ENTITY Booking
          FIELDS ( FlightPrice )
          WITH CORRESPONDING #( keys )
          RESULT DATA(bookings).

    READ ENTITIES OF zi_travel_428cmr IN LOCAL MODE
         ENTITY Booking BY \_Travel
         FROM CORRESPONDING #( bookings )
         LINK DATA(travel_booking_links).

    LOOP AT bookings INTO DATA(booking).
      APPEND VALUE #( %tky = booking-%tky %state_area = 'VALIDATE_FLIGHTPRICE' ) TO reported-booking.

      IF booking-FlightPrice < 0.
        APPEND VALUE #( %tky = booking-%tky ) TO failed-booking.
        APPEND VALUE #( %tky                 = booking-%tky
                        %state_area          = 'VALIDATE_FLIGHTPRICE'
                        %msg                 = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>flight_price_invalid
                                                                            severity = if_abap_behv_message=>severity-error )
                        %path                = VALUE #( travel-%tky = travel_booking_links[ KEY id source-%tky = booking-%tky ]-target-%tky )
                        %element-FlightPrice = if_abap_behv=>mk-on )
                     TO reported-booking.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

