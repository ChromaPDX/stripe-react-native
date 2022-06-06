//
//  STPBlocks.swift
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
import StripeApplePay


/// These values control the labels used in the shipping info collection form.
@objc public enum STPShippingType: Int {
    /// Shipping the purchase to the provided address using a third-party
    /// shipping company.
    case shipping
    /// Delivering the purchase by the seller.
    case delivery
}

/// An enum representing the status of a shipping address validation.
@objc public enum STPShippingStatus: Int {
    /// The shipping address is valid.
    case valid
    /// The shipping address is invalid.
    case invalid
}

/// An enum representing the status of a payment requested from the user.
@objc public enum STPPaymentStatus: Int {
    /// The payment succeeded.
    case success
    /// The payment failed due to an unforeseen error, such as the user's Internet connection being offline.
    case error
    /// The user cancelled the payment (for example, by hitting "cancel" in the Apple Pay dialog).
    case userCancellation
    
    init(applePayStatus: STPApplePayContext.PaymentStatus) {
        switch applePayStatus {
            case .success:
                self = .success
            case .error:
                self = .error
            case .userCancellation:
                self = .userCancellation
        }
    }
}

/// A block that may optionally be called with an error.
/// - Parameter error: The error that occurred, if any.
public typealias STPErrorBlock = (Error?) -> Void
/// A block that contains a boolean success param and may optionally be called with an error.
/// - Parameters:
///   - success:       Whether the task succeeded.
///   - error:         The error that occurred, if any.
public typealias STPBooleanSuccessBlock = (Bool, Error?) -> Void
/// A callback to be run with a JSON response.
/// - Parameters:
///   - jsonResponse:  The JSON response, or nil if an error occured.
///   - error:         The error that occurred, if any.
public typealias STPJSONResponseCompletionBlock = ([AnyHashable: Any]?, Error?) -> Void
/// A callback to be run with a token response from the Stripe API.
/// - Parameters:
///   - token: The Stripe token from the response. Will be nil if an error occurs. - seealso: STPToken
///   - error: The error returned from the response, or nil if none occurs. - seealso: StripeError.h for possible values.
public typealias STPShippingMethodsCompletionBlock = (
    STPShippingStatus, Error?, [PKShippingMethod]?, PKShippingMethod?
) -> Void

/// An enum representing the success and error states of PIN management
@objc public enum STPPinStatus: Int {
    /// The verification object was already redeemed
    case success
    /// The verification object was already redeemed
    case errorVerificationAlreadyRedeemed
    /// The one-time code was incorrect
    case errorVerificationCodeIncorrect
    /// The verification object was expired
    case errorVerificationExpired
    /// The verification object has been attempted too many times
    case errorVerificationTooManyAttempts
    /// An error occured while retrieving the ephemeral key
    case ephemeralKeyError
    /// An unknown error occured
    case unknownError
}


//
//  STPPaymentMethodAddress.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//
import Contacts
import Foundation


/// What set of billing address information you need to collect from your user.
///
/// @note If the user is from a country that does not use zip/postal codes,
/// the user may not be asked for one regardless of this setting.
@objc
public enum STPBillingAddressFields: UInt {
    /// No billing address information
    case none
    /// Just request the user's billing postal code
    case postalCode
    /// Request the user's full billing address
    case full
    /// Just request the user's billing name
    case name
    /// Just request the user's billing ZIP (synonym for STPBillingAddressFieldsZip)
    @available(*, deprecated, message: "Use STPBillingAddressFields.postalCode instead")
    case zip
}

/// STPAddress Contains an address as represented by the Stripe API.
public class STPAddress: NSObject {
    /// The user's full name (e.g. "Jane Doe")
    @objc public var name: String?

    /// The first line of the user's street address (e.g. "123 Fake St")
    @objc public var line1: String?

    /// The apartment, floor number, etc of the user's street address (e.g. "Apartment 1A")
    @objc public var line2: String?

    /// The city in which the user resides (e.g. "San Francisco")
    @objc public var city: String?

    /// The state in which the user resides (e.g. "CA")
    @objc public var state: String?

    /// The postal code in which the user resides (e.g. "90210")
    @objc public var postalCode: String?

