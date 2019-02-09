//
//  ScheduleItemTableViewController.swift
//  Bizzorg
//
//  Created by Jordan Field on 22/09/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import UIKit

/*
 You may have noticed a trend in that the view controllers for to-do items and
 schedule events are pretty much the same. This is true for the detail views
 as well, only having minor differences. Because of this, the vast majority of
 annotation is on the other file, ToDoItemTableViewController.swift
 */

/**
 The view controller for showing the details of a schedule event
 
 Properties
 ==========
 item - the item to show the details of.
 */
class ScheduleItemTableViewController: UITableViewController {
  var item: ScheduleItem?
  internal let dateFormatter = DateFormatter()
  
  //Identical to ToDoItemTableViewController.
  enum TableViewSection: Int {
    case details = 0, employees, description, options
  }
  
  //Identical to ToDoItemTableViewController, apart from the date formatter,
  //which uses a format that displays the time as well as the date.
  override func viewDidLoad() {
    super.viewDidLoad()
    dateFormatter.setLocalizedDateFormatFromTemplate("EdMMMhhmm")
    title = item?.title
    item?.getGroup {
      executeUiChange {self.tableView.reloadData()}
    }
  }

  //Identical to ToDoItemTableViewController.
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 4
  }
  
  //Identical to ToDoItemTableViewController.
  override func tableView(_ tableView: UITableView,
                          numberOfRowsInSection section: Int) -> Int {
    switch TableViewSection(rawValue: section)! {
    case .details:
      return 4
    case .employees:
      return item!.assignedEmployees.count > 0 ? 1 : 0
    case .description:
      return 1
    case .options:
      return 1
    }
  }
  
  //Mostly identical to ToDoItemTableViewController.
  override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch TableViewSection(rawValue: indexPath.section)! {
    case .details:
      let cell =
        tableView.dequeueReusableCell(withIdentifier: "item-information-cell")!
      switch indexPath.row {
      case 0:
        cell.textLabel?.text = "Priority"
        cell.detailTextLabel?.text = item?.priority.prettyValue
      case 1:
        cell.textLabel?.text = "Group"
        cell.detailTextLabel?.text = item?.group?.name.capitalized
        cell.accessoryType = .disclosureIndicator
        if item?.group != nil {
          cell.isUserInteractionEnabled = true
        }
      case 2:
        //The schedule item has a start and an end date and time, so they are
        //shown in seperate cells.
        cell.textLabel?.text = "Start"
        cell.detailTextLabel?.text = dateFormatter.string(from: item!.startDate)
      case 3:
        cell.textLabel?.text = "End"
        cell.detailTextLabel?.text = dateFormatter.string(from: item!.endDate)
      default: break
      }
      return cell
    case .employees:
      let cell =
        tableView.dequeueReusableCell(withIdentifier:
          "assigned-employees-summary-cell") as! EmployeesSummaryTableViewCell
      if item?.assignedEmployees != nil {
        cell.employees = item!.assignedEmployees
      }
      return cell
    case .description:
      let cell =
        tableView.dequeueReusableCell(withIdentifier: "item-description-cell")!
      let textField = cell.viewWithTag(15) as! UITextView
      textField.text = item?.description!
      return cell
    case .options:
      let cell = tableView.dequeueReusableCell(withIdentifier: "options-cell")!
      let textLabel = cell.viewWithTag(16) as! UILabel
      textLabel.text = "Mark as finished"
      return cell
    }
  }
  
  //Identical to ToDoItemTableViewController.
  override func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
    switch TableViewSection(rawValue: indexPath.section)! {
    case .employees: return 130
    case .details, .options, .description:
      tableView.estimatedRowHeight = 44
      return UITableViewAutomaticDimension
    }
  }
  
  //Identical to ToDoItemTableViewController.
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier! {
    case "employee-details":
      let sender = sender as? MemberCollectionViewCell
      let destination = segue.destination as? EmployeeDetailsTableViewController
      destination?.employee = sender?.employee
    case "show-group-for-item":
      let destination = segue.destination as? GroupViewController
      destination?.group = item?.group
    case "edit-schedule-item":
      let destination = segue.destination as?
        ModifyScheduleItemTableViewController
      destination?.item = item
    default: break
    }
  }
}
