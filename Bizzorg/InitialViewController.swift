
//  InitialViewController.swift
//  Bizzorg
//
//  Created by Jordan Field on 21/04/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import UIKit

/**
 The initial view controller is the first view controller that is instantiated,
 and acts as the backbone for the user to navigate through all the other view
 controllers. Most of this is done automatically by iOS, so I don't need to
 write code for it, but I have to check on this initial screen that there is a
 logged in user.
 */

internal var loggedInUser: Employee? = nil

class InitialViewController: UITabBarController {
  
  /**
   The viewDidAppear function is called on a view when it is displayed on 
   screen, In this instance, the first thing I want to do is check that there is
   a user currently logged into the app.
  */
  override func viewDidLoad() {
    //Check that there is a logge in user. If there is one, retrieve the user
    //model and assign it to the user constant. If no user is logged in,
    //transition to the log in screen.
     guard let user = getLoggedInUser() else {
      executeUiChange {
        self.performSegue(withIdentifier: "goto-login", sender: nil)
      }
      return
    }
    loggedInUser = user
    
    /**
     Now that the user has been checked check the database for any changes to
     the user.
     */
    
    let call = BizzorgApiCall(loggedInUser!.resourceUri, method: .GET)
    call.sendToServer(globalUrlSession) {
      guard call.responseValidated else {
        //If the response contains an error, assume the login is erroneous and
        //move to the login-screen.
        self.performSegue(withIdentifier: "goto-login", sender: nil)
        return
      }
      //Try to create a new user with the server information. If this fails,
      //move to the login screen.
      guard let updatedUser = Employee(data: call.serverResponse!.data!) else {
        self.performSegue(withIdentifier: "goto-login", sender: nil)
        return
      }
      
      //Set the updated user as the logged in user.
      loggedInUser = updatedUser
      globalUserDefaults.set(updatedUser.toDict(), forKey: "logged-in-user")
    }
  }
}
