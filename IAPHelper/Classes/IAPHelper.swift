//
//  IAPHelper.swift
//  VX Player
//
//  Created by Vikas Goyal on 21/03/17.
//  Copyright © 2017 Grand Hit Software. All rights reserved.
//

import UIKit
import SwiftyStoreKit
import StoreKit
import PopupDialog


public enum IAPButton{
    case buy
    case cancel
    case restore
}

public protocol IAPDelegate:class {
    func IAPButtonClicked(buttonType:IAPButton);
    func IAPPurchaseResult(identifier:String,state:String,attributes:NSDictionary?);
}

public class IAPHelper: NSObject {
    private static let instance = IAPHelper();
    weak var listener:IAPDelegate?;
    
    public class func isPurchased(identifier:String)->Bool{
        let state = UserDefaults.getState(identifier: identifier)
        return state == SKPaymentTransactionState.purchased || state == SKPaymentTransactionState.restored
    }
    
    public class func startPurchage(title:String,message:String,identifier:String,viewcontroller:UIViewController,callBack:@escaping ((Void)->Void)){
        let restoreButton = DefaultButton(title: "RESTORE PURCHASE") {
            if let listener = instance.listener{
                listener.IAPButtonClicked(buttonType: IAPButton.restore);
            }
            restore(callBack: { (result) in
                if isPurchased(identifier: identifier){
                    let cancle = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
                    showAlert(title: "Restore Purchase Successful", message: "Your purchase have been restored.", actions: [cancle], viewcontroller:viewcontroller)
                    callBack();
                    return;
                }
                var message = "Item not avaliable to restore at this time.";
                if result.restoreFailedProducts.count > 0 {
                    message = result.restoreFailedProducts[0].0.localizedDescription;
                }
                let cancle = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
                showAlert(title: "Restore Purchase Failed", message: message, actions: [cancle], viewcontroller:viewcontroller)
            })
        }
        let buyButton = DefaultButton(title: "BUY") {
            if let listener = instance.listener{
                listener.IAPButtonClicked(buttonType: IAPButton.buy);
            }
            purchase(identifier: identifier) { (message, error,product) in
                trackEvent(identifier: identifier,pro: product,errorSk: error)
                if let product = product{
                    UserDefaults.setPayment(identifier: product.productId, state: product.transaction.transactionState);
                    callBack();
                    return;
                }
                if let message = message{
                    let cancle = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
                    showAlert(title: "Purchase Failed", message: message, actions: [cancle], viewcontroller:viewcontroller)
                    return;
                }
                if error != nil{
                    let cancle = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
                    showAlert(title: "Restore Purchases Failed", message: "An error occurred while handling your purchase. Please try again later", actions: [cancle], viewcontroller:viewcontroller)
                }
                return;
            };
        };
        
        // Create the dialog
        let popup = PopupDialog(title: title, message: message, image: nil)
        let cancel = CancelButton(title: "CANCEL") {
            if let listener = instance.listener{
                listener.IAPButtonClicked(buttonType: IAPButton.cancel);
            }
        }
        
        popup.addButtons([restoreButton, buyButton, cancel])
        viewcontroller.present(popup, animated: true, completion: nil)
    }
    
    class func trackEvent(identifier:String,pro:Product?,errorSk:SKError?){
        guard let listener = instance.listener else {
            return;
        }
        
        var attribute: NSMutableDictionary?
        if let errorSk = errorSk{
            attribute = NSMutableDictionary()
            attribute?.addEntries(from: errorSk.userInfo);
            var codeStr = "Not Set";
            switch errorSk.code {
            case .unknown:
                codeStr = "Unknown Error"
            case .clientInvalid:
                codeStr = "Client Invalid"
            case .paymentCancelled:
                codeStr = "Payment Cancelled"
            case .paymentInvalid:
                codeStr = "Payment Invalid"
            case .paymentNotAllowed:
                codeStr = "Payment Not Allowed"
            case .storeProductNotAvailable:
                codeStr = "Store Product Not Available"
            case .cloudServicePermissionDenied:
                codeStr = "cloud Service Permission Denied"
            case .cloudServiceNetworkConnectionFailed:
                codeStr = "Cloud Service Network Connection Failed"
            }
            attribute?["My Error"] = codeStr;
            return;
        }
        if let pro = pro{
            listener.IAPPurchaseResult(identifier: identifier, state:  toString(state: pro.transaction.transactionState), attributes: attribute);
        }else if(errorSk == nil){
            listener.IAPPurchaseResult(identifier: identifier, state: toString(state: nil), attributes: ["My Error":"Payment Cancelled"]);
        }else{
            listener.IAPPurchaseResult(identifier: identifier, state: toString(state: nil), attributes:attribute);
        }
    }
    
