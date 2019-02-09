//
//  DatePickerTableViewCell.swift
//  Bizzorg
//
//  Created by Jordan Field on 24/09/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import UIKit

/**
 Used in the modify to-do and schedule item classes to select dates and times.
 
 UI links
 ========
 datePicker
 
 Properties
 ==========
 updateDelegate - The cell calls specific functions on this object once the user
 has selected a date using the picker.
 mode - used by the modify schedule item table view to discern between start
 times and end times, if the value is set, I know that the user wants to see
 time as well as date, so I can change the mode of the date picker.
 */
class DatePickerTableViewCell: UITableViewCell {
  
  var updateDelegate: DatePickerTableViewCellDelegate?
  @IBOutlet weak var datePicker: UIDatePicker!
  var mode: Mode? = nil {
    willSet {
      //Check that the new value is not nil, if it is, the user only wants to 
      //select the date and not time, so set the appropriate picker mode.
      guard newValue != nil else {
        datePicker.datePickerMode = .date
        return
      }
      //If the value is not nil, the user wants to pick date and time.
      datePicker.datePickerMode = .dateAndTime
    }
  }
  
  enum Mode {
    case start, end
  }
  
  //Once the user selects a date, call on the update delegate so any nessecary
  //changes can be made.
  @IBAction func didSelectDate(_ sender: UIDatePicker) {
    updateDelegate?.datePickerViewDidSelect(datePicker, cell: self)
  }
}
