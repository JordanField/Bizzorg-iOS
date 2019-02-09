//
//  ModifyGroupTableViewController.swift
//  Bizzorg
//
//  Created by Jordan Field on 11/06/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import UIKit

/**
 The class responsible for editing and creating groups.
 
 Properties
 ==========
 mode - The current usage mode the view is in.
 name - The name of the group.
 possibleMembers - The list of members that can be added to this group.
 members - the list of currently selected members, along with a boolean flag
 denoting whether the user is an admin or not.
 group - an optional value, used when the user is editing a group or making a
 sub-group
 nameTextField - Used to assign the name cell text field to a class variable so
 that the text can be extracted.
 */
class ModifyGroupTableViewController:
  UITableViewController,
  UITextFieldDelegate {

  var mode: EditMode = .baseGroup
  var name: String?
  var possibleMembers: [Employee] = []
  var members: [(admin: Bool, employee: Employee)] = []
  var group: EmployeeGroup?
  var nameTextField: UITextField?
  
  //An enum to discern between the four section of the table view.
  enum TableViewSection: Int {
    case name = 0, members, admins, submit
  }
  
  //An enum of the three possible editing modes for the view.
  enum EditMode {
    case baseGroup, editing, subGroup
  }

  //Generates the KeyValuePairs dictionary from the entered data, so it can be
  //sent to the server.
  func generateFormData() -> KeyValuePairs? {
    //Check that a name has been set. If not, return nil to denote the process
    //failed.
    guard name != nil else {
      return nil
    }
    
    //If the view is in subgroup mode, set the parent to the group class 
    //variable.
    var parent: EmployeeGroup?
    if mode == .subGroup {
      parent = group
    }
    
    //Create the formData dictionarty and add the name.
    var formData: KeyValuePairs = ["name": name!]
    
    //Add the parent group, if one exists.
    if parent != nil {
      formData["parent_group"] = parent!.resourceUri.relativeString
    }
    
    //Create an array of all resource URIs of all the members of the group.
    let memberUris = members.map {(_ ,employee) in employee.resourceUri.relativeString}
    
    //For the admin URIs, first filter the members list, removing all members
    //that aren't admins, then map the resource URIs to the list.
    let adminUris = members.filter {(admin, _) in admin}.map
        {(_, employee) in employee.resourceUri.relativeString}
    
    //Add the member and admin lists.
    formData["members"] = memberUris as AnyObject?
    formData["admins"] = adminUris as AnyObject?
    return formData
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 4
  }
  
  //Each section in this view has a specific title, and the 
  //titleForHeaderInSection function lets me define those headers.
  override func tableView(_ tableView: UITableView,
                          titleForHeaderInSection section: Int) -> String? {
    switch TableViewSection(rawValue: section)! {
    case .name:
      return "Group Name"
    case .members:
      return "Members"
    case .admins:
      return "Group Administators"
    case .submit:
      return nil
    }
  }
  
  override func tableView(_ tableView: UITableView,
                          numberOfRowsInSection section: Int) -> Int {
    switch TableViewSection(rawValue: section)! {
    case .name:
      return 1
    case .members:
      return possibleMembers.count
    case .admins:
      return members.count
    case .submit:
      return 1
    }
  }
  
  //As ModifyToDoListItemTableViewController.
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
  
  //Once the user finishes editing the name field, set the name variable to the
  //text in the field.
  func textFieldDidEndEditing(_ textField: UITextField) {
    name = textField.text
  }
  
  //As ModifyToDoListItemTableViewController
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    tableView.endEditing(false)
    super.touchesBegan(touches, with: event)
  }
  
  //As ModifyToDoListItemTableViewController.
  func retrieveEmployeeSelectionCell(_ employee: Employee,
                                     checkmark: Bool) -> UITableViewCell {
    let cell =
      tableView.dequeueReusableCell(withIdentifier: "employee-selection-cell")!
    cell.textLabel?.text = employee.fullName
    cell.detailTextLabel?.text = employee.jobPosition
    if employee.profilePicture != nil {
      cell.imageView?.image = employee.profilePicture!
    } else {
      cell.imageView?.image = defaultProfilePicture
    }
    cell.accessoryType = checkmark ? .checkmark : .none
    return cell
  }
  
  override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    //Determine the section for the cell.
    switch TableViewSection(rawValue: indexPath.section)! {
    case .name:
      //Similar to the previous modification views, retrieve the cell, then
      //get the text field via a tag assigned to it.
      let cell =
        tableView.dequeueReusableCell(withIdentifier: "group-name-cell")!
      nameTextField = cell.viewWithTag(4) as? UITextField
      nameTextField!.delegate = self
      return cell
    case .members:
      //As ModifyToDoListItemTableViewController.
      let employee = possibleMembers[indexPath.row]
      let checkmark = members.contains(where: {$0.employee.id == employee.id})
      return retrieveEmployeeSelectionCell(employee, checkmark: checkmark)
    case .admins:
      //As ModifyToDoListItemTableViewController, but using the admin flag
      //instead of finsing the item in an array.
      let (admin, employee) = members[indexPath.row]
      return retrieveEmployeeSelectionCell(employee, checkmark: admin)
    case .submit:
      return
        tableView.dequeueReusableCell(withIdentifier: "send-information-cell")!
    }
  }
  
  //Generates a sendable dictionary, sends a call to the server, then waits for
  //a response and takes the appropriate actions.
  func SubmitGroup() {
    //Check that the process of generating the form data succeds then assign it
    //to the formData constant.
    guard let formData = generateFormData() else {
      return
    }
    
    //Create a bizzorg call. If the user is editing a group, use PATCH and point
    //towards the group's URL, all other modes used POST with the base URL.
    var call: BizzorgApiCall
    switch mode {
    case .baseGroup, .subGroup:
      call = BizzorgApiCall("employee-groups/", method: .POST)
    case .editing:
      call = BizzorgApiCall("employee-groups/\(group!.id)/", method: .PATCH)
    }
    //Set the form data.
    call.apiData = formData
    
    //Send the call to the server.
    call.sendToServer(globalUrlSession) {
      //Check the response is validated.
      guard call.responseValidated else {
        return
      }
      //Move one view back to denote completion.
      executeUiChange {
        self.navigationController!.popViewController(animated: true)
      }
    }
  }
  
  //Toggles the membership of the employee at the specific index path.
  func toggleMembership(_ indexPath: IndexPath) {
    //Find the emplyee that was selected.
    let member = possibleMembers[indexPath.row]
    //If the employee is already in the members list, find their position in the 
    //list.
    if let index =
      members.index(where: {(_, employee) in employee.id == member.id}) as Int? {
      tableView.beginUpdates()
      //Remove the member from the list.
      members.remove(at: index)
      tableView.deleteRows(
        at: [IndexPath(row: index, section: TableViewSection.admins.rawValue)],
        with: .automatic
      )
      tableView.endUpdates()
    } else {
      //If the employee isn't in the member list, add them with an admin flag of
      //false.
      tableView.beginUpdates()
      members.append((false, member))
      let row = members.count - 1
      tableView.insertRows(
        at: [IndexPath(row: row, section: TableViewSection.admins.rawValue)],
        with: .automatic
      )
      tableView.endUpdates()
    }
  }
  
  //Similar to the function above, but just toggling the admin flag.
  func toggleAdminRights(_ indexPath: IndexPath) {
    members[indexPath.row].admin.toggle()
    tableView.reloadRows(at: [indexPath], with: .none)
  }
  
  override func tableView(_ tableView: UITableView,
                          didSelectRowAt indexPath: IndexPath) {
    switch TableViewSection(rawValue: indexPath.section)! {
    case .submit:
      //If the user has tapped the submit button, attempt to submit the group
      //to the server.
      SubmitGroup()
    case .members:
      toggleMembership(indexPath)
      tableView.deselectRow(at: indexPath, animated: false)
    case .admins:
      toggleAdminRights(indexPath)
      tableView.deselectRow(at: indexPath, animated: false)
    case .name: break
    }
  }
  
  //Set the keyboard dismiss mode and get the possible group members.
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.keyboardDismissMode = .onDrag
    getPossibleMembers()
  }

  override func viewDidAppear(_ animated: Bool) {
    //If we are editing a group, we need to set the information that the group
    //already has, so to do this for the name, get the name text field cell,
    //and, if applicable, set the text inside the field to the name of the
    //group.
    let nameCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0))
    nameTextField = nameCell?.viewWithTag(4) as? UITextField
    if mode == .editing {
      name = group?.name
      nameTextField?.text = group?.name.capitalized
    }
  }
  
  //Gets the possible members of the group currently being created/modified.
  func getPossibleMembers() {
    switch mode {
    case .baseGroup, .editing:
      //Since we dont 100% know which employees can be assigned, request the
      //server for all the employees.
      getAllEmployees() {
        (allEmployees, error) in
        //Check that everything succeeded. Throw an error if not.
        guard error == nil && allEmployees != nil else {
          displayErrorMessage("Network Error.",
                              viewController: self.navigationController!)
          self.navigationController!.popViewController(animated: true)
          return
        }
        //Set the possible members to all employees.
        self.possibleMembers = allEmployees!
        //Reload the table view employee section.
        executeUiChange {
          self.tableView.reloadSections(IndexSet(integer: 1), with: .fade)
        }
        //Get the user profile pictures.
        self.getProfilePictures()
      }
    case .subGroup:
      //If we are creating a sub-group, we already have the possible members,
      //so we just have to reload the section.
      executeUiChange {
        self.tableView.reloadSections(IndexSet(integer: 1), with: .fade)
      }
      getProfilePictures()
    }
  }
  
  //Requests the server for all the employees.
  func getAllEmployees(_ callback: @escaping ([Employee]?, Error?) -> Void) {
    let call = BizzorgApiCall("employees/", method: .GET)
    call.sendToServer(globalUrlSession) {
      let response = call.serverResponse!
      guard response.validated else {
        callback(nil, response.error!)
        return
      }
      var employeesArray: [Employee]? = nil
      do {
        employeesArray = try call.responseObjectsToDataModels()
      } catch {
        callback(nil, error)
      }
      callback(employeesArray, nil)
    }
  }
  
  //Gets the profile picture for each employee in the possible members list.
  func getProfilePictures() {
    for (index, employee) in possibleMembers.enumerated() {
      employee.getProfilePicture(globalUrlSession) {
        executeUiChange {
        self.tableView.reloadRows(
          at: [
            IndexPath(row: index, section: TableViewSection.members.rawValue)],
          with: .fade)
        }
      }
    }
  }
}
