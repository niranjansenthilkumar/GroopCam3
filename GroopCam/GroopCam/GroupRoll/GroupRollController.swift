//
//  GroupRollController.swift
//  GroopCam
//
//  Created by Niranjan Senthilkumar on 1/7/20.
//  Copyright © 2020 NJ. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Kingfisher
import BSImagePicker
import Photos
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
struct Image {
    let image: UIImage
    let isHorizontal: Bool
}

class GroupRollController: UICollectionViewController {
    
    var username: String = ""
    var group: Group?
    var groupCount: Int = 0

    var objects : [PrintableObject] = []
    
    var isSelected: Bool = false

    let cellId = "cellId"
    
    let printButton: UIButton = {
        let button = UIButton().setupButton(backgroundColor: Theme.buttonColor, title: "Print photos 🏞", titleColor: .white, ofSize: 18, weight: UIFont.Weight.medium, cornerRadius: 15)
        button.addTarget(self, action: #selector(handlePrintPhotos), for: .touchUpInside)
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.alpha = 1.0
        button.isEnabled = true
        
        return button
    }()
    
    let actualPrintButton: UIButton = {
        let button = UIButton().setupButton(backgroundColor: Theme.buttonColor, title: "Print photos 🏞", titleColor: .white, ofSize: 18, weight: UIFont.Weight.medium, cornerRadius: 15)
        button.addTarget(self, action: #selector(handleActualPrintPhotos), for: .touchUpInside)
        button.isEnabled = false
        button.alpha = 1.0
        return button
    }()
    
    let friendButton: UIButton = {
        let button = UIButton().setupButton(backgroundColor: Theme.buttonColor, title: "1 friend 👥", titleColor: .white, ofSize: 20, weight: UIFont.Weight.medium, cornerRadius: 15)
        button.addTarget(self, action: #selector(handleFriends), for: .touchUpInside)
        return button
    }()
    
    let viewProgress: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
        
    }()
    
    let dimView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        return view
        
    }()

    
    let progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progress = 0.0
        //progressView.progressTintColor = .white
        return progressView
    }()
    
    let progressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .white
        label.text = "Uploading...."
        return label
    }()
    
    var progress = Progress()
    var activityIndicator: UIActivityIndicatorView?
    var arrImages = [Image]()
    var assetCount = 0
    var initialPostsCount = 0
    typealias FileCompletionBlock = () -> Void
    var block: FileCompletionBlock?
        
    override func viewDidLoad() {
        super.viewDidLoad()
                
        collectionView.register(GroupRollCell.self, forCellWithReuseIdentifier: cellId)
        layoutViews()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateFeed), name: CameraController.updateGroopFeedNotificationName, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateFeed), name: PictureController.updatePictureNotificationName, object: nil)
        
           NotificationCenter.default.addObserver(self, selector: #selector(updateGroupNameFunc(notification:)), name: EditGroupController.updateGroupName, object: nil)
        
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        
        guard let groupId = self.group?.groupid else {return}

        //fetchPostsWithGroupID(groupID: groupId)

        checkIfNoPosts(forGroup: groupId)
        observeNewPosts(forGroup: groupId)
        
        if groupCount == 1 {
            self.friendButton.setTitle(String(groupCount) + " friend 👥", for: .normal)
        }
        else{
            self.friendButton.setTitle(String(groupCount) + " friends 👥", for: .normal)
        }
        
        activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicator!.center = self.collectionView.center
        self.collectionView.addSubview(activityIndicator!)
    
        view.addSubview(dimView)
        dimView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        //Custom layout
        let alignedFlowLayout = AlignedCollectionViewFlowLayout(horizontalAlignment: .justified, verticalAlignment: .bottom)
        collectionView.collectionViewLayout = alignedFlowLayout
        
        setUpUploadProgressView()
        
    }
    
    func setUpUploadProgressView() {
        //Setting up progress for multiple image uploading
        /*
         1. Create a custom UIView on Center of the screen.
         2. Add a UIProgress Bar on UIView
         3. Take a Progress() object
         4  Add a label to show total count and current uploading image number
         5.
         */
        //Add custom UIView
        progressView.progress = 0.0
        progressView.progressTintColor = .white

        dimView.addSubview(viewProgress)
        viewProgress.translatesAutoresizingMaskIntoConstraints = false
        
        viewProgress.centerXAnchor.constraint(equalTo: dimView.centerXAnchor).isActive = true
        viewProgress.centerYAnchor.constraint(equalTo: dimView.centerYAnchor).isActive = true
        
        viewProgress.widthAnchor.constraint(equalToConstant: 300).isActive = true
        viewProgress.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        //Add Progress bar
        viewProgress.addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.leadingAnchor.constraint(equalTo: viewProgress.leadingAnchor, constant: 20).isActive = true
        progressView.trailingAnchor.constraint(equalTo: viewProgress.trailingAnchor, constant: -20).isActive = true
        progressView.bottomAnchor.constraint(equalTo: viewProgress.bottomAnchor, constant: -20).isActive = true
        
        //Add Label
        viewProgress.addSubview(progressLabel)
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.leadingAnchor.constraint(equalTo: progressView.leadingAnchor).isActive = true
        progressLabel.topAnchor.constraint(equalTo: viewProgress.topAnchor, constant: 20).isActive = true
        
        progress.completedUnitCount = 0
        
    }
        
    func updateUploadProgress() {
        self.progress.completedUnitCount += 1
        let completedProgres = Float(self.progress.fractionCompleted)
        //print("Completed Progress is: \(completedProgres)")
        self.progressView.setProgress(completedProgres, animated: true)
        
        if self.progress.completedUnitCount == self.progress.totalUnitCount {
            print("Progress is completed")
            self.progressLabel.text = "Uploading Successful"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.enableViews()
                self.resetUploadProgress()
            }
        }
    }
    
    func updateProgressLabel(forIndex index: Int) {
        self.progressLabel.text = "Uploading (\(index)/\(self.assetCount))"
    }
    
    func resetUploadProgress() {
        progressView.setProgress(0.0, animated: true)
        progress.totalUnitCount = 10
        progress.completedUnitCount = 0
        progress.totalUnitCount = 0
    }
    
    func disableViews() {
        UIView.animate(withDuration: 0.2) {
            self.navigationController?.navigationBar.alpha = 0.5
            self.dimView.isHidden = false
        }
    }
    
    func enableViews() {
        self.navigationController?.navigationBar.alpha = 1.0
        self.dimView.isHidden = true
    }
    
    @objc func handleUpdateFeed() {
        handleRefresh()
    }
    
    @objc func handleRefresh() {
        guard let groupId = self.group?.groupid else {return}
        self.posts.removeAll()
        self.objects.removeAll()
        fetchPostsWithGroupID(groupID: groupId)
    
        if self.posts.count == 0 && self.objects.count == 0 {
            self.removeSpinner()
            self.collectionView.reloadData()
            self.collectionView.setEmptyMessage("hmm no pics yet. 🤔 ")
            self.collectionView?.refreshControl?.endRefreshing()
            return
        }
        
    }
    
    @objc func updateGroupNameFunc(notification: NSNotification) {
        self.navigationItem.title = notification.userInfo?["groupName"] as? String
          }
    
    
