import PassKit
import StripeApplePay
import StripeCore

@objc(StripeSdk)
class StripeSdk: RCTEventEmitter, UIAdaptivePresentationControllerDelegate {
    var merchantIdentifier: String? = nil
    var urlScheme: String? = nil

    var applePayCompletionCallback: STPIntentClientSecretCompletionBlock? = nil
    var applePayRequestResolver: RCTPromiseResolveBlock? = nil
    var applePayRequestRejecter: RCTPromiseRejectBlock? = nil
    var applePayCompletionRejecter: RCTPromiseRejectBlock? = nil
    var confirmApplePayPaymentResolver: RCTPromiseResolveBlock? = nil
    var confirmPaymentResolver: RCTPromiseResolveBlock? = nil
    
    var confirmPaymentClientSecret: String? = nil
    
    var shippingMethodUpdateHandler: ((PKPaymentRequestShippingMethodUpdate) -> Void)? = nil
    var shippingContactUpdateHandler: ((PKPaymentRequestShippingContactUpdate) -> Void)? = nil
    
    override func supportedEvents() -> [String]! {
        return ["onDidSetShippingMethod", "onDidSetShippingContact"]
    }
    
    @objc override static func requiresMainQueueSetup() -> Bool {
        return false
    }
    
    @objc override func constantsToExport() -> [AnyHashable : Any] {
        return [
            "API_VERSIONS": [
                "CORE": STPAPIClient.apiVersion,
                "ISSUING": STPAPIClient.apiVersion,
            ]
        ]
    }
    
    @objc(initialise:resolver:rejecter:)
    func initialise(params: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        let publishableKey = params["publishableKey"] as! String
        let appInfo = params["appInfo"] as! NSDictionary
        let stripeAccountId = params["stripeAccountId"] as? String
//        let params3ds = params["threeDSecureParams"] as? NSDictionary
        let urlScheme = params["urlScheme"] as? String
        let merchantIdentifier = params["merchantIdentifier"] as? String
        
        self.urlScheme = urlScheme
        
        STPAPIClient.shared.publishableKey = publishableKey
        STPAPIClient.shared.stripeAccount = stripeAccountId
        
        let name = RCTConvert.nsString(appInfo["name"]) ?? ""
        let partnerId = RCTConvert.nsString(appInfo["partnerId"]) ?? ""
        let version = RCTConvert.nsString(appInfo["version"]) ?? ""
        let url = RCTConvert.nsString(appInfo["url"]) ?? ""
        
        STPAPIClient.shared.appInfo = STPAppInfo(name: name, partnerId: partnerId, version: version, url: url)
        self.merchantIdentifier = merchantIdentifier
        resolve(NSNull())
    }
    
    @objc(updateApplePaySummaryItems:errorAddressFields:resolver:rejecter:)
    func updateApplePaySummaryItems(summaryItems: NSArray, errorAddressFields: [NSDictionary], resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        if (shippingMethodUpdateHandler == nil && shippingContactUpdateHandler == nil) {
            resolve(Errors.createError(ErrorType.Failed, "You can use this method only after either onDidSetShippingMethod or onDidSetShippingContact events emitted"))
            return
        }
        var paymentSummaryItems: [PKPaymentSummaryItem] = []
        if let items = summaryItems as? [[String : Any]] {
            for item in items {
                let label = item["label"] as? String ?? ""
                let amount = NSDecimalNumber(string: item["amount"] as? String ?? "")
                let type = Mappers.mapToPaymentSummaryItemType(type: item["type"] as? String)
                paymentSummaryItems.append(PKPaymentSummaryItem(label: label, amount: amount, type: type))
            }
        }
        var shippingAddressErrors: [Error] = []

        for item in errorAddressFields {
            let field = item["field"] as! String
            let message = item["message"] as? String ?? field + " error"
            shippingAddressErrors.append(PKPaymentRequest.paymentShippingAddressInvalidError(withKey: field, localizedDescription: message))
        }

        shippingMethodUpdateHandler?(PKPaymentRequestShippingMethodUpdate.init(paymentSummaryItems: paymentSummaryItems))
        shippingContactUpdateHandler?(PKPaymentRequestShippingContactUpdate.init(errors: shippingAddressErrors, paymentSummaryItems: paymentSummaryItems, shippingMethods: []))
        self.shippingMethodUpdateHandler = nil
        self.shippingContactUpdateHandler = nil
        resolve([])
    }
    
