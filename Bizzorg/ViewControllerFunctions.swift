//
//  ViewControllerFunctions.swift
//  Bizzorg
//
//  Created by Jordan Field on 08/09/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import Foundation
import UIKit

/**
 Presents an error message to the user.
 
 - parameter message: The main error message that will be displayed.
 - parameter title: An optional title for the message.
 - parameter viewController: The view controller which the function should push
 the error message on top of.
 */
func displayErrorMessage(_ message: String, title: String? = nil,
                         viewController: UIViewController) {
  //Create the alert controller with the correct title and message.
  let errorMessage =
    UIAlertController(title: title, message: message, preferredStyle: .alert)
  
  //Add the dissmiss button.
  errorMessage.addAction(
    UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
  )
  
  //Present the alert on the passed view controller.
  executeUiChange {
    viewController.present(errorMessage, animated: true, completion: nil)
  }
}

/**
 Displays an optional title and message along with a list of options that rise
 from the bottom of the screen.
 
 - parameter title: The optional title of the action sheet.
 - parameter message: the optional supplementary message of the action sheet.
 - parameter actions: a list of tuples containing actions and an instruction
 on how they should be presented on the action sheet (e.g. destructive actions
 will show as red.)
 - parameter callback: a function that is called when a user selects an item.
 */
func displayActionSheet(_ title: String? = nil,
                        message: String? = nil,
                        actions: [(String, UIAlertActionStyle)],
                        viewController: UIViewController,
                        callback: @escaping (String) -> Void) {
  
  //This function is called once the user has selected an action. all it does is
  //pass the string of the action selected to the line that called this 
  //function.
  func callbackAction(_ action: UIAlertAction) {
    callback(action.title!)
  }
  
  //Create the action sheet with the title and message.
  let actionSheet =
    UIAlertController(title: title, message: message,
                      preferredStyle: .actionSheet)
  
  //For each action in the actions list:
  for (title, style) in actions {
    //Add it to the newly created action sheet, with the callbackAction function
    //as the completion handler.
    actionSheet.addAction(UIAlertAction(title: title, style: style,
                                        handler: callbackAction))
  }
  
  //Present the action sheet on the viewcontroller passed to the function.
  viewController.present(actionSheet, animated: true, completion: nil)
}

/**
 Identical to the displayActionSheet function above, but showing as an alert
 instead of an action sheet.
 */
func displayAlert(title: String? = nil,
                  message: String? = nil,
                  actions: [(String, UIAlertActionStyle)],
                  viewController: UIViewController,
                  callback: @escaping (String) -> Void) {
  
  func callbackAction(_ action: UIAlertAction) {
    callback(action.title!)
  }
  
  let alert = UIAlertController(title: title, message: message,
                                preferredStyle: .alert)
  for (title, style) in actions {
    alert.addAction(UIAlertAction(title: title, style: style,
                                  handler: callbackAction))
  }
  viewController.present(alert, animated: true, completion: nil)
}