//    func getAllPosts() {
//        //print("getAllPosts() called")
//        guard let groupId = self.group?.groupid else {return}
//        self.posts.removeAll()
//        self.objects.removeAll()
//
//        fetchPostsWithGroupID(groupID: groupId, isInitialLoad: false)
//    }
    
    var posts = [Picture]()
    
    func checkIfNoPosts(forGroup groupId: String) {
        Database.database().reference().child("posts").child(groupId).observeSingleEvent(of: .value) { (snapshot) in
            if (!snapshot.exists()) {
                print("Group contains no pictures")
                self.collectionView.setEmptyMessage("hmm no pics yet. 🤔 ")
            }
            else {
                print("Group contains pictures")
                self.collectionView.setEmptyMessage("")
            }
        }
    }
    
    func observeNewPosts(forGroup groupId: String) {
        Database.database().reference().child("posts").child(groupId).observe(.childAdded) { (snapshot) in
            guard let dictionary = snapshot.value as? [String:Any] else {
                return
            }
            // print("Dict is: \(dictionary)")
    
            let key = snapshot.key
            
            let userIDToAdd = dictionary["userid"] as? String ?? ""
                            
            let creationDateToAdd = dictionary["creationDate"] as? String? ?? ""
            
            guard let groupName = dictionary["groupname"] else {return}
            let groupNameToAdd = groupName as? String ?? ""
            
            guard let imageURL = dictionary["imageUrl"] else {return}
            
            guard let imageWidth = dictionary["imageWidth"] as? Double else {return}
            guard let imageHeight = dictionary["imageHeight"] as? Double else {return}
            
            var isHorizontal = false
            if let isExistingImageHorizontal = dictionary["isHorizontal"] as? Bool {
                isHorizontal = isExistingImageHorizontal
            }
            
            let imageURLToAdd = imageURL as? String ?? ""
            
            Database.database().reference().child("users").child(userIDToAdd).observeSingleEvent(of: .value) { (usersnapshot) in
                guard let userDictionary = usersnapshot.value as? [String: Any] else { return }
                
                let usernameToAdd = userDictionary["username"] as? String ?? ""
                
                let phonenumberToAdd = userDictionary["phonenumber"] as? String ?? ""

                let groups = userDictionary["groups"] as? [String : Any] ?? [:]

                let userToAdd = User(uid: userIDToAdd, username: usernameToAdd, phonenumber: phonenumberToAdd, groups: groups)
                
                let creationDateFormat = self.parseDuration(creationDateToAdd ?? "")
                                    
                let post = Picture(user: userToAdd, imageUrl: imageURLToAdd, creationDate: creationDateFormat, groupName: groupNameToAdd, isDeveloped: false, isSelectedByUser: false, picID: key, imageWidth: imageWidth, imageHeight: imageHeight, isHorizontal: isHorizontal)
                                    
                
                self.posts.append(post)
                
                self.posts.sort { (p1, p2) -> Bool in
                    let c1 = Date(timeIntervalSince1970: p1.creationDate)
                    let c2 = Date(timeIntervalSince1970: p2.creationDate)
                    return c1.compare(c2) == .orderedDescending
                }
                
                self.objects.append(PrintableObject(isSelectedByUser: false, post: post))

                self.objects.sort { (p1, p2) -> Bool in
                    let c1 = Date(timeIntervalSince1970: p1.post.creationDate)
                    let c2 = Date(timeIntervalSince1970: p2.post.creationDate)
                    return c1.compare(c2) == .orderedDescending
                }
                
                self.collectionView.reloadData()
                self.removeSpinner()
                if self.posts.count != 0 {
                    self.collectionView.setEmptyMessage("")
                }
            }
        }
//       Database.database().reference().child("posts").child(groupId).observeSingleEvent(of: .value) { (snapshot) in
//            print("All children are iterated")
//        }
    }
    
    
    fileprivate func fetchPostsWithGroupID(groupID: String, isInitialLoad: Bool = true) {
        Database.database().reference().child("posts").child(groupID).observeSingleEvent(of: .value) { (snapshot) in
            
            guard let dictionaries = snapshot.value as? [String: Any] else {
                self.removeSpinner()
                return }
            
            if isInitialLoad {
                self.initialPostsCount = dictionaries.count
            }
            
            print("Dictionary count is: \(dictionaries.count)")
            self.collectionView.setEmptyMessage("")
            dictionaries.forEach { (key, value) in
                guard let dictionary = value as? [String : Any] else {return}
                
               // print(key, value)
                
                
                let userIDToAdd = dictionary["userid"] as? String ?? ""
                                
                let creationDateToAdd = dictionary["creationDate"] as? String? ?? ""
                
                guard let groupName = dictionary["groupname"] else {return}
                let groupNameToAdd = groupName as? String ?? ""
                
                guard let imageURL = dictionary["imageUrl"] else {return}
                
                guard let imageWidth = dictionary["imageWidth"] as? Double else {return}
                guard let imageHeight = dictionary["imageHeight"] as? Double else {return}
                
                var isHorizontal = false
                if let isExistingImageHorizontal = dictionary["isHorizontal"] as? Bool {
                    isHorizontal = isExistingImageHorizontal
                }
                
                
                let imageURLToAdd = imageURL as? String ?? ""
                
                Database.database().reference().child("users").child(userIDToAdd).observeSingleEvent(of: .value) { (usersnapshot) in
                    
                    guard let userDictionary = usersnapshot.value as? [String: Any] else { return }
                    
                    let usernameToAdd = userDictionary["username"] as? String ?? ""
                    
                    let phonenumberToAdd = userDictionary["phonenumber"] as? String ?? ""

                    let groups = userDictionary["groups"] as? [String : Any] ?? [:]

                    let userToAdd = User(uid: userIDToAdd, username: usernameToAdd, phonenumber: phonenumberToAdd, groups: groups)
                    
                    let creationDateFormat = self.parseDuration(creationDateToAdd ?? "")
                                        
                    let post = Picture(user: userToAdd, imageUrl: imageURLToAdd, creationDate: creationDateFormat, groupName: groupNameToAdd, isDeveloped: false, isSelectedByUser: false, picID: key, imageWidth: imageWidth, imageHeight: imageHeight, isHorizontal: isHorizontal)
                                        
                    
                    self.posts.append(post)
                    
                    self.posts.sort { (p1, p2) -> Bool in
                        let c1 = Date(timeIntervalSince1970: p1.creationDate)
                        let c2 = Date(timeIntervalSince1970: p2.creationDate)
                        return c1.compare(c2) == .orderedDescending
                    }
                    
                    self.objects.append(PrintableObject(isSelectedByUser: false, post: post))

                    self.objects.sort { (p1, p2) -> Bool in
                        let c1 = Date(timeIntervalSince1970: p1.post.creationDate)
                        let c2 = Date(timeIntervalSince1970: p2.post.creationDate)
                        return c1.compare(c2) == .orderedDescending
                    }
                    
                    self.collectionView.reloadData()
                    //self.collectionView?.refreshControl?.endRefreshing()
                   // print("Success")
                    self.removeSpinner()
                    
                    //print("Posts count is: \(self.posts.count)")
                    
                    if self.posts.count == self.initialPostsCount + self.assetCount {
                        print("All posts have been fetched")
                        self.initialPostsCount = self.posts.count
                        self.collectionView.setEmptyMessage("")
                        self.hideActivityIndicator()
                    }
                    
                }
            }
        }
    }
    
    func parseDuration(_ timeString:String) -> TimeInterval {
        guard !timeString.isEmpty else {
            return 0
        }

        var interval:Double = 0

        let parts = timeString.components(separatedBy: ":")
        for (index, part) in parts.reversed().enumerated() {
            interval += (Double(part) ?? 0) * pow(Double(60), Double(index))
        }

        return interval
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! GroupRollCell
               
        if indexPath.row <= objects.count {
            let pic = self.objects[indexPath.row]
            
            cell.post = pic.post

            let url = URL(string: pic.post.imageUrl)
            cell.photoImageView.kf.setImage(with: url)
            
            cell.configureCell(isSelectedByUser: objects[indexPath.row].isSelectedByUser)
                            
            return cell
        }
        
        
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let post = self.posts[indexPath.row]

        if isSelected{
            if let cell = collectionView.cellForItem(at: indexPath) as? GroupRollCell {
                                
                if objects[indexPath.row].isSelectedByUser == false {
                    objects[indexPath.row].isSelectedByUser = true
//                    self.posts[indexPath.row].isSelectedByUser = true
                    UIView.transition(with: view, duration: 0.2, options: .transitionCrossDissolve, animations: {
                            cell.selectedView.alpha = 1.0
                            cell.selectedBackground.alpha = 0.5
                    })
                }
                else{
//                    self.posts[indexPath.row].isSelectedByUser = false
                    objects[indexPath.row].isSelectedByUser = false
                    UIView.transition(with: view, duration: 0.2, options: .transitionCrossDissolve, animations: {
                            cell.selectedView.alpha = 0.0
                            cell.selectedBackground.alpha = 0.0
                    })
                }
            }
        }
            
        else{
            let pictureVC = PictureController()
            pictureVC.groupNameLabel.text = post.groupName
                        
            let url = URL(string: post.imageUrl)
//            pictureVC.groopImage.kf.setImage(with: url)
            pictureVC.photoImageView.kf.setImage(with: url)
            pictureVC.picture = post
            pictureVC.groupId = self.group?.groupid
            
            pictureVC.usernameLabel.text = "taken by: @" + post.user.username
            let picDate = Date(timeIntervalSince1970: post.creationDate)
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: NSLocale.current.identifier)
            dateFormatter.setLocalizedDateFormatFromTemplate("yyyy-MM-dd")
            pictureVC.dateLabel.text = "date: " + dateFormatter.string(from: picDate)

            
            self.navigationController?.navigationBar.isHidden = false
            self.navigationItem.leftItemsSupplementBackButton = true
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

            self.navigationController?.pushNavBarWithTitle(vc: pictureVC)
            
//            self.navigationItem.setBackImageEmpty()

        }
        
        var boolChecker = false
