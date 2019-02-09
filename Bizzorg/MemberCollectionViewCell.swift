//
//  MemberCollectionViewCell.swift
//  Bizzorg
//
//  Created by Jordan Field on 30/05/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import UIKit

/**
 The EmployeesSummaryTableViewCell is actually a collection view within a 
 table view cell, which allows for the scrolling through of the members. This
 means that the cells in side the summary cell also have to be defined, and this
 is the cell that the summary cell uses.
 
 UI Links
 ========
 profilePicture
 nameLabel
 
 Properties
 ==========
 employee - The employee for this collection view cell.
 */
class MemberCollectionViewCell: UICollectionViewCell {
  @IBOutlet weak var profilePictureView: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  
  var employee: Employee? {
    didSet {
      //Once the employee for this cell is set, start to populate the cell with
      //information
      nameLabel.text = employee?.fullName
      //If the user doesn't have a profile picture, use the default picture
      //instead.
      guard employee?.profilePictureUri != nil else {
        profilePictureView.image = #imageLiteral(resourceName: "defaultProfilePicture")
        return
      }
      
      //If the user does have a profile picture, however, we need to retrieve it
      //from the server.
      employee?.getProfilePicture(globalUrlSession) {
        //Once the picture has been recieved update the image view with the new 
        //picture.
        self.profilePictureView.updateImage(self.employee?.profilePicture)
      }
    }
  }
  
  override func awakeFromNib() {
    profilePictureView.makeCircle()
  }
}