    @objc(openApplePaySetup:rejecter:)
    func openApplePaySetup(resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        let library = PKPassLibrary.init()
        if (library.responds(to: #selector(PKPassLibrary.openPaymentSetup))) {
            library.openPaymentSetup()
            resolve([])
        } else {
            resolve(Errors.createError(ErrorType.Failed, "Cannot open payment setup"))
        }
    }
    
    
    func applePayContext(_ context: STPApplePayContext, didSelect shippingMethod: PKShippingMethod, handler: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void) {
        self.shippingMethodUpdateHandler = handler
        sendEvent(withName: "onDidSetShippingMethod", body: ["shippingMethod": Mappers.mapFromShippingMethod(shippingMethod: shippingMethod)])
    }
    
    func applePayContext(_ context: STPApplePayContext, didSelectShippingContact contact: PKContact, handler: @escaping (PKPaymentRequestShippingContactUpdate) -> Void) {
        self.shippingContactUpdateHandler = handler
        sendEvent(withName: "onDidSetShippingContact", body: ["shippingContact": Mappers.mapFromShippingContact(shippingContact: contact)])
    }
    
    func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: STPPaymentMethod, paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock) {
        self.applePayCompletionCallback = completion
        
        let address = paymentMethod.billingDetails?.address?.line1?.split(whereSeparator: \.isNewline)
        if (address?.indices.contains(0) == true) {
            paymentMethod.billingDetails?.address?.line1 = String(address?[0] ?? "")
        }
        if (address?.indices.contains(1) == true) {
            paymentMethod.billingDetails?.address?.line2 = String(address?[1] ?? "")
        }
        
        let method = Mappers.mapFromPaymentMethod(paymentMethod)
        self.applePayRequestResolver?(Mappers.createResult("paymentMethod", method))
        self.applePayRequestRejecter = nil
    }
    
    @objc(confirmApplePayPayment:resolver:rejecter:)
    func confirmApplePayPayment(clientSecret: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        self.applePayCompletionRejecter = reject
        self.confirmApplePayPaymentResolver = resolve
        self.applePayCompletionCallback?(clientSecret, nil)
    }
    