//        for post in self.posts{
//            if post.isSelectedByUser{
//                boolChecker = true
//            }
//        }
        for object in objects{
            if object.isSelectedByUser{
                boolChecker = true
            }
        }
        
        if boolChecker{
            UIView.transition(with: view, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.actualPrintButton.isEnabled = true
                self.actualPrintButton.alpha = 1.0
            })
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if isSelected{
            if let cell = collectionView.cellForItem(at: indexPath) as? GroupRollCell {
                
//                print(indexPath.row, "please")
//                print(objects[indexPath.row].isSelectedByUser, "please")
                
                if objects[indexPath.row].isSelectedByUser == true {
//                    self.posts[indexPath.row].isSelectedByUser = false
                    self.objects[indexPath.row].isSelectedByUser = false
                    UIView.transition(with: view, duration: 0.2, options: .transitionCrossDissolve, animations: {
                            cell.selectedView.alpha = 0.0
                            cell.selectedBackground.alpha = 0.0
                    })
                }
                else{
//                    self.posts[indexPath.row].isSelectedByUser = true
                    self.objects[indexPath.row].isSelectedByUser = true
                    UIView.transition(with: view, duration: 0.2, options: .transitionCrossDissolve, animations: {
                            cell.selectedView.alpha = 1.0
                            cell.selectedBackground.alpha = 0.5
                    })
                }
            }
         }
         else{
            //nothing
         }
        
        var boolCount = 0
        
