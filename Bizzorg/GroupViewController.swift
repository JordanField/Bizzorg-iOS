//
//  GroupViewController.swift
//  Bizzorg
//
//  Created by Jordan Field on 28/05/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import UIKit

/**
 View controller responsible for showing the details of a group.
 
 UI Links
 ========
 editBarButton
 tableView
 
 Properties
 ==========
 group - The group for this detail page.
 subGroups - initialy empty, this is used to determine whether the 'sub-groups'
 option is shown.
 */
class GroupViewController: UIViewController,
  UITableViewDelegate,
  UITableViewDataSource {
  
  @IBOutlet weak var editBarButton: UIBarButtonItem!
  @IBOutlet weak var tableView: UITableView!
  var group: EmployeeGroup?
  var subGroups: [EmployeeGroup] = []
  
  //There are two sections to the group detail table view, and this enum allows
  //me to easily discern betreen them.
  enum TableViewSection: Int {
    case members = 0, menuItems
  }
  
  //The enum for the three menu items
  enum MenuItem: Int {
    case subGroups = 0, toDo, schedule
  }
  
  //Retrieves the subGroups of this group from the server then calls to update
  //the table view, allowing the sub-groups button to be selected.
  func getSubGroups() {
    let call = BizzorgApiCall("employee-groups/?parent_group=\(group!.id)", method: .GET)
    call.sendToServer(globalUrlSession) {
      let response = call.serverResponse!
      guard response.validated else {
        return
      }
      self.subGroups = try! call.responseObjectsToDataModels()
      self.updateSubGroupSection()
    }
  }
  
  //Called when the edit button is pressed.
  @objc func editButtonPressed() {
    //Create the actions for an action sheet to present to the user.
    let actions: [(String, UIAlertActionStyle)] = [
      ("Edit group", .default),
      ("Create sub-group", .default),
      ("Cancel", .cancel)
    ]
    //Display the action sheet to the user and wait for a response.
    displayActionSheet(actions: actions, viewController: self) {
      action in
      switch action {
      case "Edit group":
        //If the user selected the "edit group" option, segue them into the
        //modify screen in edit mode.
        self.performSegue(withIdentifier: "edit-group", sender: self)
      case "Create sub-group":
        //If the user wants to add a sub-group, take them to the same
        //screen but with the subgroup mode activated instead.
        self.performSegue(withIdentifier: "add-subgroup", sender: self)
      default:
        return
      }
    }
  }
  
  //Called once the subgroups have been retrieved from the server.
  func updateSubGroupSection() {
    //Ensures the view controller is fully loaded.
    guard isViewLoaded else {
      return
    }
    //Updates the menu items section of the table view.
    executeUiChange {
      let indexPath = IndexPath(row: 0, section: 1)
      self.tableView.reloadRows(at: [indexPath], with: .fade)
    }
  }
  
  //The table view has two sections: employees and menu items.
  func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  
  //The members section has one row, while the menu item section has 3 (however
  //one can be hidden.)
  func tableView(_ tableView: UITableView,
                 numberOfRowsInSection section: Int) -> Int {
    switch TableViewSection(rawValue: section)! {
    case .members:
      return 1
    case .menuItems:
      return 3
    }
  }
  
  func tableView(_ tableView: UITableView,
                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    //Determine which section the cell being generated is in.
    switch TableViewSection(rawValue: indexPath.section)! {
    case .members:
      //If the cell is the members cell, generate an employees summary cell.
      let cell =
        tableView.dequeueReusableCell(withIdentifier:
          "group-members-summary-cell") as! EmployeesSummaryTableViewCell
      //Assign the cell's employees to the members of the group.
      cell.employees = group!.membersWithoutAdminFlag
      return cell
    case .menuItems:
      //Generate a group menu item cell.
      let cell =
        tableView.dequeueReusableCell(withIdentifier: "group-detail-menu-cell")
      //Then determine which cell is being generated, so we can put in the 
      //correct information.
      switch MenuItem(rawValue: indexPath.row)! {
      case .subGroups:
        //If the subgroups cell is being generated, we want to find out if the
        //group has any subgroups first.
        if subGroups.count == 0  {
          //If it doesn't have any sub-groups, hide the cell from view so it
          //can't be selected.
          cell?.isUserInteractionEnabled = false
          cell?.backgroundColor = UIColor.groupTableViewBackground
          cell?.isHidden = true
        }
        cell?.textLabel?.text = "Sub-groups (\(subGroups.count))"
      case .toDo:
        cell?.textLabel?.text = "To-Do list items"
      case .schedule:
        cell?.textLabel?.text = "Schedule items"
      }
      return cell!
    }
  }
  
  //We want to show the employee carousel at the correct height, so use the
  //heightForRowAt function to do this.
  func tableView(_ tableView: UITableView,
                 heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == TableViewSection.members.rawValue {
      return 130
    } else {
      tableView.estimatedRowHeight = 44
      return UITableViewAutomaticDimension
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    //Once the view loads, set the view title to the name of the group.
    title = group?.name.capitalized
    //The action of pressing the edit button has to be attached to a target
    //and pointed toward a subroutine that runs when the button is pressed.
    //I set the target to this view controller and the action to the
    //editButtonPressed subroutine.
    editBarButton.target = self
    editBarButton.action = #selector(GroupViewController.editButtonPressed)
    //Send the call to the server to retrieve the subgroups.
    getSubGroups()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    //Check that the group variable has actually been assigned to. If it hasn't,
    //immediately move back to the previous view controller to prevent errors.
    guard group != nil else {
      navigationController!.popViewController(animated: true)
      return
    }
  }
  
  //Small UI bug fixing code.
  override func viewWillAppear(_ animated: Bool) {
    if let indexPath = self.tableView.indexPathForSelectedRow {
      self.tableView.deselectRow(at: indexPath, animated: true)
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    guard segue.identifier != nil else {
      return
    }
    switch segue.identifier! {
      case "show-employee-details":
        let employeeCell = sender as! MemberCollectionViewCell
        let destination = segue.destination as! EmployeeDetailsTableViewController
        destination.employee = employeeCell.employee
      case "edit-group":
        /* 
         There are two instances here where a segue points to the same view
         controller. This is intentional, as the modify group view can both act
         as the view for creating groups, sub-groups and editing groups. All I
         have to do is change the mode of the view controller and supply the
         group to either edit or make a sub-group of.
        */
        let destination = segue.destination as! ModifyGroupTableViewController
        destination.mode = .editing
        destination.members = group!.members
        destination.group = group
      case "add-subgroup":
        let destination = segue.destination as! ModifyGroupTableViewController
        destination.mode = .subGroup
        destination.possibleMembers = group!.membersWithoutAdminFlag
        destination.group = group
      case "show-group-menu-item":
        /* 
         This segue preparation is a bit more complicated than most, since
         the groups extra view can show three different types of information.
         As such, I retrieve the text label of the cell the user selected then
         determine which cell was selected. Once I know what information the
         user wants I can set the mode of the view controller correctly, which
         will cause the next view to show the correct data. 
        */
        let destination = segue.destination as! GroupsExtraTableViewController
        destination.group = group
        let sender = sender as? UITableViewCell
        guard let name = sender?.textLabel?.text else {
          return
        }
        switch name {
          case "Sub-groups":
            destination.mode = .subGroups
          case "To-Do list items":
            destination.mode = .toDoList
          case "Schedule items":
            destination.mode = .schedule
        default: break
        }
    default: break
    }
  }
}
