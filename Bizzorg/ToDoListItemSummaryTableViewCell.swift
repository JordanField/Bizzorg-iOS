//
//  ToDoListItemSummaryTableViewCell.swift
//  Bizzorg
//
//  Created by Jordan Field on 16/09/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import UIKit

/*
 Code responsible for the cells in the 'To-do' tab of the app.
 
 UI Links
 ========
 itemNameLabel
 itemDeadlineLabel
 itemPriorityLabel
 
 Properties
 ==========
 item - the item this cell is displaying.
 */
class ToDoListItemSummaryTableViewCell: UITableViewCell {
 
  @IBOutlet weak var itemNameLabel: UILabel!
  @IBOutlet weak var itemDeadlineLabel: UILabel!
  @IBOutlet weak var itemPriorityLabel: UILabel!
  var item: ToDoListItem? {
    didSet {
      //Populate the UI with the right data from the item.
      itemNameLabel.text = item?.title
      itemPriorityLabel.text = item?.priority.prettyValue
      guard item?.deadlineDate != nil else {
        itemDeadlineLabel.text = "No deadline"
        return
      }
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "dd-mm-yyyy"
      itemDeadlineLabel.text = dateFormatter.string(from: item!.deadlineDate!)
    }
  }
}
