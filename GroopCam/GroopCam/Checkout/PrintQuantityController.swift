import UIKit
import Stripe
import Firebase
import PassKit
import MessageUI

class PrintQuantityController: UICollectionViewController, UICollectionViewDelegateFlowLayout, ItemCellDelegate {
        
    var objects = [QuantityObject]()
                
    let cellId = "cellId"
    let checkoutView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.backgroundColor
        return view
    }()
    
    let filmLabel: UILabel = {
        let label = UILabel().setupLabel(ofSize: 15, weight: UIFont.Weight.medium, textColor: .white, text: "printed on 4 x 6’’ kodak/fujifilm prints", textAlignment: .center)
        label.sizeToFit()
        return label
     }()
    
    let minLabel: UILabel = {
        let label = UILabel().setupLabel(ofSize: 15, weight: UIFont.Weight.medium, textColor: .white, text: "minimum 5 photos", textAlignment: .center)
         label.sizeToFit()
         return label
     }()
    
    var totalLabel: UILabel = {
        let label = UILabel().setupLabel(ofSize: 20, weight: UIFont.Weight.medium, textColor: .white, text: "Total: $0.00", textAlignment: .center)
        label.sizeToFit()
        return label
     }()
    
    var total = 0
    var quantity = 0
    var price = 0.15
    
    let checkoutButton: UIButton = {
        let button = UIButton().setupButton(backgroundColor: Theme.buttonColor, title: "Checkout 💰", titleColor: .white, ofSize: 20, weight: UIFont.Weight.medium, cornerRadius: 15)
        button.addTarget(self, action: #selector(handleCheckout), for: .touchUpInside)
        button.alpha = 0.75
        button.isEnabled = false
        return button
    }()
    
    let discountField: UITextField = {
        let field = UITextField().setupTextField(backgroundColor: .white, ofSize: 17, weight: UIFont.Weight.medium, cornerRadius: 10, keyboardType: .default, textAlignment: .left, keyboardAppearance: .light, textColor: .black)
        
        field.attributedPlaceholder = NSAttributedString(string: "Enter discount code",
                                                         attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        field.setLeftPaddingPoints(5)
        
//        field.placeholder = "Enter a discount code"
        return field
    }()
    
    let applyButton: UIButton = {
        let button = UIButton().setupButton(backgroundColor: Theme.buttonColor, title: "Apply", titleColor: .white, ofSize: 17, weight: UIFont.Weight.medium, cornerRadius: 15)
        button.addTarget(self, action: #selector(handleApply), for: .touchUpInside)
        return button
    }()
    
    var hasDiscountCode = false

    var topbarHeight: CGFloat {
        if #available(iOS 13.0, *) {
            return (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0) +
                (self.navigationController?.navigationBar.frame.height ?? 0.0)
        } else {
            // Fallback on earlier versions
            return UIApplication.shared.statusBarFrame.size.height +
            (self.navigationController?.navigationBar.frame.height ?? 0.0)
        }
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        collectionView.register(ItemCell.self, forCellWithReuseIdentifier: cellId)

        layoutViews()
        
        
        for object in objects {
            self.total += object.quantity
            self.quantity += object.quantity
        }
        
    
        self.totalLabel.text = "Total: $" + String(format: "%.02f", Double(round(100*(Double(self.total))*self.price)/100))
        
//        Double(round(100*(Double(self.total)-Double(5))*self.price)/100)
        
        
//        checkoutButton.isHidden = !PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: SupportedPaymentNetworks)
        
    }
    
    @objc func handleApply() {
        
        guard let discountCode = self.discountField.text else { return }
        self.discountField.resignFirstResponder()
        if Auth.auth().currentUser != nil {
            self.showSpinner(onView: self.checkoutView)
            Database.database().reference().child("discounts").observeSingleEvent(of: .value, with: {(snapshot) in
                self.removeSpinner()
                self.discountField.text = ""
                guard let discountsDictionary = snapshot.value as? [String: Int] else {
                    self.presentAlert("Invalid Code!")
                    return
                }
                let discounts = Array(discountsDictionary.keys)
                for discount in discounts {
                    if discountCode == discount {
                        let discountValue = discountsDictionary[discount]!
                        if discountValue >= 5 {
                            self.updateDiscountValue(discount, discountValue - 5)
                            self.hasDiscountCode = true
                            self.totalLabel.text = "Total: $" +
                                String(format: "%.02f", Double(round(100*(Double(self.total)-Double(5))*self.price)/100))

                            self.presentAlert("Successfully applied discount code!")
                        } else {
                            self.removeDiscountCode(discountCode)
                            self.presentAlert("This code doesn't have enough amount of free photos!")
                        }
                        return
                    }
                }
                self.presentAlert("Invalid Code!")
            })
        }
    }
    
    func removeDiscountCode(_ discountCode: String) {
        Database.database().reference().child("discounts").child(discountCode).removeValue()
    }
    
    func updateDiscountValue(_ discountCode: String, _ amount: Int) {
        Database.database().reference().child("discounts").child(discountCode).setValue(amount)
    }
    
    func presentAlert(_ title: String){
        let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
              switch action.style{
              case .default:
                    print("default")

              case .cancel:
                    print("cancel")

              case .destructive:
                    print("destructive")

              @unknown default:
               fatalError()
           }}))
        self.present(alert, animated: true, completion: nil)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.view.frame.origin.y -= keyboardSize.height
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        self.view.frame.origin.y = topbarHeight
    }
    
    func didIncrease(for cell: ItemCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }

        let picture = self.objects[indexPath.item]

        picture.quantity += 1
        self.objects[indexPath.item] = picture

        UIView.performWithoutAnimation {
            self.collectionView.reloadItems(at: [indexPath])
        }
        
        print(picture.quantity, "please")

        
        self.total += 1
        
        if self.hasDiscountCode {
            let num = Double(round(100*(Double(self.total)-Double(5))*self.price)/100)
            self.totalLabel.text = "Total: $" + String(format: "%.02f", num)
        } else {
            let num = Double(round(100*(Double(self.total))*self.price)/100)
            self.totalLabel.text = "Total: $" + String(format: "%.02f", num)
        }
    }

    func didDecrease(for cell: ItemCell) {

        print("Message coming from PrintQuantityController")
//
        if self.total > 0 {
            
            guard let indexPath = collectionView?.indexPath(for: cell) else { return }
    //
            let picture = self.objects[indexPath.item]
    //
            if picture.quantity > 1 && (!self.hasDiscountCode || self.total-5 > 0) {
                picture.quantity -= 1
            }
            
            quantity = 0
            for object in objects {
                quantity += object.quantity
            }
    //
    //        self.objects[indexPath.item] = picture
    //
            UIView.performWithoutAnimation {
                self.collectionView.reloadItems(at: [indexPath])
            }
            
            total = quantity
            
            if self.hasDiscountCode {
                let num = Double(round(100*(Double(self.total)-Double(5))*self.price)/100)
                self.totalLabel.text = "Total: $" + String(format: "%.02f", num)
            } else {
                let num = Double(round(100*(Double(self.total))*self.price)/100)
                self.totalLabel.text = "Total: $" + String(format: "%.02f", num)
            }
            
        }
        
//
//        print(picture.quantity, "please")
//
//        if total > quantity && picture.quantity != 1 {
//            self.total -= 1
//            self.totalLabel.text = "Total: $" + String(self.total) + ".00"
//        }


    }
    
    let SupportedPaymentNetworks = [PKPaymentNetwork.visa, PKPaymentNetwork.masterCard, PKPaymentNetwork.amex]
    let ApplePaySwagMerchantID = "merchant.groopcam"
    var shiptot: NSDecimalNumber = 0.0
    
    @objc func handleCheckout(){
        
        checkoutButton.animateButtonDown()
        
        if total < 5 {
            self.presentFailedCheckout()
        }
        else{
            self.toggleCheckout()
        }
    }
    
    func toggleCheckout(){
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        var descFinal = ""

        for object in self.objects{
            let productquantity = String(object.quantity)
            let producturl = object.printableObject.post.imageUrl
            descFinal.append("(" + productquantity + " , " + producturl + "), ")
        }
    
        
        alert.addAction(UIAlertAction(title: "Manual Checkout", style: .default , handler:{ (UIAlertAction)in
            print("User clicked manual checkout")
            let settingsVC = SettingsViewController()
            let checkoutVC = CheckoutViewController(products: self.objects, settings: settingsVC.settings, totalPrice: self.totalLabel.text!, descFinal: descFinal)
            
            
            self.navigationController?.pushNavBarWithTitle(vc: checkoutVC)
            self.navigationItem.leftItemsSupplementBackButton = true
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        }))

        alert.addAction(UIAlertAction(title: "Apple Pay", style: .default , handler:{ (UIAlertAction)in
            print("User clicked Apple Pay")
            self.pressApplePay()
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction)in
            print("User click Dismiss button")
        }))


        self.present(alert, animated: true, completion: {
            print("completion block")
        })

        
        
        
