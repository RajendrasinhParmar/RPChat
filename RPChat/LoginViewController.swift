//
//  LoginViewController.swift
//  RPChat
//
//  Created by Rajendrasinh Parmar on 23/07/16.
//  Copyright © 2016 Rajendrasinh Parmar. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet var anonymousLoginBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //set border of button
        anonymousLoginBtn.layer.borderWidth = 2.0
        anonymousLoginBtn.layer.borderColor = UIColor.whiteColor().CGColor
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func loginAnonymouslyDidTapped(sender: AnyObject) {
        print("Login Anonymously did button tapped")
        
        //Anonymously Log use in
        //switch view by setting navigation controller as rootview controller
        
        //Create a main storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        //From main storyboard instantiate a navigation controller
        let navVC = storyboard.instantiateViewControllerWithIdentifier("navigationVC") as! UINavigationController
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        //set navigation view as root view
        appDelegate.window?.rootViewController = navVC
    }
    
    @IBAction func googleLoginDidTapped(sender: AnyObject) {
        print("google Login did tapped")
        
        //Create a main storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        //From main storyboard instantiate a navigation controller
        let navVC = storyboard.instantiateViewControllerWithIdentifier("navigationVC") as! UINavigationController
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        //set navigation view as root view
        appDelegate.window?.rootViewController = navVC
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
