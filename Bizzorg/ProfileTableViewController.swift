//
//  ProfileTableViewController.swift
//  Bizzorg
//
//  Created by Jordan Field on 04/05/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import UIKit

/**
 View controller responsible for the "Profile" tab in the app.
 
 UI links
 ========
 nameLabel
 jobLabel
 emailLabel
 profilePicture
 logOutActivityIndicator
 
 Properties
 ==========
 imagePicker - Initiated when the user wants to change their profile picture.
 */
class ProfileTableViewController: UITableViewController,
  UIImagePickerControllerDelegate,
  UINavigationControllerDelegate {
  
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var jobLabel: UILabel!
  @IBOutlet weak var emailLabel: UILabel!
  @IBOutlet weak var profilePicture: UIImageView!
  @IBOutlet weak var logOutActivityIndicator: UIActivityIndicatorView!
  let imagePicker = UIImagePickerController()
  
  /**
   The iOS ImagePickerController calls this function on its delegate object when
   the user selects an image. As such, I need to take the selected image,
   compress it, then use the updateProfilePicture function to change the image
   on the server.
   */
  func imagePickerController(_ picker: UIImagePickerController,
                         didFinishPickingMediaWithInfo info: [String : Any]) {
    
    //Check the selected image actually exists can be used for compression, if
    //not, return immediately to prevent crashes.
    guard let imageToSend =
      info[UIImagePickerControllerEditedImage] as? UIImage else {
      return
    }
    
    //Dissmiss the image picker, since the user doesn't need to see it anymore.
    executeUiChange {
      self.dismiss(animated: true, completion: nil)
    }
    
    //Send the new mage to the updateProfilePicture method for the logged in
    //user. see Data and Networking/Data Models/Employee.swift for more details.
    loggedInUser?.updateProfilePicture(globalUrlSession,
                                       newPicture: imageToSend) {
        (error) in
        //Check that the process completed successfully. if not, show an error
        //message to the user.
        guard error == nil else {
        self.dismiss(animated: true) {
          //Since the view was just dismissed, the error must be displayed on
          //the still present navigation controller.
          displayErrorMessage("Image upload failed.",
                              viewController: self.navigationController!)
        }
        return
      }
      //Since the user's details may have just changed, resave the profile
      //of the logged in user back into the database.
      globalUserDefaults.set(loggedInUser?.toDict(), forKey: "logged-in-user")
      self.profilePicture.updateImage(imageToSend)
    }
  }
  
  /**
   Called once the user selects an option on the second action sheet.

   - parameter action: The button the user tapped.
  */
  func imagePickerAlertHandler(_ action: String) {
    //Allow the user to resize and scale the picture once they've selected it.
    imagePicker.allowsEditing = true
    
    //Determine which action the user tapped.
    switch action {
    case "Choose photo":
      //If the user wishes to choose a photo already taken, switch the image
      //picker to photo library mode.
      imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
    case "Take photo":
      //If the user wants to take a new photo, switch the image picker into
      //camera mode.
      imagePicker.sourceType = UIImagePickerControllerSourceType.camera
    default:
      //Fallback on photo library mode by default.
      imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
    }
    //Present the prepared image picker to the user.
    executeUiChange {
      self.present(self.imagePicker, animated: true, completion: nil)
    }
  }
  
  //Called once the user selects an option from the first action sheet.
  func editAlertViewHandler(_ action: String) {
    //Determine the action the user has selected. Since there is only one
    //non-cancellation action I do not have to code any cancellation action; I
    //can let the default action do that.
    switch action {
    case "Change profile picture":
      //I need to create another action sheet to determine whether the user
      //wants to select an existing picture or take a new one, so create the
      //actions for this new action sheet
      let actions: [(String, UIAlertActionStyle)] = [
        ("Take photo", .default),
        ("Choose photo", .default),
        ("Cancel", .cancel)
      ]
      
      //Display the action sheet, using imagePickerAlertHandler as the callback.
      displayActionSheet(actions: actions, viewController: self,
                         callback: imagePickerAlertHandler)
    default: break
    }
  }
  
  //Called once the user selections an option on the alert asking them if they
  //are sure they want to log out.
  func logOutAlertHandler(_ action: String) {
    switch action {
    case "Log out":
      //If the user selects they want to log out, we need to make a request to
      //the server to cancel the session they are using. this is done using the
      //attemptLogOut function.
      attemptLogOut(globalUrlSession) {
        (error) in
        //Check that the process completed with no errors, if not, display an
        //error to the user telling them they have not been logged out.
        guard error == nil else {
          displayErrorMessage("Log out failed", viewController: self)
          return
        }
        //If the process completes, present the log in screen.
        executeUiChange {
          self.performSegue(withIdentifier: "user-logged-out", sender: nil)
        }
      }
    default: break
    }
  }
  
  override func viewDidLoad() {
    //Set the image picker delegate to this view controller, so that it calls
    //functions on itself.
    imagePicker.delegate = self
    
    //Retrieve the user's profile picture from the server.
    loggedInUser!.getProfilePicture(globalUrlSession) {
      //If the user has no profile picture, do not update the image view,
      //instead use the default profile picture
      guard loggedInUser?.profilePicture != nil else {
        return
      }
      
      //Update the profile picture image view with the new picture.
      self.profilePicture.updateImage(loggedInUser!.profilePicture!)
    }

    //Set the relevant UI labels to their proper values.
    self.nameLabel.text = "\(loggedInUser!.firstName) \(loggedInUser!.surname)"
    self.jobLabel.text = "\(loggedInUser!.jobPosition)"
    self.emailLabel.text = "\(loggedInUser!.email)"
  }

  //Convert the image view of the profile picture from square to circle when
  //the view appears.
  override func viewWillAppear(_ animated: Bool) {
    profilePicture.makeCircle()
  }
  
  /*
   The didSelectRowAtIndexPath function is called whenever the user taps a cell
   in a table view. In some instances I can automate the selection process
   by using seque triggers, but for many instances I have to manually handcode
   what happens when the user selects a cell.
   */
  override func tableView(_ tableView: UITableView,
                          didSelectRowAt indexPath: IndexPath) {
    //Determine the cell the user tapped.
    switch indexPath.row {
    //Row 0 corresponds to the 'Edit profile' button in the UI.
    case 0:
      //Create action sheet actions for display.
      let actions: [(String, UIAlertActionStyle)] = [
        ("Change profile picture", .default),
        ("Cancel", .cancel)
      ]
      //Display the action sheet, using editAlertViewHandler as the callback,
      displayActionSheet(actions: actions, viewController: self,
                         callback: editAlertViewHandler)
    //Row 1 corresponds to the 'log out' button.
    case 1:
      //Create the options for the 'log out' alert view.
      let actions: [(String, UIAlertActionStyle)] = [
        ("Log out", .destructive),
        ("Cancel", .cancel)
      ]
      //Display it to the user.
      displayAlert(message: "Are you sure?", actions: actions,
                   viewController: self, callback: logOutAlertHandler)
    default:
      break
    }
    //Deselect the row after it is tapped, which improves user experience.
    tableView.deselectRow(at: indexPath, animated: true)
  }
}