    func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPPaymentStatus, error: Error?) {
        switch status {
        case .success:
            applePayCompletionRejecter = nil
            applePayRequestRejecter = nil
            confirmApplePayPaymentResolver?([])
            break
        case .error:
            let message = "Payment not completed"
            applePayCompletionRejecter?(ErrorType.Failed, message, nil)
            applePayRequestRejecter?(ErrorType.Failed, message, nil)
            applePayCompletionRejecter = nil
            applePayRequestRejecter = nil
            break
        case .userCancellation:
            let message = "The payment has been canceled"
            applePayCompletionRejecter?(ErrorType.Canceled, message, nil)
            applePayRequestRejecter?(ErrorType.Canceled, message, nil)
            applePayCompletionRejecter = nil
            applePayRequestRejecter = nil
            break
        @unknown default:
            let message = "Payment not completed"
            applePayCompletionRejecter?(ErrorType.Unknown, message, nil)
            applePayRequestRejecter?(ErrorType.Unknown, message, nil)
            applePayCompletionRejecter = nil
            applePayRequestRejecter = nil
        }
    }
    
    @objc(isApplePaySupported:rejecter:)
    func isApplePaySupported(resolver resolve: @escaping RCTPromiseResolveBlock,
                             rejecter reject: @escaping RCTPromiseRejectBlock) {
        let isSupported = StripeAPI.deviceSupportsApplePay()
        resolve(isSupported)
    }
  
    @objc(handleURLCallback:resolver:rejecter:)
    func handleURLCallback(url: String?, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
      guard let url = url else {
        resolve(false)
        return;
      }
      let urlObj = URL(string: url)
      if (urlObj == nil) {
        resolve(false)
      } else {
        DispatchQueue.main.async {
          let stripeHandled = StripeAPI.handleURLCallback(with: urlObj!)
          resolve(stripeHandled)
        }
      }
    }
  
    @objc(presentApplePay:resolver:rejecter:)
    func presentApplePay(params: NSDictionary,
                         resolver resolve: @escaping RCTPromiseResolveBlock,
                         rejecter reject: @escaping RCTPromiseRejectBlock) {
        if (merchantIdentifier == nil) {
            reject(ErrorType.Failed, "You must provide merchantIdentifier", nil)
            return
        }
        
        if (params["jcbEnabled"] as? Bool == true) {
            StripeAPI.additionalEnabledApplePayNetworks = [.JCB]
        }
        
        guard let summaryItems = params["cartItems"] as? NSArray else {
            reject(ErrorType.Failed, "You must provide the items for purchase", nil)
            return
        }
        guard let country = params["country"] as? String else {
            reject(ErrorType.Failed, "You must provide the country", nil)
            return
        }
        guard let currency = params["currency"] as? String else {
            reject(ErrorType.Failed, "You must provide the payment currency", nil)
            return
        }
        
        self.applePayRequestResolver = resolve
        self.applePayRequestRejecter = reject
        
        let merchantIdentifier = self.merchantIdentifier ?? ""
        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: merchantIdentifier, country: country, currency: currency)
        
        let requiredShippingAddressFields = params["requiredShippingAddressFields"] as? NSArray ?? NSArray()
        let requiredBillingContactFields = params["requiredBillingContactFields"] as? NSArray ?? NSArray()
        let shippingMethods = params["shippingMethods"] as? NSArray ?? NSArray()
        
        paymentRequest.requiredShippingContactFields = Set(requiredShippingAddressFields.map {
            Mappers.mapToPKContactField(field: $0 as! String)
        })
        
        paymentRequest.requiredBillingContactFields = Set(requiredBillingContactFields.map {
            Mappers.mapToPKContactField(field: $0 as! String)
        })
        
        paymentRequest.shippingMethods = Mappers.mapToShippingMethods(shippingMethods: shippingMethods)
        
        var paymentSummaryItems: [PKPaymentSummaryItem] = []
        
        if let items = summaryItems as? [[String : Any]] {
            for item in items {
                let label = item["label"] as? String ?? ""
                let amount = NSDecimalNumber(string: item["amount"] as? String ?? "")
                let type = Mappers.mapToPaymentSummaryItemType(type: item["type"] as? String)
                paymentSummaryItems.append(PKPaymentSummaryItem(label: label, amount: amount, type: type))
            }
        }
        
        paymentRequest.paymentSummaryItems = paymentSummaryItems
        if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: self) {
            DispatchQueue.main.async {
                applePayContext.presentApplePay(completion: nil)
            }
        } else {
            reject(ErrorType.Failed, "Payment not completed", nil)
        }
    }
   

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        confirmPaymentResolver?(Errors.createError(ErrorType.Canceled, "FPX Payment has been canceled"))
    }
}

func findViewControllerPresenter(from uiViewController: UIViewController) -> UIViewController {
    // Note: creating a UIViewController inside here results in a nil window
    // This is a bit of a hack: We traverse the view hierarchy looking for the most reasonable VC to present from.
    // A VC hosted within a SwiftUI cell, for example, doesn't have a parent, so we need to find the UIWindow.
    var presentingViewController: UIViewController =
        uiViewController.view.window?.rootViewController ?? uiViewController

    // Find the most-presented UIViewController
    while let presented = presentingViewController.presentedViewController {
        presentingViewController = presented
    }

    return presentingViewController
}
