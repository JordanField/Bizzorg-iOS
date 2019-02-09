//
//  LoginViewController.swift
//  Bizzorg
//
//  Created by Jordan Field on 25/04/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import UIKit

/**
 The login view controller allows a user to enter their username and password
 and have it sent to the server for approval.
 
 UI links
 ====================
 usernameField
 passwordField
 loginButton
 networkActivityIndicatorView: Spinning indicator that denotes credentials are 
 being checked
 */
class LoginViewController: UIViewController {
  
  @IBOutlet weak var usernameField: UITextField!
  @IBOutlet weak var passwordField: UITextField!
  @IBOutlet weak var loginButton: UIButton!
  @IBOutlet weak var networkActivityIndicatorView: UIActivityIndicatorView!
  
  var loginEnabled: Bool = true {
    willSet(newValue){
      loginButton.isEnabled = newValue
      usernameField.isEnabled = newValue
      passwordField.isEnabled = newValue
      if newValue {
        networkActivityIndicatorView.startAnimating()
      } else {
        networkActivityIndicatorView.stopAnimating()
      }
    }
  }

  ///User interface trigger function for the pressing of the log in button.
  ///Used to package the username and pasword entered to check with the server.
  @IBAction func loginButtonPressed(_ sender: UIButton) {
    //Check that there is text in the username and password fields before
    //continuing.
    guard usernameField.text != "" && passwordField.text != "" else {return}
    
    /*
     If you're wondering why these blocks of code are littered with
     executeUiChange calls, it's because iOS complains when you change
     something based on UI to the user on a thread that's not the main thread. 
     Therefore I have to run any UI changes on the main thread to ensure safety.
     */
    
    //Display to the user that the login is being processed.
    loginEnabled = false
    
    //get the username and passwords from the UI text fields.
    let username = usernameField.text!
    let password = passwordField.text!
    
    //Encode the users credentials in a dictionary for the login process.
    let userCredentials: KeyValuePairs = [
      "username": username,
      "password": password
    ]
    
    //Attempt to verify the username and password with the server.
    verifyUser(userCredentials, urlSession: globalUrlSession) {
      (employee, error) in
      //Check that no errors occured and the employee object exists.
      guard error == nil, employee != nil else {
        displayErrorMessage("Something went wrong. \(String(describing: error))",
                            viewController: self)
        //If the login process fails, re-enable login so the user can try again.
        self.loginEnabled = true
        return
      }
      
      loggedInUser = employee
      
      //Store the employee in permanent storage as a Key value pair dictionary.
      globalUserDefaults.set(employee!.toDict(), forKey: "logged-in-user")
      
      executeUiChange {
        //Transfer the user out of the login screen and back into the main UI.
        self.performSegue(withIdentifier: "user-logged-in", sender: nil)
      }
      //Allow login again in case this view is instantiated another time.
      self.loginEnabled = true
    }
    
  }
}
