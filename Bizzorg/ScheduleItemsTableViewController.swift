//
//  ScheduleItemsTableViewController.swift
//  Bizzorg
//
//  Created by Jordan Field on 21/09/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import UIKit

/**
 The table view controller used to show the user a summary of all their schedule
 items. This table view controller is almost identical to 
 ToDoListTableViewController, so annotation is sparse. See that class for a 
 detailed explanation as to what these functions do.

 UI Links
 ========
 createScheduleItemBarButton
 categorySegmentedControl
 
 Properties
 ==========
 allItems - After the response from the server is recieved, the data is
 converted into models and stored in this list.
 
 itemsAssignedToUser - A computed list that filters schedule events and returns 
 only items the user has been assigned to
 
 itemsToShow - The tableView uses this list to display data, created by using
 the previous two lists with the segmented control choosing between them
 */
class ScheduleItemsTableViewController: UITableViewController {
  
  @IBOutlet weak var categorySegmentedControl: UISegmentedControl!
  @IBOutlet weak var createScheduleItemBarButton: UIBarButtonItem!

  var allItems: [ScheduleItem] = []
  var itemsAssignedToUser: [ScheduleItem] {
    //Filter allItems to show all items which contain the logged in user as one
    //of the assigned employees.
    return allItems.filter { (item) in
      item.assignedEmployees.contains { (employee) in
        employee.id == loggedInUser?.id
      }
    }
  }
  
  var itemsToShow: [ScheduleItem] {
    //Determines whether the itemsToShow should use all items or assigned items,
    //by looking at the selected segment on the segmented control.
      if categorySegmentedControl.selectedSegmentIndex == 0 {
        return itemsAssignedToUser
      } else {
        return allItems
      }
  }
  
  ///Called when the user toggles the segmented control.
  @objc func segmentChanged() {
    //Reload the data in the table view.
    tableView.reloadData()
  }
  
  //See ToDoListTableViewController for detailed explanation.
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  //See ToDoListTableViewController for detailed explanation.
  override func tableView(_ tableView: UITableView,
                          numberOfRowsInSection section: Int) -> Int {
    return itemsToShow.count
  }
  
  //See ToDoListTableViewController for detailed explanation.
  override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let item = itemsToShow[indexPath.row]
    //Creating a schedule cell summary instead of a to-do item summary cell
    let cell =
      tableView.dequeueReusableCell(withIdentifier: "schedule-item-cell")
        as? ScheduleItemSummaryTableViewCell
    cell?.item = item
    return cell!
  }
  
  ///Identical to getToDoitems() in ToDoListTableViewController, but using
  ///schedule items instead.
  func getScheduleItems(_ callback: @escaping (Error?) -> Void) {
    guard loggedInUser != nil else {
      callback(LoginError.noLoggedInUser)
      return
    }
    
    let scheduleCall =
      BizzorgApiCall("schedule-items/?group__members=\(loggedInUser!.id)",
                     method: .GET)
    scheduleCall.sendToServer(globalUrlSession) {
      let response = scheduleCall.serverResponse!
      guard response.validated else {
        callback(response.error)
        return
      }
      do {
        self.allItems = try scheduleCall.responseObjectsToDataModels()
      } catch {
        callback(error)
      }
      callback(nil)
    }
  }
  
  ///Identical to ToDoLsitTableViewController.
  override func viewDidLoad() {
    categorySegmentedControl.addTarget(self,
            action: #selector(ScheduleItemsTableViewController.segmentChanged),
            for: .valueChanged)
    guard loggedInUser != nil else {
      return
    }
    createScheduleItemBarButton.isEnabled = loggedInUser!.administrating.count > 0
    getScheduleItems() {
      (error) in
      guard error == nil else {
        displayErrorMessage("\(String(describing: error))", viewController: self)
        return
      }
      executeUiChange {
        self.tableView.reloadData()
      }
    }
  }
  
  ///Identical to ToDoLsitTableViewController.
  override func viewWillAppear(_ animated: Bool) {
    if let indexPath = self.tableView.indexPathForSelectedRow {
      self.tableView.deselectRow(at: indexPath, animated: true)
    }
  }
  
  ///Identical to ToDoLsitTableViewController.
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier! {
    case "schedule-item-detail":
      let itemCell = sender as? ScheduleItemSummaryTableViewCell
      let destination = segue.destination as! ScheduleItemTableViewController
      destination.item = itemCell!.item
    default: break
    }
  }
}