    /// The ISO country code of the address (e.g. "US")
    @objc public var country: String?

    /// The phone number of the address (e.g. "8885551212")
    @objc public var phone: String?

    /// The email of the address (e.g. "jane@doe.com")
    @objc public var email: String?

    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// Initializes an empty STPAddress.
    @objc
    public override init() {
        super.init()
    }

    /// Initializes a new STPAddress with data from STPPaymentMethodBillingDetails.
    /// - Parameter billingDetails: The STPPaymentMethodBillingDetails instance you want to populate the STPAddress from.
    /// - Returns: A new STPAddress instance with data copied from the passed in billing details.
    @objc
    public init(paymentMethodBillingDetails billingDetails: STPPaymentMethodBillingDetails) {
        super.init()
        name = billingDetails.name
        phone = billingDetails.phone
        email = billingDetails.email
        let pmAddress = billingDetails.address
        line1 = pmAddress?.line1
        line2 = pmAddress?.line2
        city = pmAddress?.city
        state = pmAddress?.state
        postalCode = pmAddress?.postalCode
        country = pmAddress?.country
    }


    /// Generates a PassKit contact representation of this STPAddress.
    /// - Returns: A new PassKit contact with data copied from this STPAddress instance.
    @objc(PKContactValue)
    public func pkContactValue() -> PKContact {
        let contact = PKContact()
        var personName = PersonNameComponents()
        contact.name = personName
        contact.emailAddress = email
        let address = CNMutablePostalAddress()
        address.street = street() ?? ""
        address.city = city ?? ""
        address.state = state ?? ""
        address.postalCode = postalCode ?? ""
        address.country = country ?? ""
        contact.postalAddress = address
        contact.phoneNumber = CNPhoneNumber(stringValue: phone ?? "")
        return contact
    }

    /// Checks if this STPAddress has any content (possibly invalid) in any of the
    /// desired billing address fields.
    /// Where `containsRequiredFields:` validates that this STPAddress contains valid data in
    /// all of the required fields, this method checks for the existence of *any* data.
    /// For example, if `desiredFields` is `STPBillingAddressFieldsZip`, this will check
    /// if the postalCode is empty.
    /// Note: When `desiredFields == STPBillingAddressFieldsNone`, this method always returns
    /// NO.
    /// @parameter desiredFields The billing address information the caller is interested in.
    /// - Returns: YES if there is any data in this STPAddress that's relevant for those fields.
    @objc(containsContentForBillingAddressFields:)
    public func containsContent(for desiredFields: STPBillingAddressFields) -> Bool {
        switch desiredFields {
        case .none:
            return false
        case .postalCode:
            return (postalCode?.count ?? 0) > 0
        case .full:
            return hasPartialPostalAddress()
        case .name:
            return (name?.count ?? 0) > 0
        default:
            fatalError()
        }
    }


    /// Converts an STPBillingAddressFields enum value into the closest equivalent
    /// representation of PKContactField options
    /// - Parameter billingAddressFields: Stripe billing address fields enum value to convert.
    /// - Returns: The closest representation of the billing address requirement as
    /// a PKContactField value.
    @objc(applePayContactFieldsFromBillingAddressFields:)
    public class func applePayContactFields(from billingAddressFields: STPBillingAddressFields)
        -> Set<PKContactField>
    {
        switch billingAddressFields {
        case .none:
            return Set<PKContactField>([])
        case .postalCode, .full:
            return Set<PKContactField>([.name, .postalAddress])
        case .name:
            return Set<PKContactField>([.name])
        case .zip:
            return Set()
        @unknown default:
            fatalError()
        }
    }


    private func street() -> String? {
        var street: String?
        if let line1 = line1 {
            street = "" + line1
        }
        if let line2 = line2 {
            street = [street ?? "", line2].joined(separator: " ")
        }
        return street
    }

  

    /// Does this STPAddress contain any data in the postal address fields?
    /// If they are all empty or nil, returns NO. Even a single character in a
    /// single field will return YES.
    private func hasPartialPostalAddress() -> Bool {
        return (line1?.count ?? 0) > 0 || (line2?.count ?? 0) > 0 || (city?.count ?? 0) > 0
            || (country?.count ?? 0) > 0 || (state?.count ?? 0) > 0 || (postalCode?.count ?? 0) > 0
    }
}

