//
//  ToDoItemTableViewController.swift
//  Bizzorg
//
//  Created by Jordan Field on 18/09/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import UIKit

/**
 View controller responsible for the showing of a To-do item and the details of
 it
 
 Properties
 ==========
 item - The item to show the details of.
 */
class ToDoItemTableViewController: UITableViewController {
  var item: ToDoListItem?
  internal let dateFormatter = DateFormatter()
  
  //The To-do Detail view is divided into distinct sections, so to decrease
  //confusion I associate the section number with its purpose in this enum.
  enum TableViewSection: Int {
    case details = 0, employees, description, options
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    //Set the title of the screen to the title of the item.
    title = item?.title
    //Get the group for this specific item.
    item?.getGroup {
      //Once the group is found, reload the table.
      executeUiChange {self.tableView.reloadData()}
    }
    //Give the date formatter the correct format.
    dateFormatter.setLocalizedDateFormatFromTemplate("EdMMM")
  }
  
  override func viewWillAppear(_ animated: Bool) {
    if let indexPath = self.tableView.indexPathForSelectedRow {
      self.tableView.deselectRow(at: indexPath, animated: true)
    }
  }
  
  /**
   The view has four sections: details, employees, descriptions and options.
  */
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 4
  }
  
  override func tableView(_ tableView: UITableView,
                          numberOfRowsInSection section: Int) -> Int {
    //Make an instance of TableViewSection with the section integer given.
    switch TableViewSection(rawValue: section)! {
    case .details:
      return 4
    case .employees:
      //If the item has assigned employees, show the employee carousel. if not,
      //hide it.
      return item!.assignedEmployees.count > 0 ? 1 : 0
    case .description:
      return 1
    case .options:
      return 1
    }
  }
  
  override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    //Determine which section the cell is in.
    switch TableViewSection(rawValue: indexPath.section)! {
    case .details:
      /*
       The details section has 4 cells: priority, group, deadline and completed.
      */
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
        //If the group has been retrieved, allow this cell to be tapped to take
        //the user to the group detail screen.
        if item?.group != nil {
          cell.isUserInteractionEnabled = true
        }
      case 2:
        cell.textLabel?.text = "Deadline"
        //If there is a deadline date, use the formatter to convert it into a
        //String. if not, show "No deadline".
        if let deadline = item?.deadlineDate {
          cell.detailTextLabel?.text = dateFormatter.string(from: deadline)
        } else {
          cell.detailTextLabel?.text = "No deadline"
        }
      case 3:
        //Changes the completed text to "Completed" or "Not completed" 
        //respectfully.
        cell.detailTextLabel?.text = "\(item!.completed ? "C" : "Not c")ompleted"
        cell.textLabel?.text = ""
      default: break
      }
      return cell
    case .employees:
      /*
       The employees summary table view cell is one of the more complex table
       view cells alongside the date and item picker cells. Luckily initiating
       it is easy. just create a new instance of the cell and assign the
       employees into the instances variable "employees"
      */
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
      /*
       It seemed superfluous to create a bespoke view cell class for each
       cell, so in this and the next instance I use tags which can be used to
       refer to a specific UI object directly. In this case, I'm selecting the
       text view that shows the to-do item description.
       */
      let textField = cell.viewWithTag(15) as! UITextView
      textField.text = item?.description!
      return cell
    case .options:
      let cell = tableView.dequeueReusableCell(withIdentifier: "options-cell")!
      //And in this case I'm retrieving the label so I can change the text of it.
      let textLabel = cell.viewWithTag(16) as! UILabel
      textLabel.text = "Toggle completed"
      return cell
    }
  }
  
  override func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
    //The employees summary cell has a larger height than all the other cells,
    //So I need to tell the table view when it is dealing with this cell so
    //it can give it the correct height.
    switch TableViewSection(rawValue: indexPath.section)! {
    case .employees: return 130
    case .details, .options, .description:
      tableView.estimatedRowHeight = 44
      return UITableViewAutomaticDimension
    }
  }
  
  //Called when the user taps the "toggle completed" button in the UI.
  func toggleCompletedTask() {
    let call = BizzorgApiCall("todolist-items/\(item!.id)/", method: .PATCH)
    call.apiData = [
      //set the completed flag to the opposite of what it is now.
      "completed": !item!.completed
    ]
    call.sendToServer(globalUrlSession) {
      guard call.responseValidated else {
        displayErrorMessage("Network error.", viewController: self)
        return
      }
      //If everything goes through without any errors, pop the view controller
      //to demonstrate to the user the process has completed.
      executeUiChange {
        self.navigationController!.popViewController(animated: true)
      }
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier! {
    case "employee-details":
      let sender = sender as? MemberCollectionViewCell
      let destination = segue.destination as? EmployeeDetailsTableViewController
      destination?.employee = sender?.employee
    case "show-group-for-item":
      let destination = segue.destination as? GroupViewController
      destination?.group = item?.group
    case "edit-todo-item":
      let destination = segue.destination as? ModifyToDoItemTableViewController
      destination?.item = item
    default: break
    }
  }
  
  //Since there is only one button that can cause anything other than a segue
  //this function is rather short.
  override func tableView(_ tableView: UITableView,
                          didSelectRowAt indexPath: IndexPath) {
    switch TableViewSection(rawValue: indexPath.section)! {
    case .options:
      //If the "toggle completed" button is pressed, initiate the toggle
      //completed function.
      toggleCompletedTask()
    default: break
    }
  }
}