//        for post in self.posts{
//            if post.isSelectedByUser == true{
//                boolCount += 1
//            }
//        }
//
        for object in objects{
            if object.isSelectedByUser == true {
                boolCount += 1
            }
        }
        
        if boolCount == 0 {
            UIView.transition(with: view, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.actualPrintButton.isEnabled = false
                self.actualPrintButton.alpha = 0.75
            })
        }
    }
     
    /*
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (self.posts.count == 0) {
            self.collectionView.setEmptyMessage("hmm no pics yet. 🤔 ")
        } else {
            self.collectionView.restore()
        }
        
        return self.posts.count
    } */
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.posts.count
    }
        
    @objc func handlePrintPhotos(){
        
        UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.printButton.isHidden = true
            self.friendButton.isHidden = true
            self.actualPrintButton.isHidden = false
            
            self.navigationItem.backBarButtonItem = nil
            self.navigationItem.leftBarButtonItem = nil
            self.navigationItem.rightBarButtonItems = nil

            
            self.navigationItem.setRightBarButton(UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.handleCancel)), animated: false)
            
            self.navigationItem.setLeftBarButton(UIBarButtonItem(title: "Select All", style: .plain, target: self, action: #selector(self.handleSelectAll)), animated: false)
                        
            self.navigationItem.title = nil

            self.isSelected = true
            
            print(self.isSelected)

        })
        
    }
    
    @objc func handleSelectAll(){
        
        for object in objects{
            object.isSelectedByUser = true
        }
        
        if objects.count == 0 {
            self.actualPrintButton.isEnabled = false
            self.actualPrintButton.alpha = 0.75
        }
        else{
            self.actualPrintButton.isEnabled = true
            self.actualPrintButton.alpha = 1.0
        }
        
        self.collectionView.reloadData()
        let section = 0
        let item = collectionView.numberOfItems(inSection: section) - 1
        let lastIndexPath = IndexPath(item: item, section: section)
        self.collectionView.scrollToItem(at: lastIndexPath, at: .bottom, animated: true)
        
    }
    
    @objc func handleCancel(){
//        UIView.transition(with: self.view, duration: 0.3, options: .transitionCrossDissolve, animations: {
        self.printButton.isHidden = false
        self.friendButton.isHidden = false
        self.actualPrintButton.isHidden = true
    
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.backBarButtonItem = nil

        //self.navigationItem.setRightBarButton(UIBarButtonItem(image: UIImage(named: "cameraiconwhite")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(self.handleCamera)), animated: false)

        self.navigationItem.backBarButtonItem = UIBarButtonItem(image: UIImage(named: "backbutton"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.handleBack))
        
        addRightBarButtonItems()

        self.isSelected = false

        print(self.isSelected, "please")

        self.navigationItem.title = self.group?.groupname
                
//        for (index, _) in self.posts.enumerated(){
//            self.objects[index].isSelectedByUser = false
//        }
//
        for object in objects{
            object.isSelectedByUser = false
        }

        
        self.collectionView.reloadData()
        self.actualPrintButton.isEnabled = false
        self.actualPrintButton.alpha = 0.75
    }
    
    @objc func handleBack(){
        navigationController?.popViewController(animated: true)
    }
    
    
    @objc func handleActualPrintPhotos(){
        var printObjectArray = [QuantityObject]()
        
        var count = 0
        for object in objects{
            if object.isSelectedByUser{
                count += 1
                
                let imageView = UIImageView()
                
                //Z: Fix for image not showing on printquantitycontroller
                let url = URL(string: object.post.imageUrl)
                imageView.kf.setImage(with: url)
                
                printObjectArray.append(QuantityObject(quantity: 1, printableObject: object, image: imageView.image ?? UIImage(), isHorizontal: object.post.isHorizontal))
            }
        }
        
        if count == 0 {
            self.presentFailedCheckout()
        }
            
        else{
            let printQuantityVC = PrintQuantityController(collectionViewLayout: UICollectionViewFlowLayout())
            
            printQuantityVC.objects = printObjectArray
            
            self.navigationController?.pushNavBarWithTitle(vc: printQuantityVC)
            self.navigationItem.setBackImageEmpty()
        }
    }
    
    func presentFailedCheckout(){
        let alert = UIAlertController(title: "At least 1 photo needs to be printed.", message: "", preferredStyle: .alert)
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
    
    @objc func handleFriends(){
        let friendsVC = FriendsController()
        friendsVC.group = self.group
        self.navigationController?.pushNavBarWithTitle(vc: friendsVC)
        self.navigationItem.setBackImageEmpty()
    }
    
    @objc func handleCamera(){
        
        let cameraController = CameraController()
        cameraController.group = self.group
        
        cameraController.username = username
                                                        
        let navVC = UINavigationController(rootViewController: cameraController)

        navVC.modalPresentationStyle = .fullScreen

        let height: CGFloat = 200 //whatever height you want to add to the existing height
        let bounds = navVC.navigationBar.bounds
        navVC.navigationBar.frame = CGRect(x: 0, y: 0, width: 50, height: bounds.height + height)
        
        navVC.setNavigationBarHidden(true, animated: false)

        self.present(navVC, animated: true, completion: nil)
    }
    
    
    func showAlertForMaximumImages() {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "You can't upload more than 10 photos at one time", message: "", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @objc func openGallery() {
        let imagePicker = ImagePickerController()
        
        let options = PHImageRequestOptions()
        options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true

        presentImagePicker(imagePicker, select: { (asset) in
            // User selected an asset. Do something with it. Perhaps begin processing/upload?
            print("User selected an asset")
        }, deselect: { (asset) in
            // User deselected an asset. Cancel whatever you did when asset was selected.
            print("User DeSelected an asset")
        }, cancel: { (assets) in
            // User canceled selection.
        }, finish: { (assets) in
            // User finished selection assets.
            print("User finished selecting assets")
            
            //Don't allow user to upload more than 10 images at one time
            if assets.count > 10 {
                self.showAlertForMaximumImages()
                return
            }
            
            //Upload all the images on firebase storage
            print("Number of assets: \(assets.count)")
            self.progress.totalUnitCount = Int64(assets.count)
            self.showActivityIndicator()
            for asset in assets {
                self.assetCount = assets.count
                print("Asset is: \(asset)")
                // Request the maximum size. If you only need a smaller size make sure to request that instead.
                PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: options) { (image, info) in
                    // Do something with image

                    self.hideActivityIndicator()
                    guard let dictInfo = info as? [String:Any] else {
                        return
                    }
                    
                    guard let isDegraded = dictInfo["PHImageResultIsDegradedKey"] as? Bool else {
                        print("isDegraded not found")
                        return
                    }
                                        
                    guard !isDegraded else {
                        print("isDegraded is true")
                        return
                    }
                    
                    guard let fetchedImage = image else {
                        print("NO IMAGE FOUND")
                        return
                    }
                    
                    
                    print("isDegraded is: \(isDegraded)")
                    let fixedImage = fetchedImage.fixOrientation()
                    //self.applyFormatingOnImageAndAddToArray(prev: fixedImage)
                    self.getFormattedImageAndAddToArray(prev: fixedImage)
                }
            }
        })
    }
    
    func layoutViews(){
        
        collectionView.backgroundColor = Theme.backgroundColor
        
        setupNavBar()
        
        self.view.addSubview(printButton)
        printButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 50, paddingRight: 210, width: view.frame.width * 0.482667, height: 66)
        printButton.layer.applySketchShadow(color: .black, alpha: 0.5, x: 0, y: 2, blur: 4, spread: 0)
        
        self.view.addSubview(friendButton)
        friendButton.anchor(top: nil, left: nil, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 210, paddingBottom: 50, paddingRight: 5, width: view.frame.width * 0.482667, height: 66)
          friendButton.layer.applySketchShadow(color: .black, alpha: 0.5, x: 0, y: 2, blur: 4, spread: 0)
        
        self.view.addSubview(actualPrintButton)
        
        self.actualPrintButton.anchor(top: nil, left: self.view.leftAnchor, bottom: self.view.bottomAnchor, right: self.view.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 50, paddingRight: 5, width: 0, height: 66)
        self.actualPrintButton.layer.applySketchShadow(color: .black, alpha: 0.5, x: 0, y: 2, blur: 4, spread: 0)
        self.actualPrintButton.isHidden = true
        
        collectionView.alwaysBounceVertical = true
        collectionView.allowsMultipleSelection = true

    }
    
    fileprivate func setupNavBar(){
        guard let groupTitle = self.group?.groupname else {return}
        self.navigationItem.title = groupTitle
        
//        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "cameraiconwhite")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleCamera))
        addRightBarButtonItems()
    }
    
    func addRightBarButtonItems() {
        let cameraButton = UIBarButtonItem(image: UIImage(named: "cameraiconwhite")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleCamera))
        
        let galleryButton = UIBarButtonItem(image: UIImage(named: "galleryIcon")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(openGallery))

        self.navigationItem.setRightBarButtonItems([cameraButton,galleryButton], animated: true)
    }
}

