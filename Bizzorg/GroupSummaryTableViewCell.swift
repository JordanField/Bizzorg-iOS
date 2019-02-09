//
//  GroupSummaryTableViewCell.swift
//  Bizzorg
//
//  Created by Jordan Field on 26/05/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import UIKit

/*
 Class used for the cells in the 'My Groups' tab.
 
 UI links
 ========
 groupNameLabel
 groupMembersLabel
 
 Properties
 ==========
 group - the group that the details should be shown for.
*/
class GroupSummaryTableViewCell: UITableViewCell {
  @IBOutlet weak var groupNameLabel: UILabel!
  @IBOutlet weak var groupMembersLabel: UILabel!
  
  var group: EmployeeGroup? = nil {
    didSet {
      groupNameLabel.text = group?.name.capitalized
      guard group != nil else {
        return
      }
      //This line seems complicated, but all it's doing is creating a list of
      //the members' first names, then squeezing that list down back into a
      //string with a comma separator.
      groupMembersLabel.text =
        group!.membersWithoutAdminFlag.map {$0.firstName}.joined(separator: ", ")
    }
  }
}