//        if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: SupportedPaymentNetworks) {
//            self.pressApplePay()
//        } else {
//            let settingsVC = SettingsViewController()
//            let checkoutVC = CheckoutViewController(products: self.objects, settings: settingsVC.settings, hasDiscount: self.hasDiscountCode)
//            self.navigationController?.pushNavBarWithTitle(vc: checkoutVC)
//            self.navigationItem.leftItemsSupplementBackButton = true
//            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
//        }
    }
    
    func pressApplePay(){
        let tot = String(self.total) + ".00"

        shiptot = NSDecimalNumber(value: Double(self.total) + 1.50)
        
        var shippitot = Double(round(100*(Double(self.total))*self.price)/100)
    
        
        if self.hasDiscountCode {
            shippitot = Double(round(100*(Double(self.total)-Double(5))*self.price)/100)
        }
        

        let request = PKPaymentRequest()
        request.merchantIdentifier = ApplePaySwagMerchantID
        request.supportedNetworks = SupportedPaymentNetworks
        request.merchantCapabilities = PKMerchantCapability.capability3DS
        request.countryCode = "US"
        request.currencyCode = "USD"
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "GroopCam Photos", amount: NSDecimalNumber(value: shippitot)),
            PKPaymentSummaryItem(label: "Shipping", amount: NSDecimalNumber(value: 1.50)),
            PKPaymentSummaryItem(label: "GroopCam", amount: NSDecimalNumber(value: shippitot  + 1.50))
        ]

        var address = PKAddressField()
        address.insert(.postalAddress)
        address.insert(.email)
                    
        request.requiredShippingAddressFields = address
        
        var billingAddress = PKAddressField()
        address.insert(.postalAddress)
        address.insert(.email)
        
        request.requiredBillingAddressFields = address
        
        let applePayController = PKPaymentAuthorizationViewController(paymentRequest: request)
        applePayController?.delegate = self
        self.present(applePayController!, animated: true, completion: nil)

    }

    
    func presentFailedCheckout(){
         let alert = UIAlertController(title: "Please checkout 5 or more photos.", message: "", preferredStyle: .alert)
         alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
               switch action.style{
               case .default:
                     print("default")

               case .cancel:
                     print("cancel")

               case .destructive:
                     print("destructive")


         }}))
         self.present(alert, animated: true, completion: nil)

     }
    
    var alternate: Bool = false
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ItemCell
                        
        cell.cellQuantity = objects[indexPath.item]
        
        cell.delegate = self
                
                
        if objects.index(after: indexPath.item) % 2 == 0 {
            cell.backgroundColor = Theme.cellColor
        }
        else{
            cell.backgroundColor = Theme.backgroundColor
        }
        
        var total = 0
        for object in objects{
            total += object.quantity
        }
        
        if total >= 5 {
            self.checkoutButton.layoutIfNeeded()
            self.checkoutButton.fadeIn()
            self.checkoutButton.isEnabled = true
            
            self.applyButton.layoutIfNeeded()
            self.applyButton.fadeIn()
            self.applyButton.isEnabled = true
        }
        else{
                self.checkoutButton.layoutIfNeeded()
                self.checkoutButton.fadeOut()
                self.checkoutButton.isEnabled = false
            
                self.applyButton.layoutIfNeeded()
                self.applyButton.fadeOut()
                self.applyButton.isEnabled = false
        }
        
        let object = self.objects[indexPath.row]
        
        if object.isHorizontal {
            cell.showHorizontalImage()
            //print("Showing Horizontal Image")
        }
        else {
            cell.showVerticalImage()
           // print("Showing Vertical Image")
        }

        cell.photoImageView.image = object.image
        
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return objects.count
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.objects.removeAll()
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = view.frame.width
        return CGSize(width: width, height: width * 0.45)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
        
    func layoutViews(){
        
        collectionView.backgroundColor = Theme.backgroundColor
        
        collectionView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 270, paddingRight: 0, width: 0, height: 0)
                
        collectionView.alwaysBounceVertical = true
        
        self.navigationItem.title = "Print Quantity"

        view.addSubview(checkoutView)
        checkoutView.anchor(top: collectionView.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        checkoutView.addSubview(applyButton)
        applyButton.anchor(top: collectionView.bottomAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 15, paddingLeft: 0, paddingBottom: 0, paddingRight: 12, width: 80, height: 40)
        applyButton.layer.applySketchShadow(color: .black, alpha: 0.5, x: 0, y: 2, blur: 4, spread: 0)
        
        checkoutView.addSubview(discountField)
        discountField.anchor(top: collectionView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: applyButton.leftAnchor, paddingTop: 15, paddingLeft: 12, paddingBottom: 0, paddingRight: 12, width: 80, height: 40)
        discountField.delegate = self
//        discountField.becomeFirstResponder()
        
        checkoutView.addSubview(checkoutButton)
        checkoutButton.anchor(top: collectionView.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 160, paddingLeft: 12, paddingBottom: 43, paddingRight: 12, width: 0, height: 0)
        checkoutButton.layer.applySketchShadow(color: .black, alpha: 0.5, x: 0, y: 2, blur: 4, spread: 0)
        
        checkoutView.addSubview(filmLabel)
        filmLabel.anchor(top: collectionView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 73, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 18)
        
        checkoutView.addSubview(minLabel)
        minLabel.anchor(top: filmLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 4, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 18)
        
        checkoutView.addSubview(totalLabel)
        totalLabel.anchor(top: minLabel.bottomAnchor, left: minLabel.leftAnchor, bottom: nil, right: minLabel.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 24)
        
    }
     
    
    func createShippingAddressFromRef(address: ABRecord!) -> Address {
      var shippingAddress: Address = Address()
            
      shippingAddress.FirstName = ABRecordCopyValue(address, kABPersonFirstNameProperty)?.takeRetainedValue() as? String
      shippingAddress.LastName = ABRecordCopyValue(address, kABPersonLastNameProperty)?.takeRetainedValue() as? String
        
        let addressProperty : ABMultiValue = ABRecordCopyValue(address, kABPersonAddressProperty).takeUnretainedValue() as ABMultiValue
      if let dict : NSDictionary = ABMultiValueCopyValueAtIndex(addressProperty, 0).takeUnretainedValue() as? NSDictionary {
        shippingAddress.Street = dict[String(kABPersonAddressStreetKey)] as? String
        shippingAddress.City = dict[String(kABPersonAddressCityKey)] as? String
        shippingAddress.State = dict[String(kABPersonAddressStateKey)] as? String
        shippingAddress.Zip = dict[String(kABPersonAddressZIPKey)] as? String
        
      }
            
      return shippingAddress
    }

}

