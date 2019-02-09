//
//  GroupsTableViewController.swift
//  Bizzorg
//
//  Created by Jordan Field on 17/05/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import UIKit

/**
 Table view controller responsible for the "My groups" tab, showing a list of
 all groups the user is a member of.
 
 UI links
 ========
 addGroupButton
 
 Properties
 ==========
 groups - The list the table view uses as a data source. populated with data
 models once they are recieved from the server.
 */
class GroupsTableViewController: UITableViewController {
  @IBOutlet weak var addGroupButton: UIBarButtonItem!
  
  var groups: [EmployeeGroup] = []
  
  ///Retrives the groups from the server for the logged in user.
  func getGroups(_ completion: @escaping (Error?) -> Void) {
    
    //Check for a logged in user. If there isn't one, callback an error.
    guard loggedInUser != nil else {
      completion(LoginError.noLoggedInUser)
      return
    }
    
    //Generate the call with the correct URL.
    let call = BizzorgApiCall("employee-groups/?members=\(loggedInUser!.id)",
                              method: .GET)
    
    //Initiate server communication and wait for a response.
    call.sendToServer(globalUrlSession) {
      //Assign the server response to the constant 'response'.
      let response = call.serverResponse!
      
      //Check that the response contains no errors, if there is an error,
      //send it to the completion handler.
      guard response.validated else {
        completion(response.error)
        return
      }

      //Check that the server response code is 200 OK. If it isn't, send the 
      //actual staus code as an error to the completion handler.
      guard response.statusCode == 200 else {
        completion(NetworkError.serverError(statusCode: response.statusCode))
        return
      }
      
      //Attempt to convert the server response to data models, if this fails,
      //pass the error to the completion handler.
      do {
        self.groups = try call.responseObjectsToDataModels()
      } catch {
        completion(error)
        return
      }
      
      //Everything has been processed successfuly, so call the completion
      //handler with nil to denote no error.
      completion(nil)
    }
  }

  override func viewDidLoad() {
    
    //Check for a logged in user before proceeding.
    guard loggedInUser != nil else {
      return
    }
    
    /*
     If the user is the member of the VIP staff list, they have sufficent 
     privileges to create base groups that have no parent groups. Therefore
     enable the 'add base group' button if the logged in user satifies this
     position.
     */
    executeUiChange {
      self.addGroupButton.isEnabled = loggedInUser!.isStaff
    }
    
    getGroups() {
      (error) in
      
      //Check for a possible error. If there is one, display it to the user.
      guard error == nil else {
        displayErrorMessage("\(alertIntro) \(error!)", viewController: self)
        return
      }
      
      //If there are no errors, I can now safely reload the table with the new
      //data.
      executeUiChange {
        self.tableView.reloadData()
      }
    }
  }
  
  //Identical to ToDoListTableViewController
  override func viewWillAppear(_ animated: Bool) {
    if let indexPath = self.tableView.indexPathForSelectedRow {
      self.tableView.deselectRow(at: indexPath, animated: true)
    }
  }
  
  //Only one section in this view, so return 1.
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  //Returns the length of the groups variable.
  override func tableView(_ tableView: UITableView,
                          numberOfRowsInSection section: Int) -> Int {
    return groups.count
  }
  
  
  override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    //Initate a cell with the correct layout and type.
    let cell =
      tableView.dequeueReusableCell(withIdentifier: "group-summary")
        as! GroupSummaryTableViewCell
   
    /* The summary cells are very easy to configure since the code to display
    the information is handled by the cell itself. Therefore all I have to
    do is to assign the cell's variable 'group' to the correct group for this
    cell in the groups list. */
    let group = groups[indexPath.row]
    cell.group = group
   
    return cell
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //Check the segue has a unique identifier
    guard segue.identifier != nil else {
      return
    }
    
    //Only pass information if the segue has the correct identifier to prevent
    //errors.
    switch segue.identifier! {
      case "group-detail":
        //Retrieve the cell the user tapped.
        let groupCell = sender as! GroupSummaryTableViewCell
        
        //Initialise the destination view controller with the correct type for
        //data transfer.
        let destination = segue.destination as! GroupViewController
        
        //Set the cell's group to the view controller's group.
        destination.group = groupCell.group!
    default: break
    }
  }
}
