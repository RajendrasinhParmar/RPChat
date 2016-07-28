//
//  Helper.swift
//  RPChat
//
//  Created by Rajendrasinh Parmar on 27/07/16.
//  Copyright © 2016 Rajendrasinh Parmar. All rights reserved.
//

import Foundation
import FirebaseAuth
import UIKit
import GoogleSignIn

class Helper {
    static let helper = Helper()
    
    func loginAnonymously() {
        FIRAuth.auth()?.signInAnonymouslyWithCompletion({ (anonymouseUser: FIRUser?, error: NSError?) in
            if error == nil {
                print(anonymouseUser!.uid)
                self.switchToNavigationViewController()
            }else{
                print(error!.localizedDescription)
                return
            }
        })
    }
    
    func loginWithGoogle(authentication: GIDAuthentication) {
        let credential = FIRGoogleAuthProvider.credentialWithIDToken(authentication.idToken, accessToken: authentication.accessToken)
        
        FIRAuth.auth()?.signInWithCredential(credential, completion: { (user: FIRUser?, error: NSError?) in
            if error != nil {
                print(error?.localizedDescription)
                return
            }else{
                print(user?.email)
                print(user?.displayName)
                self.switchToNavigationViewController()
            }
        })
    }
    
    private func switchToNavigationViewController(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navVC = storyboard.instantiateViewControllerWithIdentifier("navigationVC") as! UINavigationController
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.rootViewController = navVC
    }
}