//
//  ScheduleItemSummaryTableViewCell.swift
//  Bizzorg
//
//  Created by Jordan Field on 21/09/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import UIKit

/**
 The structure code for the table view cells found in the "Schedule" section of
 the app. To populate with the correct data, initialise a cell object, then
 assign the schedule item to the 'item variable.
 
 UI Links
 ========
 titleLabel
 dateTimeLabel
 PriorityLabel
 
 Properties
 ==========
 item - as soon as the item property is set, it populates the three UI hooks
 with the correct data.
 */
class ScheduleItemSummaryTableViewCell: UITableViewCell {
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var dateTimeLabel: UILabel!
  @IBOutlet weak var priorityLabel: UILabel!
  var item: ScheduleItem? {
    didSet {
      //ensure the item is not nil, if it is, return without populating the UI.
      guard item != nil else {
        return
      }
      //Set the titleLabel text to the item title text
      titleLabel.text = item?.title
      
      //Set the priority label text to the priority priority pretty value.
      priorityLabel.text = item?.priority.prettyValue
      
      //Create a date formatter to convert the native Swift date to a string.
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "dd-MM-yyyy | HH:mm"
      
      //Set the date/time label to the formatted date string.
      dateTimeLabel.text = "\(dateFormatter.string(from: item!.startDate))"
    }
  }
}