extension PrintQuantityController: PKPaymentAuthorizationViewControllerDelegate {
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {

        // 1
        print(123)
        let shippingAddress = self.createShippingAddressFromRef(address: payment.shippingAddress)
        
        
        
        // 2
//        Stripe.setDefaultPublishableKey("pk_test_pUrttWCwYjM0Ge3VzWJhT9v800pwbF49Ik")  // Replace With Your Own Key!
        
         Stripe.setDefaultPublishableKey("pk_live_b1pjET7QOxe5hVHCABXX5oZx00k8hUVqEo")  // Replace With Your Own Key!
        
//        pk_live_b1pjET7QOxe5hVHCABXX5oZx00k8hUVqEo
    
        print(256)
    
        // 3
        
        STPAPIClient.shared().createToken(with: payment) {
          (token, error) -> Void in
    
          if (error != nil) {
            print(error)
//            completion(PKPaymentAuthorizationStatus.failure)
            completion(PKPaymentAuthorizationResult(status: PKPaymentAuthorizationStatus.failure, errors: []))
            return
          }
    
          // 4
            let shippingAddress = self.createShippingAddressFromRef(address: payment.shippingAddress)
            
            let billingAddress = self.createShippingAddressFromRef(address: payment.billingAddress)
            

                
            print(billingAddress, 256)
        
            let emailAddress = payment.shippingContact?.emailAddress!
            
          // 5
          let url = NSURL(string: "https://groopcamstripe2.herokuapp.com/pay")
//          let url = NSURL(string: "http://127.0.0.1:5000/pay")  // Replace with computers local IP Address!
          let request = NSMutableURLRequest(url: url! as URL)
          request.httpMethod = "POST"
          request.setValue("application/json", forHTTPHeaderField: "Content-Type")
          request.setValue("application/json", forHTTPHeaderField: "Accept")
            
          // 6
            var tot = 0.0
            var rand = 0.0
            
            if self.hasDiscountCode{
                rand = Double(round(100*(Double(self.total)-Double(5))*self.price)/100)
                
                rand = (Double(self.total)-Double(5))*self.price


//                tot = rand * 100
                
                tot = Double(rand * 100)
            }
            else{
                rand = Double(self.total)*self.price
                
//                Double(round(100*(Double(self.total)-Double(5))*self.price)/100)

                tot = Double(rand * 100)
            }
            
            let shipping_tot = 150
            
            var intTot = Int(tot)
            let final_tot = intTot + shipping_tot
        
            
            
            var desc = ""
            for object in self.objects{
                let st = "(" + String(object.quantity) + " , " + object.printableObject.post.imageUrl + "), "
                desc.append(st)
            }
            
        
                        
            let final_name = shippingAddress.FirstName! + " " + shippingAddress.LastName!
            
            let shipping = [
                "name": final_name,
                "address": [
                    "line1": shippingAddress.Street!,
                    "city": shippingAddress.City!,
                    "country": "US",
                    "postal_code": shippingAddress.Zip],
            ] as [String : Any]
            
            let body = [
                        "stripeToken": token!.tokenId,
                        "amount": final_tot,
                        "description": emailAddress! + " " + desc,
                        "email": emailAddress!,
                        "shippingActual": shipping
                ] as [String : Any]
    
            print(body, 123)
            
          var error: NSError?
    //        request.HTTPBody = JSONSerialization.dataWithJSONObject(body, options: JSONSerialization.WritingOptions(), error: &error)
    
    //        request.httpBody = JSONSerialization.datawith
    
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: JSONSerialization.WritingOptions())
                
                print(256)
            }
            catch{
                print("Caught error:", error)
            }
    
