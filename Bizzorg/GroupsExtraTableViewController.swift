//
//  GroupsExtraTableViewController.swift
//  Bizzorg
//
//  Created by Jordan Field on 07/11/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import UIKit

/**
 View controller for the table view that can be called from a group detail view,
 which can show sub-groups, to-do items or schedule events.
 
 Properties
 ==========
 group - The group to retrieve the information for.
 mode - the type of information to retrieve.
 items - will be fileld with the response from the server.
 */
class GroupsExtraTableViewController: UITableViewController {
  
  enum Mode {
    case subGroups, toDoList, schedule
  }
  
  var group: EmployeeGroup?
  var mode: Mode = .subGroups
  var items: [Any] = []
  
  
  override func viewDidLoad() {
    //Check that the view has been initialised with a group.
    guard group != nil else {
      return
    }
    
    //Create a bizzorg api call.
    var call: BizzorgApiCall
    
    //Determine which information the user wants to retrieve, and set the call
    //to the appropriate request URL.
    switch mode {
    case .toDoList:
      title = "To-do items"
      call = BizzorgApiCall("todolist-items/?group=\(group!.id)", method: .GET)
    case .schedule:
      title = "Schedule events"
      call = BizzorgApiCall("schedule-items/?group=\(group!.id)", method: .GET)
    case .subGroups:
      title = "Sub-groups"
      call = BizzorgApiCall("employee-groups/?parent_group=\(group!.id)",
                            method: .GET)
    }
    
    //Send the call to the server and wait for a response.
    call.sendToServer(globalUrlSession) {
      //Check for any problems.
      guard call.responseValidated else {
        return
      }
      //Check that the server did respond with data.
      guard call.serverResponse?.data != nil else {
        return
      }
    
      //Determine the information in the response by checking the mode. This
      //works out what type to the supply to the polymophic 
      //responseObjectsToDataModels function. Once the response has been
      //processed, set the items variable to the list of models.
      switch self.mode {
      case .schedule:
        guard let scheduleItems: [ScheduleItem] =
          try? call.responseObjectsToDataModels() else {
          return
        }
        self.items = scheduleItems
      case .toDoList:
        guard let toDoItems: [ToDoListItem] =
          try? call.responseObjectsToDataModels() else {
          return
        }
        self.items = toDoItems
      case .subGroups:
        guard let subGroups: [EmployeeGroup] =
          try? call.responseObjectsToDataModels() else {
          return
        }
        self.items = subGroups
      }
      //Reload the table view with the new data.
      self.tableView.reloadData()
    }
    super.viewDidLoad()
  }
  
  //Function runs once view is displayed to the user. I use this function to fix
  //a small bug with cell selection.
  override func viewWillAppear(_ animated: Bool) {
    if let indexPath = self.tableView.indexPathForSelectedRow {
      self.tableView.deselectRow(at: indexPath, animated: true)
    }
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView,
                          numberOfRowsInSection section: Int) -> Int {
    return items.count
  }
  
  override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var cell: UITableViewCell
    //Determine what type of information is in the items list, then generate
    //the correct cells accordingly.
    switch mode {
    case .schedule:
      cell = tableView.dequeueReusableCell(withIdentifier: "schedule-item-cell")!
      let itemCell = cell as? ScheduleItemSummaryTableViewCell
      itemCell?.item = items[indexPath.row] as? ScheduleItem
    case .toDoList:
      cell = tableView.dequeueReusableCell(withIdentifier: "todolist-item-cell")!
      let itemCell = cell as? ToDoListItemSummaryTableViewCell
      itemCell?.item = items[indexPath.row] as? ToDoListItem
    case .subGroups:
      cell = tableView.dequeueReusableCell(withIdentifier: "group-summary")!
      let groupCell = cell as? GroupSummaryTableViewCell
      groupCell?.group = items[indexPath.row] as? EmployeeGroup
    }
    return cell
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch mode {
    //Once again, I must work out what type of information is currently being
    //displayed to the user, I do this using the mode variable. again.
    case .schedule:
      //Once we have determine the type of information, we can initialise the
      //correct detail table view for that data. and send the data on its way.
      let senderCell = sender as? ScheduleItemSummaryTableViewCell
      let destination = segue.destination as? ScheduleItemTableViewController
      destination?.item = senderCell?.item
    case .toDoList:
      let senderCell = sender as? ToDoListItemSummaryTableViewCell
      let destination = segue.destination as? ToDoItemTableViewController
      destination?.item = senderCell?.item
    case .subGroups:
      let senderCell = sender as? GroupSummaryTableViewCell
      let destination = segue.destination as? GroupViewController
      destination?.group = senderCell?.group
    }
  }
}