extension UIViewController {

    func presentDetail(_ viewControllerToPresent: UIViewController) {
        let transition = CATransition()
        transition.duration = 0.25
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromRight
        self.view.window!.layer.add(transition, forKey: kCATransition)

//        present(viewControllerToPresent, animated: true)
        
        present(viewControllerToPresent, animated: true, completion: nil)
    }

    func dismissDetail() {
        let transition = CATransition()
        transition.duration = 0.25
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromLeft
        self.view.window!.layer.add(transition, forKey: kCATransition)

        dismiss(animated: false)
    }
    
}

extension Date {
  func asString(style: DateFormatter.Style) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = style
    return dateFormatter.string(from: self)
  }
}

extension UIView {

    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    func asImage() -> UIImage {
        if #available(iOS 10.0, *) {
            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            return renderer.image { rendererContext in
                layer.render(in: rendererContext.cgContext)
            }
        } else {
            UIGraphicsBeginImageContext(self.frame.size)
            self.layer.render(in:UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return UIImage(cgImage: image!.cgImage!)
        }
    }
}

var vSpinner : UIView?
 
extension UIViewController {
    func showSpinner(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = Theme.backgroundColor
        let ai = UIActivityIndicatorView.init(style: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center

        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }

        vSpinner = spinnerView
    }
    
