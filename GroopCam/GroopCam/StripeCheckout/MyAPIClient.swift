

import Foundation
import Stripe

class MyAPIClient: NSObject, STPCustomerEphemeralKeyProvider {
    
    enum APIError: Error {
        case unknown
        
        var localizedDescription: String {
            switch self {
            case .unknown:
                return "Unknown error"
            }
        }
    }

    static let sharedClient = MyAPIClient()
    var baseURLString: String? = nil
    var baseURL: URL {
        if let urlString = self.baseURLString, let url = URL(string: urlString) {
            return url
        } else {
            fatalError()
        }
    }
    
        
    func createShippingAddressFromRef(address: STPAddress!) -> Address {
        var shippingAddress: Address = Address()
        
        shippingAddress.FirstName = address.pkContactValue().name?.givenName
        shippingAddress.LastName = address.pkContactValue().name?.familyName
        
        shippingAddress.Street = address.line1
        shippingAddress.City = address.city
        shippingAddress.State = address.state
        shippingAddress.Zip = address.postalCode
    
        return shippingAddress
    }
    
    private func sendToJSON(products: [QuantityObject], shippingMethod: PKShippingMethod?, shippingAddress: STPAddress?, amount: Int, paymentResult: STPPaymentResult){
//
        let shipp = self.createShippingAddressFromRef(address: shippingAddress)
//
        Stripe.setDefaultPublishableKey("pk_live_b1pjET7QOxe5hVHCABXX5oZx00k8hUVqEo")  // Replace With Your Own Key!
        guard let tokenId = paymentResult.paymentMethod?.stripeId else {return}
        
        guard let paymentMethod = paymentResult.paymentMethod else {return}
        var paymentStripeId: String?
        if let source = paymentMethod as? STPSource {
            paymentStripeId = source.stripeID
        }else if let card = paymentMethod as? STPCard {
            paymentStripeId = card.stripeID
        }
                
        
    
//
        let emailAddress = shippingAddress?.email
//
        let url = NSURL(string: "https://groopcamstripe2.herokuapp.com/payManual")
//        let url = NSURL(string: "http://127.0.0.1:5000/pay")
        
//
        let request = NSMutableURLRequest(url: url! as URL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        var desc = ""
        for object in products{
            let st = "(" + String(object.quantity) + " , " + object.printableObject.post.imageUrl + "), "
            desc.append(st)
        }
//
        let final_name = shipp.FirstName! + " " + shipp.LastName!

        let shipping = [
            "name": final_name,
            "address": [
                "line1": shipp.Street!,
                "city": shipp.City!,
                "country": "US",
                "postal_code": shipp.Zip],
        ] as [String : Any]
//
        let body = [
                    "stripeToken": tokenId,
                    "amount": amount,
                    "description": emailAddress! + " " + desc,
                    "email": emailAddress!,
                    "shippingActual": shipping
            ] as [String : Any]
//
            print(body, 123)
//
        var error: NSError?
//
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: JSONSerialization.WritingOptions())

            print(256)
        }
        catch{
            print("Caught error:", error)
        }
//
//          // 7
        NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: OperationQueue.main) { (response, data, error) -> Void in
        if (error != nil) {
//                completion(PKPaymentAuthorizationStatus.failure)
            print("There", 12222)

        } else {
//                completion(PKPaymentAuthorizationStatus.success)
            print("Success", 12222)
        }
        }
    }
    
    func createDictFromProducts(products: [QuantityObject]) -> [String: String]{
        
        var dict = ["payment_request_id": UUID().uuidString]
        
        var i = 0
        for product in products{
            
            var key = String(i)
            
            let post = product.printableObject.post.imageUrl
            dict[key] = String(product.quantity) + " " + post
            
            i += 1
        }
        
        return dict
    }
    
    func createShipping(shippingAddress: STPAddress?) -> String{
        shippingAddress
        
        var line = shippingAddress?.line1 ?? ""
        var city = shippingAddress?.city ?? ""
        var state = shippingAddress?.state ?? ""
        var postalcode = shippingAddress?.postalCode ?? ""
        var name = shippingAddress?.name ?? ""
        var emailAddress = shippingAddress?.email ?? ""
        var phone = shippingAddress?.phone ?? ""
            
        
        var str = ""
        str.append(line)
        str.append(", ")
        str.append(city)
        str.append(", ")
        str.append(state)
        str.append(", ")
        str.append(postalcode)
        str.append(", ")
        str.append(name)
        str.append(", ")
        str.append(emailAddress)
        str.append(", ")
        str.append(phone)
                
        return str
    }
    
    func createPaymentIntent(products: [QuantityObject], shippingMethod: PKShippingMethod?, shippingAddress: STPAddress?, amount: Int, paymentResult: STPPaymentResult, descFinal: String, completion: @escaping ((Result<String, Error>) -> Void)) {
        
        
//        sendToJSON(products: products, shippingMethod: shippingMethod, shippingAddress: shippingAddress, amount: amount, paymentResult: paymentResult)
        
        guard let tokenId = paymentResult.paymentMethod?.stripeId else {return}
        
        guard let paymentMethod = paymentResult.paymentMethod else {return}
        var paymentStripeId: String?
        if let source = paymentMethod as? STPSource {
            paymentStripeId = source.stripeID
        }else if let card = paymentMethod as? STPCard {
            paymentStripeId = card.stripeID
        }
        
        
                
//        let url = self.baseURL.appendingPathComponent("create_payment_intent")
        let urlString = "https://groopcamstripe2.herokuapp.com/create_payment_intent"
        let url = URL(string: urlString)

        guard let shipping = shippingAddress else {return}

//        guard let billingAd = country else {return}
//        guard let billing = billingAd.prefilledInformation else {return}
        let metadata = createDictFromProducts(products: products)
        
        
        
        print(metadata, 12222)
        
        paymentMethod.customerId
        
        let shippin = createShipping(shippingAddress: shippingAddress)
        
        let shippingJSON = [
            "name": shipping.name ?? "",
            "address": [
                "line1": shipping.line1 ?? "",
                "city": shipping.city ?? "",
                "country": "US",
                "postal_code": shipping.postalCode ?? ""],
        ] as [String : Any]
        

        var params: [String: Any] = [
            "amount": amount,
            "description": shippin,
            "metadata": metadata,
            "shipping": shippingJSON,
            "email": shippingAddress?.email,
            "customerId": paymentMethod.customerId
        ]
        
//        params["products"] = products.map({ (p) -> String in
//            return p.printableObject.post.imageUrl
//        })
        


        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        
        
        var request = URLRequest(url: url as! URL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                let data = data,
                let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]) as [String : Any]??),
                let secret = json?["secret"] as? String else {
                    completion(.failure(error ?? APIError.unknown))
                    return
            }
            completion(.success(secret.replacingOccurrences(of: "\"", with: "")))
        })
        task.resume()
    }
//
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        let url = self.baseURL.appendingPathComponent("ephemeral_keys")

        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [URLQueryItem(name: "api_version", value: apiVersion)]
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                let data = data,
                let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]) as [String : Any]??) else {
                completion(nil, error)
                return
            }
            completion(json, nil)
        })
        task.resume()
    }

}
