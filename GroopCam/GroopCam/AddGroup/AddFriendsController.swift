//
//  AddFriendsController.swift
//  GroopCam
//
//  Created by Niranjan Senthilkumar on 1/6/20.
//  Copyright © 2020 NJ. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth
import Contacts

class AddFriendsController: UITableViewController, UISearchResultsUpdating {
    
    var groupName: String = ""
        
    let cellIdentifier: String = "tableCell"
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            layoutViews()
        } else {
            // Fallback on earlier versions
        }
        
        fetchContacts()
        
        self.tableView.reloadData()
    }
    
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (self.contactsToDisplay.count == 0) {
            self.tableView.setEmptyMessage("No friends using GroopCam yet! 🤔")
        } else {
            self.tableView.restore()
        }
    
        if isFiltering {
            return self.filteredContacts.count
        }
        else{
            return self.contactsToDisplay.count
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.contactsToDisplay[indexPath.row].hasSelected = true
        
//        print(self.contactsToDisplay[indexPath.row])
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        self.contactsToDisplay[indexPath.row].hasSelected = false
        
//        print(self.contactsToDisplay[indexPath.row])

    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CustomTableCell
        
        let contact = contactsToDisplay[indexPath.row]
        
        cell.label.text = contact.firstname + " " + contact.lastname
        cell.usernameLabel.text = "@" + contact.username
        cell.selectionStyle = .none
        
        return cell
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        // do some stuff
        filteredContacts = contactsToDisplay.filter { (contact: ContactToDisplay) -> Bool in
            return contact.username.lowercased().contains(find: searchText.lowercased())
        }
        
        tableView.reloadData()
    }
    
    var isFiltering: Bool {
      return searchController.isActive && !isSearchBarEmpty
    }
    
    var isSearchBarEmpty: Bool {
      return searchController.searchBar.text?.isEmpty ?? true
    }
    
    var filteredContacts: [ContactToDisplay] = []

    var favoritableContacts = [FavoritableContact]()
    var contactsToDisplay = [ContactToDisplay]()
    var fullContactsToDisplay = [ContactToDisplay]()
    
    func sortAlphabeticalContacts(contact: ContactToDisplay) {
        var index = 0
        while index != self.contactsToDisplay.count && contact.username.lowercased() > self.contactsToDisplay[index].username.lowercased() {
                      index+=1
        }
        self.contactsToDisplay.insert(contact, at: index)
    }
    
    func sortAlphabeticalFullContacts(contact: ContactToDisplay) {
        var index = 0
        while index != self.fullContactsToDisplay.count && contact.username.lowercased() > self.fullContactsToDisplay[index].username.lowercased() {
                      index+=1
        }
        self.fullContactsToDisplay.insert(contact, at: index)
    }
    
    /* Testing sort
       private func testSort() {
           let fav1 = FavoritableContact(firstname: "Barty", lastname: "Crouch", phonenumber: "+13025561234", hasSelected: false)
             
           let fav2 = FavoritableContact(firstname: "Aania", lastname: "Safar", phonenumber: "+13025561156", hasSelected: false)
             
           let c1 = ContactToDisplay(firstname: "Barty", lastname: "Crouch", phonenumber: "+13025561234", hasSelected: false, uid: "1", username: "123Barty")
             
           let c2 = ContactToDisplay(firstname: "Aania", lastname: "Safar", phonenumber: "+13025561234", hasSelected: false, uid: "2", username: "aania")
           
           self.favoritableContacts.append(fav1)
           self.favoritableContacts.append(fav2)
                      
           self.sortAlphabeticalContacts(contact: c1)
           self.sortAlphabeticalContacts(contact: c2)
                      
           self.sortAlphabeticalFullContacts(contact: c1)
           self.sortAlphabeticalFullContacts(contact: c2)
           
       }
    */
    
    private func fetchContacts(){
        print("Attempting to fetch contacts today")
            
        let store = CNContactStore()
            
        store.requestAccess(for: .contacts) { (granted, err) in
            if let err = err {
                print("Failed to request access:", err)
                return
            }
                
            if granted {
                print("Access granted")
                    
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
                let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
                    
                do{
                        
//                    var favoritableContacts = [FavoritableContact]()
                        
                    try store.enumerateContacts(with: request) { (contact, stopPointerIfYouWantToStopEnumerating) in
                            
//                        print(contact.givenName + " " + contact.familyName)
                            
                        var ogphoneNumber = contact.phoneNumbers.first?.value.stringValue ?? ""
                            
                        var phoneNumber = ogphoneNumber.components(separatedBy:CharacterSet.decimalDigits.inverted).joined()
                                                    
                        if phoneNumber.count == 10 {
//                            print("+1" + phoneNumber)
                            phoneNumber = "+1" + phoneNumber
                        }
                        else if phoneNumber.count == 11 {
//                            print("+" + phoneNumber)
                            phoneNumber = "+" + phoneNumber
                        }
                        else{
                            phoneNumber = "+" + phoneNumber
                        }
                            
                        let favContact = FavoritableContact(firstname: contact.givenName, lastname: contact.familyName, phonenumber: phoneNumber, hasSelected: false)
                        self.favoritableContacts.append(favContact)
                    }
                        

                } catch let err{
                    print("Failed to enumerate contacts:", err)
                }
                    
            } else {
                print("Access denied...")
            }
                
            print(self.favoritableContacts.count, "please")
                        
            for contact in self.favoritableContacts {
                Database.database().reference().child("contacts").observeSingleEvent(of: .value) { (snapshot) in
                    if snapshot.hasChild(contact.phonenumber){
                        print("phonenumber exists")
                            
                        Database.database().reference().child("contacts").child(contact.phonenumber).observeSingleEvent(of: .value) { (snapshot) in
                            if let value = snapshot.value as? [String: Any] {
                                guard let uid = value["uid"] else {return}
                                guard let username = value["username"] else {return}
                                
//                                print(uid, "please")
//                                print(username, "please")
                                let uidToAdd = uid as? String ?? ""
                                let usernameToAdd = username as? String ?? ""
                                //dont add current user
                                if uidToAdd != Auth.auth().currentUser?.uid {
                                    let contact = ContactToDisplay(firstname: contact.firstname, lastname: contact.lastname, phonenumber: contact.phonenumber, hasSelected: false, uid: uidToAdd, username: usernameToAdd)
                                    
                                    //self.contactsToDisplay.append(contact)
                                    self.sortAlphabeticalContacts(contact: contact)
                                    self.tableView.reloadData()
                                }
                                //fullcontacts
                                let contact = ContactToDisplay(firstname: contact.firstname, lastname: contact.lastname, phonenumber: contact.phonenumber, hasSelected: false, uid: uidToAdd, username: usernameToAdd)
                                self.sortAlphabeticalFullContacts(contact: contact)
                                
                            }
                        }
                            
                    }
                }
            }
        }
            
    }
    
    static let updateFeedNotificationName = NSNotification.Name(rawValue: "UpdateFeed")
    
    @objc func handleCreateGroup(){
        
        let groupName = self.groupName
        let timeAgo = String(Date().timeIntervalSince1970)
        
        let groupId = NSUUID().uuidString

        let dictionaryValues = ["groupname": groupName, "timestamp": timeAgo, "lastPicture": timeAgo]

        let values = [groupId: dictionaryValues]
        

    Database.database().reference().child("groups").updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to save group info into db:", err)
                return
            }

            print("Successfully saved group info to db")

        }
        
        //implement more than current users after
        let currentUser = Auth.auth().currentUser
        
        var members = [currentUser?.uid: true]
        
        for contact in self.contactsToDisplay {
            if contact.hasSelected == true {
                members[contact.uid] = true
            }
        }
        
        
        
        print(members.count, "please")
        
        let groupMembers = [groupId: members]
        Database.database().reference().child("members").updateChildValues(groupMembers) { (err, ref) in
                if let err = err {
                    print("Failed to save group members into db:", err)
                    return
                }

                print("Successfully saved group members to db")

        }
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let username = UserDefaults.standard.string(forKey: "username") else {return}
       
        var uidsToUpdate = [uid]
        for contact in self.contactsToDisplay {
            if contact.hasSelected == true{
                uidsToUpdate.append(contact.uid)
            }
        }
        
        
        let userGroups = [groupId: true]
       
        for currentuid in uidsToUpdate {
            Database.database().reference().child("users").child(currentuid).child("groups").updateChildValues(userGroups) { (err, ref) in
                if let err = err {
                    print("Failed to append group to user", err)
                }
                else{
                    print("Successfully appended group to user")
                }
            }
            if currentuid != uid {
                Database.database().reference().child("users").child(currentuid).child("token").observeSingleEvent(of: .value) {(snapshot) in
                    if let value = snapshot.value as? String {
                        let sender = PushNotificationSender()
                        if uidsToUpdate.count == 2 {
                            sender.sendPushNotification(to: value, body: "@\(username) added you to album \"\(self.groupName)\".")
                        } else {
                            sender.sendPushNotification(to: value, body: "@\(username) added you to album \"\(self.groupName)\" with \(uidsToUpdate.count - 2) others.")
                        }
                        
                    }
                }
            }
        }
        
        self.navigationController?.popToRootViewController(animated: true)
        NotificationCenter.default.post(name: AddFriendsController.updateFeedNotificationName, object: nil)

    }

    func layoutViews(){
        setupNavBar()
        setupTableView()
        setupSearchBar()
    }
    
    fileprivate func setupNavBar(){
        self.navigationItem.title = "Add Friends"
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "creategroup")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleCreateGroup))
    }
    
    
    fileprivate func setupTableView(){
        
        self.tableView.backgroundView?.backgroundColor = Theme.backgroundColor
        self.tableView.tableHeaderView = searchController.searchBar
        tableView.register(CustomTableCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.allowsMultipleSelection = true
        tableView.backgroundColor = Theme.backgroundColor
        self.tableView.backgroundView = UIView()
        tableView.tableFooterView = UIView()
    }
    
    fileprivate func setupSearchBar(){

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true
        self.searchController.searchBar.isTranslucent = false
        self.searchController.searchBar.backgroundImage = UIImage()
        self.searchController.searchBar.barTintColor = Theme.backgroundColor
        self.searchController.searchBar.tintColor = UIColor.white
                
        searchController.searchBar.barTintColor = Theme.backgroundColor
        if #available(iOS 13.0, *) {
            searchController.searchBar.searchTextField.backgroundColor = Theme.whiteopacity
            searchController.searchBar.searchTextField.placeholder = "Search by username"
            searchController.searchBar.searchTextField.textColor = Theme.lgColor
        }

        if let textFieldInsideSearchBar = searchController.searchBar.value(forKey: "searchField") as? UITextField,
            let glassIconView = textFieldInsideSearchBar.leftView as? UIImageView {
                //Magnifying glass
                glassIconView.image = glassIconView.image?.withRenderingMode(.alwaysTemplate)
            glassIconView.tintColor = Theme.lgColor
        }
        
        searchController.searchBar.tintColor = .black
    }
    
}
