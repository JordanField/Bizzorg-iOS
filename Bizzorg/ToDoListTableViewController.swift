//
//  ToDoListTableViewController.swift
//  Bizzorg
//
//  Created by Jordan Field on 17/03/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

/**
 Most TableViewControllers have very similar to identical setup. Therefore I
 will explain this TableViewController in detail, going over every function
 and descibing what it does. For every other TableViewController I will point to
 this file as an example of how it works, but will annotate any unique code that
 isnt included in all TableViewController files.

 */

import UIKit

/**
 The table view controller used to show the user a summary of all their to-do
 items.
 
 UI Links
 ========
 createTodoItemBarButton
 categorySegmentedControl
 
 Properties
 ==========
 allItems - After the response from the server is recieved, the data is
 converted into models and stored in this list.
 
 itemsAssignedToUser - A computed list that filters to-do items and returns only
 items the user has been assigned to
 
 itemsToShow - The tableView uses this list to display data, created by using
 the previous two lists, with a possible filtering based on the "show completed
 items" toggle switch.
 
 completedSwitch - The switch in the user interface for toggling completed 
 items.
 
 showCompleted - The actual boolean value that is used by the itemsToShow list
 to denote whether to filter the items or not. Toggled by the completedSwitch.
 */
class ToDoListTableViewController: UITableViewController {
  
  /**
   The IBOutlet identifier allows me to link objects from my Interface Builder
   file into my code and manipulate them.
  */
  @IBOutlet weak var createTodoItemBarButton: UIBarButtonItem!
  @IBOutlet weak var categorySegmentedControl: UISegmentedControl!
  
  var allItems: [ToDoListItem] = []
  
  var itemsAssignedToUser: [ToDoListItem] {
    //Filter allItems to show all items which contain the logged in user as one
    //of the assigned employees.
    return allItems.filter { (item) in
      item.assignedEmployees.contains { (employee) in
        employee.id == loggedInUser?.id
      }
    }
  }
  
  var itemsToShow: [ToDoListItem] {
    
    //Determines whether the itemsToShow should use all items or assigned items,
    //by looking at the selected segment on the segmented control.
    var basisList: [ToDoListItem] {
      if categorySegmentedControl.selectedSegmentIndex == 0 {
        return itemsAssignedToUser
      } else {
        return allItems
      }
    }
    
    //If the 'show completed items' toggle is on, return the unfiltered list, if
    //not, return only items that are not completed.
    if showCompleted {
      return basisList
    } else {
      return basisList.filter {(item) in item.completed == false}
    }
  }
  
  var completedSwitch: UISwitch? = nil
  var showCompleted = false
  
  enum TableViewSection: Int {
    //Used to discern sections by the tableview
    case completedToggle = 0, items
  }
  
  ///Called when the user toggles the segmented control.
  @objc func segmentChanged() {
    //Reload the data in the table view.
    tableView.reloadData()
  }
  
  /**
   TableViews are based on sections and cells, and I must tell iOS how many
   sections I want in each view. This table view has two sections. as such, the 
   function should return 2
   */
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  
  /**
   Once the sections have been determined, iOS now queries for how many cells
   are in each section. In this case, the completed toggle switch should only
   have one cell, and other sections should contain the number of cells
   corresponding to the count of the itemsToShow list.
   */
  override func tableView(_ tableView: UITableView,
                          numberOfRowsInSection section: Int) -> Int {
    switch TableViewSection(rawValue: section)! {
    case .completedToggle:
      return 1
    case .items:
      return itemsToShow.count
    }
  }
  
  //Called when the 'show completed' toggle is tapped.
  @objc func switchChanged() {
    //toggle the showCompleted variable.
    showCompleted.toggle()
    //reload the tableview to show the updated data.
    tableView.reloadData()
  }
  
  /**
   The number of sections in the tableView, and the cells in each section have
   now been determined, so iOS now queries for the contents of each cell. It
   does this by calling the cellForRowAt indexPath function, which needs to be
   overwritten by me in order to not produce blank cells.
   */
  override func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    //Check which section the cell that is being requested is in.
    guard
      TableViewSection(rawValue: indexPath.section)! != .completedToggle else {
        //If it is determined that the completed items switch is being 
        //generated, run through the procedure to generate this cell.
        //Retrieve the cell from the Interface builder file with the correct
        //identifi]er.
        let cell =
        tableView.dequeueReusableCell(withIdentifier: "completed-items-switch")!
        //set the label to the correct string.
        cell.textLabel?.text = "Show completed items"
        
        //Add the switch as the accessory view for the cell.
        cell.accessoryView = UISwitch()
        
        //Point the class variable completedSwitch to the newly created switch.
        completedSwitch = cell.accessoryView as? UISwitch
        
        //Set the switch to the correct state.
        completedSwitch!.isOn = showCompleted
        
        //Add a target which runs the switchChanged() function whenever the
        //switches value changes.
        completedSwitch!.addTarget(self, action: #selector(switchChanged),
                                   for: .valueChanged)
        return cell
    }
    
