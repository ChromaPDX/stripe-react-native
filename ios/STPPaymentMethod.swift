//
//  STPPaymentMethod.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

@_spi(STP) import StripeCore

/// PaymentMethod objects represent your customer's payment instruments. They can be used with PaymentIntents to collect payments.
/// - seealso: https://stripe.com/docs/api/payment_methods
public class STPPaymentMethod: NSObject {
    /// Unique identifier for the object.
    @objc private(set) public var stripeId: String
    /// Time at which the object was created. Measured in seconds since the Unix epoch.
    @objc private(set) public var created: Date?
    /// `YES` if the object exists in live mode or the value `NO` if the object exists in test mode.
    @objc private(set) public var liveMode = false
    /// The type of the PaymentMethod.  The corresponding, similarly named property contains additional information specific to the PaymentMethod type.
    /// e.g. if the type is `STPPaymentMethodTypeCard`, the `card` property is also populated.
  
    /// Billing information associated with the PaymentMethod that may be used or required by particular types of payment methods.
    @objc private(set) public var billingDetails: STPPaymentMethodBillingDetails?
    /// If this is an Alipay PaymentMethod (ie `self.type == STPPaymentMethodTypeAlipay`), this contains additional detailsl
  
    /// The ID of the Customer to which this PaymentMethod is saved. Nil when the PaymentMethod has not been saved to a Customer.
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

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethod.self), self),
            // Identifier
            "stripeId = \(stripeId)",
            // STPPaymentMethod details (alphabetical)
            "alipay = \(String(describing: alipay))",
            "auBECSDebit = \(String(describing: auBECSDebit))",
            "bacsDebit = \(String(describing: bacsDebit))",
            "bancontact = \(String(describing: bancontact))",
            "billingDetails = \(String(describing: billingDetails))",
            "card = \(String(describing: card))",
            "cardPresent = \(String(describing: cardPresent))",
            "created = \(String(describing: created))",
            "customerId = \(customerId ?? "")",
            "ideal = \(String(describing: iDEAL))",
            "eps = \(String(describing: eps))",
            "fpx = \(String(describing: fpx))",
            "giropay = \(String(describing: giropay))",
            "netBanking = \(String(describing: netBanking))",
            "oxxo = \(String(describing: oxxo))",
            "grabPay = \(String(describing: grabPay))",
            "payPal = \(String(describing: payPal))",
            "przelewy24 = \(String(describing: przelewy24))",
            "sepaDebit = \(String(describing: sepaDebit))",
            "sofort = \(String(describing: sofort))",
            "upi = \(String(describing: upi))",
            "afterpay_clearpay = \(String(describing: afterpayClearpay))",
            "blik = \(String(describing: blik))",
            "weChatPay = \(String(describing: weChatPay))",
            "boleto = \(String(describing: boleto))",
            "link = \(String(describing: link))",
            "klarna = \(String(describing: klarna))",
            "affirm = \(String(describing: affirm))",
            "usBankAccount = \(String(describing: usBankAccount))",
            "liveMode = \(liveMode ? "YES" : "NO")",
            "type = \(allResponseFields["type"] as? String ?? "")",
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPPaymentMethodType
    class func stringToTypeMapping() -> [String: NSNumber] {
        return [
            "card": NSNumber(value: STPPaymentMethodType.card.rawValue),
            "ideal": NSNumber(value: STPPaymentMethodType.iDEAL.rawValue),
            "fpx": NSNumber(value: STPPaymentMethodType.FPX.rawValue),
            "card_present": NSNumber(value: STPPaymentMethodType.cardPresent.rawValue),
            "sepa_debit": NSNumber(value: STPPaymentMethodType.SEPADebit.rawValue),
            "bacs_debit": NSNumber(value: STPPaymentMethodType.bacsDebit.rawValue),
            "au_becs_debit": NSNumber(value: STPPaymentMethodType.AUBECSDebit.rawValue),
            "grabpay": NSNumber(value: STPPaymentMethodType.grabPay.rawValue),
            "giropay": NSNumber(value: STPPaymentMethodType.giropay.rawValue),
            "p24": NSNumber(value: STPPaymentMethodType.przelewy24.rawValue),
            "eps": NSNumber(value: STPPaymentMethodType.EPS.rawValue),
            "bancontact": NSNumber(value: STPPaymentMethodType.bancontact.rawValue),
            "netbanking": NSNumber(value: STPPaymentMethodType.netBanking.rawValue),
            "oxxo": NSNumber(value: STPPaymentMethodType.OXXO.rawValue),
            "sofort": NSNumber(value: STPPaymentMethodType.sofort.rawValue),
            "upi": NSNumber(value: STPPaymentMethodType.UPI.rawValue),
            "alipay": NSNumber(value: STPPaymentMethodType.alipay.rawValue),
            "paypal": NSNumber(value: STPPaymentMethodType.payPal.rawValue),
            "afterpay_clearpay": NSNumber(value: STPPaymentMethodType.afterpayClearpay.rawValue),
            "blik": NSNumber(value: STPPaymentMethodType.blik.rawValue),
            "link": NSNumber(value: STPPaymentMethodType.link.rawValue),
            "wechat_pay": NSNumber(value: STPPaymentMethodType.weChatPay.rawValue),
            "boleto": NSNumber(value: STPPaymentMethodType.boleto.rawValue),
            "klarna": NSNumber(value: STPPaymentMethodType.klarna.rawValue),
            "affirm": NSNumber(value: STPPaymentMethodType.affirm.rawValue),
            "us_bank_account": NSNumber(value: STPPaymentMethodType.USBankAccount.rawValue),
        ]
    }

    class func string(from type: STPPaymentMethodType) -> String? {
        return
            (self.stringToTypeMapping() as NSDictionary).allKeys(
                for: NSNumber(value: type.rawValue)
            )
            .first as? String
    }

    class func type(from string: String) -> STPPaymentMethodType {
        let key = string.lowercased()
        let typeNumber = self.stringToTypeMapping()[key]

        if let typeNumber = typeNumber {
            return STPPaymentMethodType(rawValue: Int(truncating: typeNumber)) ?? .unknown
        }

        return .unknown
    }

    class func types(from strings: [String]) -> [NSNumber] {
        var types: [AnyHashable] = []
        for string in strings {
            types.append(NSNumber(value: self.type(from: string).rawValue))
        }
        return types as? [NSNumber] ?? []
    }

    class func paymentMethodTypes(from strings: [String]) -> [STPPaymentMethodType] {
        var types: [STPPaymentMethodType] = []
        for string in strings {
            types.append(self.type(from: string))
        }
        return types
    }

    // MARK: - STPAPIResponseDecodable
    /// :nodoc:
    @objc required init(stripeId: String) {
        self.stripeId = stripeId
        super.init()
    }

    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary

        // Required fields
        guard let stripeId = dict.stp_string(forKey: "id") else {
            return nil
        }

        let paymentMethod = self.init(stripeId: stripeId)
        paymentMethod.allResponseFields = response
        paymentMethod.stripeId = stripeId
        paymentMethod.created = dict.stp_date(forKey: "created")
        paymentMethod.liveMode = dict.stp_bool(forKey: "livemode", or: false)
        paymentMethod.billingDetails = STPPaymentMethodBillingDetails.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "billing_details"))
        paymentMethod.card = STPPaymentMethodCard.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "card"))
        paymentMethod.type = self.type(from: dict.stp_string(forKey: "type") ?? "")
        paymentMethod.iDEAL = STPPaymentMethodiDEAL.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "ideal"))
        if let stp = dict.stp_dictionary(forKey: "fpx") {
            paymentMethod.fpx = STPPaymentMethodFPX.decodedObject(fromAPIResponse: stp)
        }
        if let stp = dict.stp_dictionary(forKey: "card_present") {
            paymentMethod.cardPresent = STPPaymentMethodCardPresent.decodedObject(
                fromAPIResponse: stp)
        }
        paymentMethod.sepaDebit = STPPaymentMethodSEPADebit.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "sepa_debit"))
        paymentMethod.bacsDebit = STPPaymentMethodBacsDebit.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "bacs_debit"))
        paymentMethod.auBECSDebit = STPPaymentMethodAUBECSDebit.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "au_becs_debit"))
        paymentMethod.giropay = STPPaymentMethodGiropay.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "giropay"))
        paymentMethod.eps = STPPaymentMethodEPS.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "eps"))
        paymentMethod.przelewy24 = STPPaymentMethodPrzelewy24.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "p24"))
        paymentMethod.bancontact = STPPaymentMethodBancontact.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "bancontact"))
        paymentMethod.netBanking = STPPaymentMethodNetBanking.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "netbanking"))
        paymentMethod.oxxo = STPPaymentMethodOXXO.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "oxxo"))
        paymentMethod.sofort = STPPaymentMethodSofort.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "sofort"))
        paymentMethod.upi = STPPaymentMethodUPI.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "upi"))
        paymentMethod.customerId = dict.stp_string(forKey: "customer")
        paymentMethod.alipay = STPPaymentMethodAlipay.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "alipay"))
        paymentMethod.grabPay = STPPaymentMethodGrabPay.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "grabpay"))
        paymentMethod.payPal = STPPaymentMethodPayPal.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "paypal"))
        paymentMethod.afterpayClearpay = STPPaymentMethodAfterpayClearpay.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "afterpay_clearpay"))
        paymentMethod.blik = STPPaymentMethodBLIK.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "blik"))
        paymentMethod.weChatPay = STPPaymentMethodWeChatPay.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "wechat_pay"))
        paymentMethod.boleto = STPPaymentMethodBoleto.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "boleto"))
        paymentMethod.link = STPPaymentMethodLink.decodedObject(
                fromAPIResponse: dict.stp_dictionary(forKey: "link"))
        paymentMethod.klarna = STPPaymentMethodKlarna.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "klarna"))
        paymentMethod.affirm = STPPaymentMethodAffirm.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "affirm"))
        paymentMethod.usBankAccount = STPPaymentMethodUSBankAccount.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "us_bank_account"))

        paymentMethod.accessibilityLabel = {
            switch paymentMethod.type {
            case .card:
                guard let card = paymentMethod.card else {
                    return nil
                }
                let brand = STPCardBrandUtilities.stringFrom(card.brand) ?? ""
                let last4 = card.last4 ?? ""
                let last4Spaced = last4.map{ String($0) }.joined(separator: " ")
                let localized = String.Localized.card_brand_ending_in_last_4
                return String(format: localized, brand, last4Spaced)
            case .USBankAccount:
                guard let usBankAccount = paymentMethod.usBankAccount else {
                    return nil
                }
                return String(format: String.Localized.bank_account_ending_in_last_4, usBankAccount.bankName, usBankAccount.last4)

            default:
                return nil
            }
        }()

        return paymentMethod
    }

    // MARK: - STPPaymentOption
    @objc public var image: UIImage {
        if type == .card, let card = card {
            return STPImageLibrary.cardBrandImage(for: card.brand)
        } else {
            return STPImageLibrary.cardBrandImage(for: .unknown)
        }
    }

    @objc public var templateImage: UIImage {
        if type == .card, let card = card {
            return STPImageLibrary.templatedBrandImage(for: card.brand)
        } else {
            return STPImageLibrary.templatedBrandImage(for: .unknown)
        }
    }

    @objc public var label: String {
        switch type {
        case .card:
            if let card = card {
                let brand = STPCardBrandUtilities.stringFrom(card.brand)
                return "\(brand ?? "") \(card.last4 ?? "")"
            } else {
                return STPCardBrandUtilities.stringFrom(.unknown) ?? ""
            }
        case .FPX:
            if let fpx = fpx {
                return STPFPXBank.stringFrom(STPFPXBank.brandFrom(fpx.bankIdentifierCode)) ?? ""
            } else {
                fallthrough
            }
        case .USBankAccount:
            if let usBankAccount = usBankAccount {
                return String(format: String.Localized.bank_account_ending_in_last_4, usBankAccount.bankName, usBankAccount.last4)
            } else {
                fallthrough
            }
        default:
            return type.displayName
        }
    }

    @objc public var isReusable: Bool {
        switch type {
        case .card, .link, .USBankAccount:
            return true
        case .alipay /* Careful! Revisit this if/when we support recurring Alipay */, .AUBECSDebit,
            .bacsDebit, .SEPADebit, .iDEAL, .FPX, .cardPresent, .giropay, .EPS, .payPal,
            .przelewy24, .bancontact,
            .OXXO, .sofort, .grabPay, .netBanking, .UPI, .afterpayClearpay, .blik,
            .weChatPay, .boleto, .klarna, .linkInstantDebit, .affirm, // fall through
            .unknown:
            return false
        @unknown default:
            return false
        }
    }
}

extension STPPaymentMethod {
    var paymentSheetLabel: String {
        switch type {
        case .card:
            return "••••\(card?.last4 ?? "")"
        case .SEPADebit:
            return "••••\(sepaDebit?.last4 ?? "")"
        case .USBankAccount:
            return "••••\(usBankAccount?.last4 ?? "")"
        default:
            return label
        }
    }
}
