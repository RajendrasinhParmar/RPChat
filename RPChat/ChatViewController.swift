//
//  ChatViewController.swift
//  RPChat
//
//  Created by Rajendrasinh Parmar on 23/07/16.
//  Copyright © 2016 Rajendrasinh Parmar. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import MobileCoreServices
import AVKit
import FirebaseDatabase
import FirebaseStorage

class ChatViewController: JSQMessagesViewController {
    var messages = [JSQMessage]()
    var messageRef = FIRDatabase.database().reference().child("messages")
    var avatarDict = [String: JSQMessagesAvatarImage]()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        if let currentUser = FIRAuth.auth()?.currentUser {
            self.senderId = currentUser.uid
            if currentUser.anonymous == true {
                self.senderDisplayName = "anonymous"
            }else{
                self.senderDisplayName = "\(currentUser.displayName!)"
            }
        }
        self.observeMessages()
    }
    
    func observeUsers(id: String) {
        FIRDatabase.database().reference().child("users").child(id).observeEventType(.Value, withBlock: {
            snapshot in
            if let dict = snapshot.value as? [String: AnyObject] {
                let avatarUrl = dict["profileUrl"] as! String
                self.setupAvatar(avatarUrl, messageId: id)
            }
        })
    }
    
    func setupAvatar(url: String, messageId: String) {
        if url != "" {
            let fileUrl = NSURL(string: url)
            let data = NSData(contentsOfURL: fileUrl!)
            let image = UIImage(data: data!)
            let userImage = JSQMessagesAvatarImageFactory.avatarImageWithImage(image, diameter: 30)
            avatarDict[messageId] = userImage
        }else{
            avatarDict[messageId] = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "profileImage"), diameter: 30)
        }
        collectionView.reloadData()
    }
    
    func observeMessages() {
        messageRef.observeEventType(.ChildAdded) { (snapshot:FIRDataSnapshot) in
            if let dict = snapshot.value as? NSDictionary{
                let MediaType = dict["MediaType"] as! String
                let senderId = dict["senderId"] as! String
                let senderName = dict["senderName"] as! String
                
                self.observeUsers(senderId)
                
                switch MediaType {
                case "TEXT":
                    let text = dict["text"] as! String
                    self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, text: text))
                case "PHOTO":
                    let fileUrl = dict["fileUrl"]  as! String
                    let data = NSData(contentsOfURL: NSURL(string: fileUrl)!)
                    let picture = UIImage(data: data!)
                    
                    let photo = JSQPhotoMediaItem(image: picture)
                    self.messages.append(JSQMessage(senderId: senderId, displayName: self.senderDisplayName, media: photo))
                    if self.senderId == senderId {
                        photo.appliesMediaViewMaskAsOutgoing = true
                    }else{
                        photo.appliesMediaViewMaskAsOutgoing = false
                    }
                case "VIDEO":
                    let fileUrl = dict["fileUrl"] as! String
                    let video = NSURL(string: fileUrl)
                    let videoItem = JSQVideoMediaItem(fileURL: video, isReadyToPlay: true)
                    self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, media: videoItem))
                    
                    if self.senderId == senderId {
                        videoItem.appliesMediaViewMaskAsOutgoing = true
                    }else{
                        videoItem.appliesMediaViewMaskAsOutgoing = false
                    }
                default:
                    print("Invalid data type")
                }
                self.collectionView.reloadData()
            }
        }
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        print("send button pressed")
        print("\(text)")
        let newMessage = messageRef.childByAutoId()
        let messageData = ["text": text, "senderId":senderId, "senderName":senderDisplayName, "MediaType":"TEXT"]
        newMessage.setValue(messageData)
        //        messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text))
        //        collectionView.reloadData()
        //        print(messages)
        self.finishSendingMessage()
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        let message = messages[indexPath.item]
        if message.senderId == self.senderId {
            return bubbleFactory.outgoingMessagesBubbleImageWithColor(.blackColor())
        }else{
            return bubbleFactory.incomingMessagesBubbleImageWithColor(.blueColor())
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        let message = messages[indexPath.item]
        return avatarDict[message.senderId]
    }
    
    
    override func didPressAccessoryButton(sender: UIButton!) {
        print("Did pressed AccessoryButton")
        let sheet = UIAlertController(title: "Media Messages", message: "Please select a media", preferredStyle: UIAlertControllerStyle.ActionSheet)
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (alert: UIAlertAction) in
            
        }
        let photoLibrary = UIAlertAction(title: "Photo Library", style: UIAlertActionStyle.Default) { (alert: UIAlertAction) in
            self.getMediaOfType(kUTTypeImage)
        }
        let videoLibrary = UIAlertAction(title: "Video Library", style: UIAlertActionStyle.Default) { (alert: UIAlertAction) in
            self.getMediaOfType(kUTTypeMovie)
        }
        sheet.addAction(cancel)
        sheet.addAction(photoLibrary)
        sheet.addAction(videoLibrary)
        self.presentViewController(sheet, animated: true, completion: nil)
        /*
         let imagePicker = UIImagePickerController()
         imagePicker.delegate = self
         presentViewController(imagePicker, animated: true, completion: nil)
         */
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAtIndexPath indexPath: NSIndexPath!) {
        print("didTapMessageBubbleAtIndexPath \(indexPath.item)")
        let message = messages[indexPath.item]
        
        if message.isMediaMessage{
            if let mediaItem = message.media as? JSQVideoMediaItem{
                let player = AVPlayer(URL: mediaItem.fileURL)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                self.presentViewController(playerViewController, animated: true, completion: nil)
            }
        }
    }
    
    func getMediaOfType(type: CFString) {
        let mediaPicker = UIImagePickerController()
        mediaPicker.delegate = self
        mediaPicker.mediaTypes = [type as String]
        self.presentViewController(mediaPicker, animated: true, completion: nil)
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        return cell
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logoutDidTapped(sender: AnyObject) {
        
        do{
            try FIRAuth.auth()?.signOut()
        } catch let error {
            print(error);
        }
        
        print(FIRAuth.auth()?.currentUser)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let loginVC = storyboard.instantiateViewControllerWithIdentifier("LoginVC")
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        appDelegate.window?.rootViewController = loginVC
    }
    
    func sendMedia(picture: UIImage?, video: NSURL?) {
        
        if let picture = picture{
            let filepath = "\(FIRAuth.auth()!.currentUser!.uid)/\(NSDate.timeIntervalSinceReferenceDate())"
            let data = UIImageJPEGRepresentation(picture, 0.1)
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpg"
            FIRStorage.storage().reference().child(filepath).putData(data!, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print(error?.localizedDescription)
                }
                
                let fileUrl = metadata!.downloadURLs![0].absoluteString
                
                let newMessage = self.messageRef.childByAutoId()
                let messageData = ["fileUrl": fileUrl, "senderId":self.senderId, "senderName":self.senderDisplayName, "MediaType":"PHOTO"]
                newMessage.setValue(messageData)
                
            }
        }else if let video = video{
            let filepath = "\(FIRAuth.auth()!.currentUser!.uid)/\(NSDate.timeIntervalSinceReferenceDate())"
            let data = NSData(contentsOfURL: video)
            let metadata = FIRStorageMetadata()
            metadata.contentType = "video/mp4"
            FIRStorage.storage().reference().child(filepath).putData(data!, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print(error?.localizedDescription)
                }
                
                let fileUrl = metadata!.downloadURLs![0].absoluteString
                
                let newMessage = self.messageRef.childByAutoId()
                let messageData = ["fileUrl": fileUrl, "senderId":self.senderId, "senderName":self.senderDisplayName, "MediaType":"VIDEO"]
                newMessage.setValue(messageData)
                
            }
        }
    }
    
}


extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        print("picked image")
        print(info)
        if let picture = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.sendMedia(picture, video: nil)
        }
        if let video = info[UIImagePickerControllerMediaURL] as? NSURL {
            self.sendMedia(nil, video: video)
        }
        self.dismissViewControllerAnimated(true, completion: nil)
        collectionView.reloadData()
    }
}