    func removeSpinner() {
        DispatchQueue.main.async {
            vSpinner?.removeFromSuperview()
            vSpinner = nil
        }
    }
}

extension GroupRollController {
    func applyFormatingOnImageAndAddToArray(prev: UIImage) {
        //var prev = UIImage()

        guard let cgimage = prev.cgImage else {return}
        
        let isHorizontal = prev.size.width > prev.size.height
        let originalCIImage = CIImage(cgImage: cgimage, options: [.applyOrientationProperty:true])
        let sepiaCIImage = originalCIImage

        var previewImage = UIImage()
        previewImage = UIImage(ciImage: sepiaCIImage)
        
        let viewHeight = getVariableHeightForImage(isLandscape: isHorizontal)
        
        //let containerView = UIView(frame: CGRect(x: 0, y: 44, width: view.frame.width, height: view.frame.width * 1.561))
        let containerView = UIView(frame: CGRect(x: 0, y: 44, width: view.frame.width, height: viewHeight))
        containerView.backgroundColor = .clear

        let groopImage = UIImageView()
        containerView.addSubview(groopImage)

        groopImage.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        groopImage.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

        groopImage.contentMode = .scaleAspectFit
        groopImage.clipsToBounds = true
        groopImage.backgroundColor = .clear
        groopImage.image = previewImage
        
//        groopImage.layer.borderColor = UIColor.black.cgColor
//        groopImage.layer.borderWidth = 2

        let groopCamLabel = UILabel().setupLabel(ofSize: 10, weight: UIFont.Weight.regular, textColor: Theme.black, text: "", textAlignment: .right)
        groopCamLabel.sizeToFit()
        containerView.addSubview(groopCamLabel)
        groopCamLabel.anchor(top: groopImage.bottomAnchor, left: nil, bottom: nil, right: groopImage.rightAnchor, paddingTop: -1, paddingLeft: 0, paddingBottom: 0, paddingRight: 1, width: 200, height: 20)

        groopCamLabel.setCharacterSpacing(-0.4)

        containerView.layer.masksToBounds = false
        containerView.layer.applySketchShadow(color: .black, alpha: 0.5, x: 0, y: 2, blur: 4, spread: 0)

        //This is where the image size changes from it's original size. Need to handle this thing.
        guard let image = imageWithView(view: containerView) else {return}

        let objImage = Image(image: image, isHorizontal: isHorizontal)
        
        arrImages.append(objImage)

        if arrImages.count == assetCount {
            print("Image array count is: \(arrImages.count)")
            startUploading {
                print("start uploading")
            }
        }
    }
    