    //Retrieve the to-do item.
    let item = itemsToShow[indexPath.row]
    
    //Create a To-do summary cell with the correct identifier.
    let cell =
      tableView.dequeueReusableCell(withIdentifier: "todolist-item-cell")
        as? ToDoListItemSummaryTableViewCell
    
    //Set the cell's item to the current item. this will generate the correct
    //UI.
    cell?.item = item
    return cell!
  }
  
  /**
   Retrieves the correct To-do items from the server, runs a callback function
   when this is completed.
   */
  func getToDoListItems(_ callback: @escaping (Error?) -> Void) {
    //Check that there is a logged in user. if not, callback an error.
    guard loggedInUser != nil else {
      callback(LoginError.noLoggedInUser)
      return
    }
    
    //Create a call to retrieve the to-do items from the logged in user.
    let toDoListCall =
      BizzorgApiCall("todolist-items/?group__members=\(loggedInUser!.id)",
                     method: .GET)
    
    //Send the request to the server.
    toDoListCall.sendToServer(globalUrlSession) {
      //Ensure the response is validated. If not, callback the error.
      guard toDoListCall.responseValidated else {
        callback(toDoListCall.serverResponse?.error)
        return
      }
      
      do {
        //try to convert the server response into native data models, if this
        //fails, forward the error to the callback function.
        self.allItems = try toDoListCall.responseObjectsToDataModels()
      } catch {
        callback(error)
      }
      //If everything goes successfully, callback with nil to denote the process
      //completed with no errors.
      callback(nil)
    }
  }
  
  /**
   Since the cells in this view are different sizes, I need to tell iOS which
   cells are what heights. This function allows me to do this.
   */
  override func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
    //If the cell is a switch cell return a smaller height.
    if TableViewSection(rawValue: indexPath.section)! == .completedToggle {
      return 44
    } else {
      return 90
    }
  }
  
  /**
   The ViewDidLoad function is called when the view is loaded into memory, and
   is therefore the first code that is run by the view, I use this function to 
   prepare the view and make network calls.
   */
  override func viewDidLoad() {
    //Attach a funciton to the segmented control to trigger when it is changed.
    categorySegmentedControl.addTarget(self,
              action: #selector(ToDoListTableViewController.segmentChanged),
              for: .valueChanged)
    
    //Check there is a logged in user.
    guard loggedInUser != nil else {
      return
    }
    
    //If the user has groups they are administrating, enable the 'create item'
    //Button.
    createTodoItemBarButton.isEnabled = loggedInUser!.administrating.count > 0
    
    //Attempt to retrieve the To-do items from the server. Display any possible
    //errors to the user.
    getToDoListItems() { (error) in
      guard error == nil else {
        displayErrorMessage("\(error!)", viewController: self)
        return
      }
      //If there are no errors, update the table with the newly retrived data.
      executeUiChange {self.tableView.reloadData()}
    }
  }
  
  //Function runs once view is displayed to the user. I use this function to fix
  //a small bug with cell selection.
  override func viewWillAppear(_ animated: Bool) {
    if let indexPath = self.tableView.indexPathForSelectedRow {
      self.tableView.deselectRow(at: indexPath, animated: true)
    }
  }
  
  /**
   The prepare function is incredibly important, as it coordinates the passage
   of information from one screen to another (known in iOS as a 'segue'). 
   Many segues in my app require the passing of info from one screen to another.
   This is done by initialising the destination view as one of my coded view
   controllers which contain specific instance variables and changing that
   instance variable before the screen is displayed, in this case. I need to
   pass the To-do item to the to-do item detail view.
   */
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //In order to prevent unwanted screen changes. each segue has a specific
    //identifier string, and if a segue without an identfier is invoked no
    //data is sent. This increases the robustness of my app and prevents 
    //chrases.
    switch segue.identifier! {
    case "todo-item-detail":
      //Assign the cell the user tapped as the constant itemCell.
      let itemCell = sender as? ToDoListItemSummaryTableViewCell
      
      //Assign the destination view controller as the constant destination with
      //the correct type, ToDoItemTableViewController.
      let destination = segue.destination as! ToDoItemTableViewController
      
      //Set the destination instance variable item to the To-do item for the
      //cell the user tapped.
      destination.item = itemCell!.item
    default: break
    }
    //Once all these processes have completed, iOS will display the next view
    //controller.
  }
}
