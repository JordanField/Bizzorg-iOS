//
//  EmployeeDetailsTableViewController.swift
//  Bizzorg
//
//  Created by Jordan Field on 06/09/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import UIKit

/**
 A very simple view controller that is used to display the detials of an
 employee when their profile picture is tapped in a group detail view, for
 example.
 
 UI links
 ========
 profilePictureView
 nameLabel
 jobPositionLabel
 emailLabel
 
 Properties
 ==========
 employee - The employee object that the details should be shown for.
 */
class EmployeeDetailsTableViewController: UITableViewController {

  @IBOutlet weak var profilePictureView: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var jobPositionLabel: UILabel!
  @IBOutlet weak var emailLabel: UILabel!
  var employee: Employee? = nil
  
  
  //On view appearing
  override func viewWillAppear(_ animated: Bool) {
    //Only update the profile picture view if there is a profile picture. If
    //there isn't, use the default profile picture.
    if employee?.profilePicture != nil {
      profilePictureView.image = employee?.profilePicture
    }
    profilePictureView.makeCircle()
    nameLabel.text = employee?.fullName
    jobPositionLabel.text = employee?.jobPosition
    emailLabel.text = employee?.email
  }
}