    func getVariableHeightForImage(isLandscape: Bool) -> CGFloat {
        var calculatedHeight: CGFloat = 0
        
        //Landscape
        print("isLandscape is: \(isLandscape)")
        if isLandscape {
            calculatedHeight = (view.frame.width) / 2
        }

        //Portrait
        else  {
            calculatedHeight = (view.frame.width) * 1.561
        }
                
        return calculatedHeight
    }
    
    func imageWithView(view: UIView) -> UIImage? {
        
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        let image = renderer.image { ctx in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }

        return image
        
//        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0)
//        defer { UIGraphicsEndImageContext() }
//
//        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
//        return UIGraphicsGetImageFromCurrentImageContext()
        
    }

    //Test - Zubair
    func getFormattedImageAndAddToArray(prev: UIImage) {
        //var prev = UIImage()
        let imageView = UIImageView(image: prev)
        //imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit

        imageView.layer.applySketchShadow(color: .black, alpha: 0.5, x: 0, y: 2, blur: 4, spread: 0)

        //This is where the image size changes from it's original size. Need to handle this thing.
        
        let isHorizontal = prev.size.width > prev.size.height
        let image = Image(image: imageView.image!, isHorizontal: isHorizontal)
        arrImages.append(image)

        if arrImages.count == assetCount {
            print("Image array count is: \(arrImages.count)")
            startUploading {
            }
        }
    }
    
