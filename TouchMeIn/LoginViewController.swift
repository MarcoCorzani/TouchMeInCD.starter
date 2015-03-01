/*
* Copyright (c) 2014 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import CoreData
import LocalAuthentication

class LoginViewController: UIViewController {
  
  var managedObjectContext: NSManagedObjectContext? = nil
  
  let MyKeychainWrapper = KeychainWrapper()
  let createLoginButtonTag = 0
  let loginButtonTag = 1
    
  @IBOutlet weak var loginButton: UIButton!
    
  
  @IBOutlet weak var usernameTextField: UITextField!
  @IBOutlet weak var passwordTextField: UITextField!
  @IBOutlet weak var createInfoLabel: UILabel!  

  @IBOutlet weak var touchIDButton: UIButton!
  
    var error : NSError?
    var context = LAContext()
    
    override func viewDidLoad() {
    super.viewDidLoad()
    
    // 1.
    let hasLogin = NSUserDefaults.standardUserDefaults().boolForKey("hasLoginKey")
    
    // 2.
    if hasLogin {
        loginButton.setTitle("Login", forState: UIControlState.Normal)
        loginButton.tag = loginButtonTag
        createInfoLabel.hidden = true
    } else {
        loginButton.setTitle("Create", forState: UIControlState.Normal)
        loginButton.tag = createLoginButtonTag
        createInfoLabel.hidden = false
    }
    
    // 3.
    let storedUsername : NSString? = NSUserDefaults.standardUserDefaults().valueForKey("username") as? NSString
    usernameTextField.text = storedUsername
  
    touchIDButton.hidden = true
        
    if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
            touchIDButton.hidden = false
     }
    
    
    }
  
  // MARK: - Action for checking username/password
  @IBAction func loginAction(sender: AnyObject) {
    
    // 1.
    if (usernameTextField.text == "" || passwordTextField.text == "") {
        var alert = UIAlertView()
        alert.title = "You must enter both a username and password!"
        alert.addButtonWithTitle("Oops!")
        alert.show()
        return;
    }
    
    // 2.
    usernameTextField.resignFirstResponder()
    passwordTextField.resignFirstResponder()
    
    // 3.
    if sender.tag == createLoginButtonTag {
        
        // 4.
        let hasLoginKey = NSUserDefaults.standardUserDefaults().boolForKey("hasLoginKey")
        if hasLoginKey == false {
            NSUserDefaults.standardUserDefaults().setValue(self.usernameTextField.text, forKey: "username")
        }
        
        // 5.
        MyKeychainWrapper.mySetObject(passwordTextField.text, forKey:kSecValueData)
        MyKeychainWrapper.writeToKeychain()
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hasLoginKey")
        NSUserDefaults.standardUserDefaults().synchronize()
        loginButton.tag = loginButtonTag
        
        performSegueWithIdentifier("dismissLogin", sender: self)
    
    } else if sender.tag == loginButtonTag {
        // 6.
        if checkLogin(usernameTextField.text, password: passwordTextField.text) {
            performSegueWithIdentifier("dismissLogin", sender: self)
        } else {
            // 7.
            var alert = UIAlertView()
            alert.title = "Login Problem"
            alert.message = "Wrong username or password."
            alert.addButtonWithTitle("Foiled Again!")
            alert.show()
        }
      }
    }

  
    @IBAction func touchIDLoginAction(sender: AnyObject) {
        // 1.
        if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
            
            // 2.
            context.evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, localizedReason: "Logging in with Touch ID",
                reply: { (success: Bool, error: NSError! ) -> Void in
                    
                    // 3.
                    dispatch_async(dispatch_get_main_queue(), {
                        if success {
                            self.performSegueWithIdentifier("dismissLogin", sender: self)
                        }
                        
                        if error != nil {
                            
                            var message: NSString
                            var showAlert: Bool
                            
                            // 4.
                            switch(error.code) {
                            case LAError.AuthenticationFailed.rawValue:
                                message = "There was a problem verifying your identity."
                                showAlert = true
                            case LAError.UserCancel.rawValue:
                                message = "You pressed cancel."
                                showAlert = true
                            case LAError.UserFallback.rawValue:
                                message = "You pressed password."
                                showAlert = true
                            default:
                                showAlert = true
                                message = "Touch ID may not be configured"
                            }
                            
                            var alert = UIAlertView()
                            alert.title = "Error"
                            alert.message = message
                            alert.addButtonWithTitle("Darn!")
                            if showAlert {
                                alert.show()
                            }
                            
                        }
                    })
                    
            })
        } else {
            // 5.
            var alert = UIAlertView()
            alert.title = "Error"
            alert.message = "Touch ID not available"
            alert.addButtonWithTitle("Darn!")
            alert.show()
        }
    }

    func checkLogin(username: String, password: String ) -> Bool {
        if password == MyKeychainWrapper.myObjectForKey("v_Data") as NSString &&
            username == NSUserDefaults.standardUserDefaults().valueForKey("username") as? NSString {
                return true
        } else {
            return false
        }



    }

}
  
  