          // 7
            NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: OperationQueue.main) { (response, data, error) -> Void in
            if (error != nil) {
//                completion(PKPaymentAuthorizationStatus.failure)
                completion(PKPaymentAuthorizationResult(status: PKPaymentAuthorizationStatus.failure, errors: []))
            } else {
//                completion(PKPaymentAuthorizationStatus.success)
                completion(PKPaymentAuthorizationResult(status: PKPaymentAuthorizationStatus.success, errors: []))
                self.navigationController?.popToRootViewController(animated: true)
            }
          }
        }
    }
  
  func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController!) {
    controller.dismiss(animated: true, completion: nil)
  }
    
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController!, didSelectShippingAddress address: ABRecord!, completion: ((PKPaymentAuthorizationStatus, [AnyObject]?, [AnyObject]?) -> Void)!) {
        let shippingAddress = createShippingAddressFromRef(address: address)

        switch (shippingAddress.State, shippingAddress.City, shippingAddress.Zip) {
        case (.some(let state), .some(let city), .some(let zip)):
            completion(PKPaymentAuthorizationStatus.success, nil, nil)
          default:
            completion(PKPaymentAuthorizationStatus.invalidShippingPostalAddress, nil, nil)
        }
    }
}

struct Address {
  var Street: String?
  var City: String?
  var State: String?
  var Zip: String?
  var FirstName: String?
  var LastName: String?
  var Email: String?

  init() {
  }
}

extension PrintQuantityController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }

}