    //**********//
    func startUploading(completion: @escaping FileCompletionBlock) {
        if arrImages.count == 0 {
            completion()
            return;
        }
        
        block = completion
        
        disableViews()
        uploadImage(forIndex: 0)
    }

    func uploadImage(forIndex index:Int) {
        if index < arrImages.count {
            /// Perform uploading
            print("Uploading \(index + 1) of \(self.assetCount)")

            //Show upload progress label
            updateProgressLabel(forIndex: index + 1)
            
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            guard let groupId = self.group?.groupid else {return}
            
            guard let groupName = self.group?.groupname else {return}
            
            let image = arrImages[index].image
            
            let isHorizontal = arrImages[index].isHorizontal
            
            guard let uploadData = image.jpegData(compressionQuality: 0.5) else { return }
            
            //guard let pngData = image.pngData() else {return}
            //let testImage = UIImage(data: pngData)
            let picId = NSUUID().uuidString
            
            Storage.storage().reference().child("posts").child(picId).putData(uploadData, metadata: nil) { (metadata, err) in
                FirFile.shared.upload(data: uploadData, withName: picId, block: { (url) in
                    /// After successfully uploading call this method again by increment the **index = index + 1**
                    print(url ?? "Couldn't not upload. You can either check the error or just skip this.")
                    
                    if let strUrl = url {
                        self.saveToDatabaseWithImageUrl(imageUrl: strUrl, userID: uid, groupID: groupId, groupName: groupName, image: image, picId: picId, isHorizontal: isHorizontal)
                    }
                    
                    //Update progress bar
                    print("Updating Progress for: \(index + 1) / \(self.progress.totalUnitCount)")
                    self.updateUploadProgress()
                    
                    //Upload next Image
                    self.uploadImage(forIndex: index + 1)
                })
                return;
            }
            
            if block != nil {
                block!()
            }
        }
        else {
            print("All Images have been uploaded.")
            arrImages.removeAll()
            self.collectionView.setEmptyMessage("")
            
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            guard let groupId = self.group?.groupid else {return}
            
            guard let groupName = self.group?.groupname else {return}
            
            sendNotificationToGroupUsers(uid, groupId, groupName)

            //enableViews()
            //resetUploadProgress()
        }
    }
    
    func saveToDatabaseWithImageUrl(imageUrl: String, userID: String, groupID: String, groupName: String, image: UIImage, picId: String, isHorizontal: Bool) {
        let postImage = image
                
        let values = ["imageUrl": imageUrl, "groupname": groupName, "imageWidth": postImage.size.width, "imageHeight": postImage.size.height, "creationDate": String(Date().timeIntervalSince1970), "userid": userID, "isHorizontal": isHorizontal] as [String : Any]
        
        let picValues = [picId: values]
        
        Database.database().reference().child("posts").child(groupID).updateChildValues(picValues) { (err, ref) in
            if let err = err {
                print("Failed to save image to DB", err)
                return
            }
            
            print("Successfully saved post to DB")
            
            //self.getAllPosts()
        }
        
    Database.database().reference().child("groups").child(groupID).child("lastPicture").setValue(String(Date().timeIntervalSince1970))
    }
    
    func sendNotificationToGroupUsers (_ userId: String, _ groupId: String, _ groupName: String) {
        guard let username = UserDefaults.standard.string(forKey: "username") else { return }
        Database.database().reference().child("members").child(groupId).observeSingleEvent(of: .value) {(snapshot) in
            if let dictionary = snapshot.value as? [String:Bool] {
                let uidArray = Array(dictionary.keys)
                for eachUid in uidArray {
                    if eachUid != userId {
                        Database.database().reference().child("users").child(eachUid).child("token").observeSingleEvent(of: .value) {(snapshot) in
                            if let value = snapshot.value as? String {
                                let sender = PushNotificationSender()
                                sender.sendPushNotification(to: value, body: "@\(username) uploaded images to \"\(groupName)\".")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func showActivityIndicator() {
        activityIndicator!.startAnimating()
    }
    
    func hideActivityIndicator() {
        activityIndicator!.stopAnimating()
    }
}

extension GroupRollController: UICollectionViewDelegateFlowLayout {
    //Horizontal spacing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 23
    }

    //Vertical spacing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 40
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 19, left: 14, bottom: 19, right: 14)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let pic = self.objects[indexPath.row]

        let width = (view.frame.width - 2) / 3
        
        let testHeight = pic.post.isHorizontal ? (width*1.561 - 40) / 2 : width*1.561 - 40
        
        //print("Image is: \(pic.post.imageUrl) \n Size is: \(CGSize(width: width - 25, height: testHeight))")

        return CGSize(width: width - 25, height: testHeight)
        //return CGSize(width: 80, height: 80)
    }
}