/// The billing address, a property on `STPPaymentMethodBillingDetails`
public class STPPaymentMethodAddress: NSObject {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// City/District/Suburb/Town/Village.
    @objc public var city: String?
    /// 2-letter country code.
    @objc public var country: String?
    /// Address line 1 (Street address/PO Box/Company name).
    @objc public var line1: String?
    /// Address line 2 (Apartment/Suite/Unit/Building).
    @objc public var line2: String?
    /// ZIP or postal code.
    @objc public var postalCode: String?
    /// State/County/Province/Region.
    @objc public var state: String?

    /// Convenience initializer for creating a STPPaymentMethodAddress from an STPAddress.
    @objc
    public init(address: STPAddress) {
        super.init()
        city = address.city
        country = address.country
        line1 = address.line1
        line2 = address.line2
        postalCode = address.postalCode
        state = address.state
    }

    /// :nodoc:
    @objc public required override init() {
        super.init()
    }

    /// :nodoc:
    private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodAddress.self), self),
            // Properties
            "line1 = \(line1 ?? "")",
            "line2 = \(line2 ?? "")",
            "city = \(city ?? "")",
            "state = \(state ?? "")",
            "postalCode = \(postalCode ?? "")",
            "country = \(country ?? "")",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

  

    @objc
    public class func rootObjectName() -> String? {
        return nil
    }

}


/// Billing information associated with a `STPPaymentMethod` that may be used or required by particular types of payment methods.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-billing_details
public class STPPaymentMethodBillingDetails: NSObject {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// Billing address.
    @objc public var address: STPPaymentMethodAddress?
    /// Email address.
    @objc public var email: String?
    /// Full name.
    @objc public var name: String?
    /// Billing phone number (including extension).
    @objc public var phone: String?
    @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodBillingDetails.self), self),
            // Properties
            "name = \(name ?? "")",
            "phone = \(phone ?? "")",
            "email = \(email ?? "")",
            "address = \(String(describing: address))",
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    /// :nodoc:
    @objc public override required init() {
        super.init()
    }

    // MARK: - STPFormEncodable
    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter:address)): "address",
            NSStringFromSelector(#selector(getter:email)): "email",
            NSStringFromSelector(#selector(getter:name)): "name",
            NSStringFromSelector(#selector(getter:phone)): "phone",
        ]
    }

    @objc
    public class func rootObjectName() -> String? {
        return nil
    }

}

/// PaymentMethod objects represent your customer's payment instruments. They can be used with PaymentIntents to collect payments.
/// - seealso: https://stripe.com/docs/api/payment_methods
public class STPPaymentMethod: NSObject {
    /// Unique identifier for the object.
    @objc private(set) public var stripeId: String
    /// Time at which the object was created. Measured in seconds since the Unix epoch.
    @objc private(set) public var created: Date?
    /// `YES` if the object exists in live mode or the value `NO` if the object exists in test mode.
    @objc private(set) public var liveMode = false
    
    @objc private(set) public var billingDetails: STPPaymentMethodBillingDetails?
    /// The type of the PaymentMethod.  The corresponding, similarly named property contains additional information specific to the PaymentMethod type.
    /// e.g. if the type is `STPPaymentMethodTypeCard`, the `card` property is also populated.
    @objc private(set) public var customerId: String?
    // MARK: - Deprecated
    /// Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    /// @deprecated Metadata is no longer returned to clients using publishable keys. Retrieve them on your server using yoursecret key instead.
    /// - seealso: https://stripe.com/docs/api#metadata
    @available(
        *, deprecated,
        message:
            "Metadata is no longer returned to clients using publishable keys. Retrieve them on your server using your secret key instead."
    )
    @objc private(set) public var metadata: [String: String]?

    /// :nodoc:
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]


    // MARK: - STPAPIResponseDecodable
    /// :nodoc:
    @objc required init(stripeId: String) {
        self.stripeId = stripeId
        super.init()
    }
}