    private class func toString(state:SKPaymentTransactionState?)-> String {
        guard let state = state else {
            return "failed"
        }
        switch state {
        case .purchasing:
            return "purchasing" // Transaction is being added to the server queue.
        case .purchased:
            return "purchased" // Transaction is in queue, user has been charged.  Client should complete the transaction.
        case .failed:
            return "failed" // Transaction was cancelled or failed before being added to the server queue.
        case .restored:
            return "restored" // Transaction was restored from user's purchase history.  Client should complete the transaction.
        case .deferred:
            return "deferred" // The transaction is in the queue, but its final status is pending external action.
        }
    }
    
    private class  func showAlert(title: String, message: String,actions:[UIAlertAction],viewcontroller:UIViewController){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        for action in actions{
            alert.addAction(action)
        }
        viewcontroller.present(alert, animated: true, completion: nil)
    }
    
    public class func initiate(listener:IAPDelegate? = nil){
        instance.listener = listener
        SwiftyStoreKit.completeTransactions(atomically: true) { products in
            for product in products {
                if product.transaction.transactionState == .purchased || product.transaction.transactionState == .restored {
                    if product.needsFinishTransaction {
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(product.transaction)
                    }
                    print("purchased: \(product)")
                }
            }
        }
        restore { (results) in
            if results.restoreFailedProducts.count > 0 {
                print("Restore Failed: \(results.restoreFailedProducts)")
            }
            else if results.restoredProducts.count > 0 {
                print("Restore Success: \(results.restoredProducts)")
            }
            else {
                print("Nothing to Restore")
            }
        };
    }
    
    public class func restore(callBack:@escaping (RestoreResults)->Void){
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            let products = results.restoredProducts;
            var rs = [String:Int]()
            for product in products{
                rs[product.productId] = product.transaction.transactionState.rawValue
            }
            UserDefaults.setPayments(values: rs);
            callBack(results);
        }
    }
    
    public class func retriveInfo(identifier:String,callBack:@escaping ((SKProduct?,Error?)->Void)){
        SwiftyStoreKit.retrieveProductsInfo([identifier]) { result in
            if let product = result.retrievedProducts.first {
                callBack(product,nil)
                let priceString = product.localizedPrice!
                print("Product: \(product.localizedDescription), price: \(priceString)")
            }
            else if result.invalidProductIDs.first != nil {
                callBack(nil,NSError(domain: "com.ghs.iap", code: 404, userInfo: [NSLocalizedDescriptionKey : "Could not retrieve product info.Invalid product identifier."]));
            }
            else {
                callBack(nil,result.error)
            }
        }
    }
    
    class func purchase(identifier:String,callBack:@escaping ((_ errorMsg:String?,_ error:SKError?,_ product:Product?)->Void)){
        SwiftyStoreKit.purchaseProduct(identifier, atomically: true) { result in
            switch result {
            case .success(let product):
                print("Purchase Success: \(product.productId)")
                if product.transaction.transactionState == SKPaymentTransactionState.restored{
                    callBack("Purchase Restored Successful",nil,product);
                    return;
                }
                callBack("Purchase Successful",nil,product);
            case .error(let error):
                print("IAPHELPER ERROR::: \(error)")
                switch error.code {
                case .unknown: print("Unknown error. Please contact support")
                callBack(error.localizedDescription,error,nil);
                case .clientInvalid: print("Not allowed to make the payment")
                callBack("Not allowed to make the payment",error,nil);
                case .paymentCancelled:
                    callBack(nil,nil,nil);
                case .paymentInvalid: print("The purchase identifier was invalid")
                callBack("The purchase identifier was invalid",error,nil);
                case .paymentNotAllowed: print("The device is not allowed to make the payment")
                callBack("The device is not allowed to make the payment",error,nil);
                case .storeProductNotAvailable: print("The product is not available in the current storefront")
                callBack("The product is not available in the current storefront",error,nil);
                case .cloudServicePermissionDenied: print("Access to cloud service information is not allowed")
                callBack("Access to cloud service information is not allowed",error,nil);
                case .cloudServiceNetworkConnectionFailed: print("Could not connect to the network")
                callBack("Could not connect to the network",error,nil);
                }
            }
        }
    }
}


extension UserDefaults{
    static let iap_key = "\(Bundle.main.bundleIdentifier).iap"
    
    static func setPayments(values:[String:Int]){
        let ud = UserDefaults.standard;
        ud.set(values, forKey: iap_key)
        ud.synchronize()
    }
    
    static func setPayment(identifier:String,state:SKPaymentTransactionState){
        let ud = UserDefaults.standard;
        var paymentDictonary = [String:Int]()
        if let allPayments = ud.value(forKey: iap_key) as? [String:Int]{
            paymentDictonary = allPayments;
        }
        paymentDictonary[identifier] = state.rawValue;
        ud.set(paymentDictonary, forKey: iap_key)
        ud.synchronize()
    }
    
    static func getState(identifier:String)->SKPaymentTransactionState{
        let ud = UserDefaults.standard;
        if let allPayments = ud.value(forKey: iap_key) as? [String:Int]{
            if let value = allPayments[identifier],let state = SKPaymentTransactionState(rawValue: value){
                return state
            }
        }
        return SKPaymentTransactionState.failed
    }
}

