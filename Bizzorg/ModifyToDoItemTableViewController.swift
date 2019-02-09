//
//  ModifyToDoItemTableViewController.swift
//  Bizzorg
//
//  Created by Jordan Field on 23/09/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import UIKit

/*
 This class, along with ModifyScheduleItemTableViewController, is one of the
 most complex classes in the entire app. It involves both sending and recieving
 data to and from the server, turning native swift objects into JSON data,
 accepting user input in a way that is useful to the user, and dealing with 
 associations like user assignments. be prepared for heavy annotation on this
 file. However since ModifySchduleItemTableViewController is essentialy 
 identical, the annotation on that class will be sparse.
 */

/*
 The UI in these views is very dynamic, as the date and item picker views can
 slide in and out of position. As such, I need a way to easily keep track of
 what cells are where. I do this with a dynamic list of cells that can be added
 to and subtracted from. This way I can append a picker cell to this dynamic
 list, update the table view, then remove the picker view and update the table
 view again when nessecary. However, In the code I need a way to distinguish
 which cells are detail cells and which cells are picker cells. The way I do
 this is by having two distinct enum types for the two types of cells. The
 problem with this, however, is that the strict typing of Swift does not allow
 you to have objects of different types in a list. It does, however, let you
 assign a protocol type to a list. This means that the list can have multiple
 types, but they all must conform to a specific protocol, and the programmer
 has to discern what the type of the object they just recieved is. So in order
 to create this dynamic list I created an empty protocol DetailCellType, which
 I then assign to the InfoCellType and PickerCellType respectively.
*/
protocol DetailCellType {}

/**
 The class responsible for creating and editing to-do items.
 
 Properties
 ==========
 itemTitle - The title of the item to be sent.
 itemDesciption - The description of the item.
 group - The group the item is assigned to. Changing the group property will
 change which employees can be assigned to the item, so a didSet function
 changes the possible employees and updates the table view.
 priority - As name suggests.
 deadlineDate - As name suggests.
 potentialEmployees - This is the list used by the employees section of the
 table view to show which employees can be assigned and gives the user the
 capability of assigning them.
 employees - a list of employees that actually have been assigned currently.
 Used in the table view to add the checkmarks on the cells.
 item - If the user is editing an item rather than making a new one, this
 variable is set to the item they are changing, when this is set, all of the
 other relevant variables are changed to the ones that the item has.
 possiblePriorities - Used by the priority picker view, a list of the priorities
 a to-do item can have.
 groups - used by the group picker view, shows which groups the user can assign
 a to-do item to.
 itemTitleTextField - Will be used to point to the text field the user types
 the title of the item title into so the text can be extracted.
 descriptionTextView - As above, but with the description text field instead.
 dataDateFormatter - Used when building the dictionary to send to the server
 to convert the swift Date object to a standard string representation.
 prettyDateFormatter - Similar to above, but for converting the date into a
 human-readable format for use in the UI.
 detailCells - The dynamic list I was talking about above, this starts with just
 the 4 info cells, but as the user uses this view the list will change as they
 interact with the screen.
 */
class ModifyToDoItemTableViewController: UITableViewController,
  UITextFieldDelegate,
  UITextViewDelegate,
  ItemPickerTableViewCellDelegate,
  DatePickerTableViewCellDelegate {

  var itemTitle: String?
  var itemDescription: String?
  var group: EmployeeGroup? {
    didSet {
      //Check the data assigned was not nil
      guard group != nil else {
        return
      }
      //Set the potential employees to the members of the group assigned.
      potentialEmployees = group!.membersWithoutAdminFlag
    }
  }
  var priority: ToDoListItem.TaskPriority = .Regular
  var deadlineDate: Date?
  var potentialEmployees: [Employee] = [] {
    //When the employees are assigned, retrieve each of their profile pictures
    //to be displayed in the UI.
    didSet {
      getProfilePictures()
    }
  }
  var employees: [Employee] = []
  
  var item: ToDoListItem? {
    didSet {
      //Check the item assigned isn't nil before setting all the data.
      guard item != nil else {
        return
      }
      group = item!.group
      itemTitle = item!.title
      itemDescription = item!.description
      priority = item!.priority
      deadlineDate = item!.deadlineDate
      employees = item!.assignedEmployees
      tableView.reloadData()
    }
  }
  
  let possiblePriorities: [ToDoListItem.TaskPriority] = [
    .Regular,
    .Low,
    .Significant,
    .Urgent,
    .Severe
  ]
  
  var groups: [EmployeeGroup] = []
  
  var itemTitleTextField: UITextField?
  var descriptionTextView: UITextView?
  let dataDateFormatter = DateFormatter()
  let prettyDateFormatter = DateFormatter()
  
  var detailCells: [DetailCellType] = [
    InfoCellType.title,
    InfoCellType.group,
    InfoCellType.priority,
    InfoCellType.deadline
  ]
  
  //An enum to differentiate between the four sections of the table view.
  enum TableViewSection: Int {
    case details = 0, employees, description, submit
  }
  
  //An enum to differentiate between the two different types of item picker 
  //cells.
  enum PickerViewType: Int {
    case group = 1, priority
  }
  
  //The four different types of information cells.
  enum InfoCellType: DetailCellType {
    case title, group, priority, deadline
  }
  
  //The three different types of picker cells.
  enum PickerCellType: DetailCellType {
    case datePicker, groupPicker, priorityPicker
  }
  
  //Takes all the assigned variables and generates a KeyValuePairs dictionary
  //that can be sent to the server.
  func generateFormData() -> KeyValuePairs? {
    //Check that the required variables have assigned values, if they don't,
    //return nil so that nothing is sent to the server.
    guard itemTitle != nil, itemTitle != "", group != nil else {
      return nil
    }
    
    //Start to generate the dictionary.
    var formData: KeyValuePairs = [
      "group": group!.resourceUri.relativeString,
      "title": itemTitle!,
      "priority": priority.rawValue,
      "deadline_date": dataDateFormatter.string(from: deadlineDate!)
    ]
    
    
    //Add the description to the dictionary if it is not nil.
    if itemDescription != nil {
      formData["description"] = itemDescription!
    }
    
    //Get the resource URI of each employee and make a list of all of them.
    let employeeUris = employees.map {$0.resourceUri.relativeString}

    //Cast the employeeUris list down to any and add it to the dictionary.
    formData["employees"] = employeeUris as Any?
    
    //Return the finalised dictionary.
    return formData
  }
  
  //Retrieves the groups the creator is an administrator of.
  func getCreatorGroups() {
    /*
     For this function, I will be using the capability of the tastypie API to
     retrieve a set of values at once to prevent multiple requests and hence
     increase efficiency. The URL therefore has to be built like this:
     
     /employee-groups/set/1;2;4;5;10 etc.
     
     I start by creating an empty string that the URI will be built from.
     */
    var requestString = ""
    
    //I then check there is a logged in user before proceeding.
    guard loggedInUser != nil else {
      return
    }
    
    /*
     The 'administrating' property in the Employee object is a list of resource
     URIs for the groups that employee has admin privileges of. I iterate
     through this list, find the ID of the employee group, and append it to
     the request string.
     */
    for groupUri in loggedInUser!.administrating {
      let relativeString = groupUri.relativeString
      let components = relativeString.components(separatedBy: "/")
      requestString.append(components[4])
      //The last item does not need to have a semicolon, so this line check
      //each item to check it's not the last item, and adds a ; if it isn't.
      if groupUri != loggedInUser!.administrating.last {
        requestString.append(";")
      }
    }
    
    //Create an API call with the new request string.
    let call =
      BizzorgApiCall("employee-groups/set/\(requestString)/", method: .GET)
    
    //Send the call to the server.
    call.sendToServer(globalUrlSession) {
      //Check the response is okay before proceeding.
      guard call.serverResponse!.validated else {
        return
      }
      //Try to convert the response to a list of groups.
      guard let groupList: [EmployeeGroup] =
        try? call.responseObjectsToDataModels() else {
        return
      }
      //set the groups property to the newly created group list.
      self.groups = groupList
      //Set the currently selected group to the first group in the group list,
      //since that is the first selected group in the picker view.
      self.group = groupList.first
      
      //Reload the table view so that the new data is shown.
      executeUiChange {
        self.tableView.reloadData()
      }
    }
  }
  
  //Retrieves each employees profile picture.
  func getProfilePictures() {
    //Runs the getProfilePicture function on each employee object, then reloads
    //the tabe view when a picture is recieved.
    _ = potentialEmployees.map {
      $0.getProfilePicture(globalUrlSession) {
        executeUiChange { self.tableView.reloadData() }
      }
    }
  }
  
  override func viewDidLoad() {
    //Set the correct formats for the date formatters.
    dataDateFormatter.dateFormat = "yyyy-MM-dd"
    prettyDateFormatter.setLocalizedDateFormatFromTemplate("EdMMMyyyy")
    
    /*
     Since I'm dealing with users entering text on screen, I have to deal with
     the keyboard popping up and obscuring the view. As such I want an easy and
     intuitive way for the user to dismiss the keybaord, I do this by using the
     on drag mode, which dissmisses the keyboard as soon as the user starts
     to scroll the screen.
     */
    tableView.keyboardDismissMode = .onDrag
    
    //If the user is creating a new to-do item. Set the deadline date to the
    //current time and find the possible groups the user can assign items to.
    if item == nil {
      deadlineDate = Date.now
      getCreatorGroups()
    }
  }
  
  //You know what these two functions does by now.
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 4
  }

  override func tableView(_ tableView: UITableView,
                          numberOfRowsInSection section: Int) -> Int {
    switch TableViewSection(rawValue: section)! {
    case .details:
      return detailCells.count
    case .employees:
      return potentialEmployees.count
    case .description:
      return 1
    case .submit:
      return 1
    }
  }
  
  //For the assigning employees section, I create a cell that shows the user's
  //profile picture, name and job position, as well as a checkmark to denote
  //if the user has been selecte already.
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
  
  //In order to reduce the size of the cellForRowAt function, I separated the
  //sinple detail cell creation to a seperate function that can be called with
  //title and detail argumaents.
  func retrieveDetailCell(title: String, detail: String?) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "detail-showing-cell")!
    cell.textLabel?.text = title
    cell.detailTextLabel?.text = detail
    return cell
  }
  
  override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    //Determine which section the cell being requested is in.
    switch TableViewSection(rawValue: indexPath.section)! {
    case .details:
      var cell: UITableViewCell
      //Determine which cell is being requested.
      switch detailCells[indexPath.row] {
      case InfoCellType.title:
        //For the title cell. We need a text field which is assigned to the
        //class so we can get the text from it
        cell = tableView.dequeueReusableCell(withIdentifier: "item-title-cell")!
        //I use the tag function explained earlier to get the text field and
        //assign it to the correct instance variable.
        itemTitleTextField = cell.viewWithTag(17) as? UITextField
        itemTitleTextField?.delegate = self
        itemTitleTextField?.text = itemTitle
      //Both group and priority are pretty simple, since they use picker cells
      //for selection instead of manual access.
      case InfoCellType.group:
        cell = retrieveDetailCell(title: "Group", detail: group?.name.capitalized)
      case InfoCellType.priority:
        cell = retrieveDetailCell(title: "Priority", detail: priority.prettyValue)
      case InfoCellType.deadline:
        var dateString: String?
        //Check to see if a deadline date exists, then format it into the human
        //readable format if it is.
        if deadlineDate == nil {
          dateString = nil
        } else {
          dateString = prettyDateFormatter.string(from: deadlineDate!)
        }
        cell = retrieveDetailCell(title: "Deadline", detail: dateString)
      /*
        The picker cells have to be initialised in a specific way to ensure they
        work properly. First I initialise the cell as a generic table view cell,
        then typecast it into a picker view cell, assign the appropriate choices
        then finally assign the update delegate (the cell will then call the
        function on the delegate when an option has been selected.)
      */
      case PickerCellType.groupPicker:
        cell = tableView.dequeueReusableCell(withIdentifier: "item-picker-cell")!
        let pickerCell = cell as! ItemPickerTableViewCell
        pickerCell.options = groups
        pickerCell.updateDelegate = self
      case PickerCellType.priorityPicker:
        cell = tableView.dequeueReusableCell(withIdentifier: "item-picker-cell")!
        let pickerCell = cell as! ItemPickerTableViewCell
        pickerCell.options = possiblePriorities
        pickerCell.updateDelegate = self
      case PickerCellType.datePicker:
        cell = tableView.dequeueReusableCell(withIdentifier: "date-picker-cell")!
        let dateCell = cell as! DatePickerTableViewCell
        dateCell.updateDelegate = self
        if deadlineDate != nil {
          //For the date picker, we have to move the current date shown to the
          //deadline date alread selected if it exists.
          dateCell.datePicker.setDate(deadlineDate!, animated: false)
        }
      default: cell = UITableViewCell()
      }
      return cell
    case .employees:
      //Get the employee that is to be shown using this cell.
      let employee = potentialEmployees[indexPath.row]
      //Determine if the employee has already been selected by polling the
      //employees list to see if an employee with the same ID as the user
      //is already in the list. this creates the boolean 'selected'
      let selected = employees.contains(where: {$0.id == employee.id})
      //Use the retirieved employee and selected value to generate an employee
      //selection cell.
      let cell = retrieveEmployeeSelectionCell(employee, checkmark: selected)
      return cell
    case .description:
      //I do a similar thing to the title cell here, generating the cell,
      //targeting the text field and assigning it to the appropriate class
      //variable.
      let cell =
        tableView.dequeueReusableCell(withIdentifier: "item-description-cell")!
      descriptionTextView = cell.viewWithTag(15) as? UITextView
      descriptionTextView?.delegate = self
      descriptionTextView?.text = itemDescription
      return cell
    case .submit:
      //This one's simple enough.
      let cell =
        tableView.dequeueReusableCell(withIdentifier: "send-information-cell")!
      return cell
    }
  }
  
  //This is called when the 'done' key on the virtual keyboard is pressed, in
  //this instance, all we want to do is dismiss the keyboard.
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
  
  //Called once the title text field has finished editing.
  func textFieldDidEndEditing(_ textField: UITextField) {
    //assign the title instance variable to the text in the field.
    itemTitle = textField.text
  }
  
  //The description text view has a placeholder that is shown before text is
  //entered, so once the user starts to enter text, immediately clear that
  //placeholder.
  func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
    textView.textColor = UIColor.black
    textView.text = ""
    return true
  }
  
  //Called when the user finishes editing the description.
  func textViewDidEndEditing(_ textView: UITextView) {
    itemDescription = textView.text
    //If the user has in fact deleted the description, put the placeholder text
    //back in.
    if textView.text.characters.count == 0 {
      textView.textColor = UIColor.lightGray
      textView.text = "Description"
    }
  }
  
  //Edits the dynamic cell list to add a picker cell at the location specified.
  func insertPicker(_ type: PickerCellType, at indexPath: IndexPath) {
    //In order to animate the procedure, I have to tell iOS that I'm making
    //changes to the data list.
    tableView.beginUpdates()
    //Insert the specified picker cell type enum instance into the list at the
    //correct position.
    detailCells.insert(type, at: indexPath.row)
    //Now insert the row we have just added to the list. This will push all the
    //other cells down for me.
    tableView.insertRows(at: [indexPath], with: .fade)
    //Signify to iOS we are done updating.
    tableView.endUpdates()
  }
  
  //This function does the same as the function above, but with removing a
  //picker cell rather than adding it.
  func removePicker(at indexPath: IndexPath) {
    tableView.beginUpdates()
    detailCells.remove(at: indexPath.row)
    tableView.deleteRows(at: [indexPath], with: .fade)
    tableView.endUpdates()
  }
  
  //Called when the user taps an employee cell to add them to the item or
  //remove them.
  func toggleEmployeeAssignment(_ employee: Employee) {
    //If the employee has a spot in the list, assign it to the constant index
    //if not, move to the else statement.
    if let index = employees.index(where: {$0.id == employee.id}) {
      //Remove the item from that position
      employees.remove(at: index)
    } else {
      //Add the employee to the end of the list.
      employees.append(employee)
    }
  }
  
  //Used to determine if the user taps outside the keyboard, to dismiss the
  //keyboard.
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    tableView.endEditing(false)
    super.touchesBegan(touches, with: event)
  }
  
  /*
   This is the big one.
   
   Since this view controller does so many different things when the user
   selects different cells, this function is /really/ big. In a nutshell: if
   the user selects a detail cell, open the corresponding picker view. If they
   tap an employee cell, toggle that employee's assignment to the item. If the
   user selects the 'Submit' button, build the request, send it to the server
   and wait for a response. Once the response is recieved, dismiss the view.
  */
  override func tableView(_ tableView: UITableView,
                          didSelectRowAt indexPath: IndexPath) {
    //Two variables that may be used are defined here.
    //Picker type denotes which picker cell the view wants to initialise.
    var pickerType: PickerCellType?
    //mutableIndexPath is used to find the correct position for the picker view
    //cell. Initially it will be one cell after the cell that is selected, but
    //this may change.
    var mutableIndexPath = indexPath
    mutableIndexPath.row += 1
    //Determine the section of the cell the user tapped.
    switch TableViewSection(rawValue: indexPath.section)! {
    case .details:
      //Determine which detail cell the user pressed. This is done to determine
      //which picker cell to show.
      switch detailCells[indexPath.row] {
      case InfoCellType.group:
        //I only want the user to be able to select the group if they are
        //creating a new to-do item, as such, I check to see if there is already
        //an assigned item and stop a picker view from showing if there is.
        pickerType = item != nil ? nil : .groupPicker
      case InfoCellType.priority:
        pickerType = .priorityPicker
      case InfoCellType.deadline:
        pickerType = .datePicker
      default: break
      }
    case .employees:
      //If the user selected an employee cell, find the employee they selected.
      let employee = potentialEmployees[indexPath.row]
      //Then toggle assigment for that employee.
      toggleEmployeeAssignment(employee)
      //Finally, reload that row, so the checkmark will be displayed.
      tableView.reloadRows(at: [indexPath], with: .none)
    case .description: break
    case .submit:
      //Generate the data as a dictionary.
      tableView.deselectRow(at: indexPath, animated: true)
      guard let kvp = generateFormData() else {
        displayErrorMessage("Missing information.", viewController: self)
        return
      }
      var call: BizzorgApiCall
      //If an item is being editing, create the call as a PATCH and point the
      //url to the correct item on the server. Otherwise, use a POST request
      //to make a new object.
      if item != nil {
        call = BizzorgApiCall("todolist-items/\(item!.id)/", method: .PATCH)
      } else {
        call = BizzorgApiCall("todolist-items/", method: .POST)
      }
      //Set the api data to the form data generated earlier.
      call.apiData = kvp
      //Send the call to the server and wait for a response.
      call.sendToServer(globalUrlSession) {
        //Check the response is validated and has the right status code. If not,
        //display an error to the user.
        guard call.responseValidated &&
          call.serverResponse?.statusCode == 201 else {
          displayErrorMessage("Server error.", viewController: self)
          return
        }
        //If everything goes successfully, push the user one view back to show
        //that the process has completed.
        executeUiChange {
          self.navigationController!.popViewController(animated: true)
        }
      }
    }
    //Deslect the row to remove the grey highlighting.
    tableView.deselectRow(at: indexPath, animated: true)
    //Find the current index of the picker cell, or nil if there isn't one.
    let pickerIndex = detailCells.index(where: {$0 is PickerCellType})
    //If there is currently a picker cell present in the UI.
    if pickerIndex != nil {
      //Remove it from the UI.
      removePicker(at: IndexPath(row: pickerIndex!, section: 0))
      //Set the mutable index path one back if the removed picker view comes
      //before the removed cell, since everything after that has been shifted
      //back by one.
      if pickerIndex! < mutableIndexPath.row {
        mutableIndexPath.row -= 1
      }
    }
    //If a picker type has been set and there isn't already a cell in the 
    //place where the picker cells is about to be created.
    if pickerType != nil && pickerIndex != mutableIndexPath.row {
      //Insert the picker in the correct position.
      insertPicker(pickerType!, at: mutableIndexPath)
    }
  }
  
  /*
   Called when a picker view is stopped on a selection. Since there are multiple
   picker views, I need to determine which picker view is used and then take
   the appropriate actions to whatever is selected.
  */
  func pickerViewDidSelect(_ pickerView: ItemPickerTableViewCell) {
    //Check that there is a selected object.
    guard pickerView.selectedOption != nil else {
      return
    }
    //If the selected item is a priority object. Set the priority to the one
    //selected.
    if pickerView.selectedOption is ToDoListItem.TaskPriority {
      priority = pickerView.selectedOption as! ToDoListItem.TaskPriority
    } else if pickerView.selectedOption is EmployeeGroup {
      //if the selected item is a group, set the group variable, and reset
      //all the selected users to prevent a user being assigned to a item in a
      //group they are not in.
      group = pickerView.selectedOption as? EmployeeGroup
      employees = []
    }
    //Reload the table view to show the correct data.
    executeUiChange {
      self.tableView.reloadData()
    }
  }
  
  //Used when the date picker is used to select a date.
  func datePickerViewDidSelect(_ datePicker: UIDatePicker,
                               cell: DatePickerTableViewCell) {
    //Set the date using the picker's data.
    deadlineDate = datePicker.date
    //reload the tableview.
    executeUiChange {
      self.tableView.reloadData()
    }
  }
  
  //Used to ensure cells have the correct height.
  override func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
    if TableViewSection(rawValue: indexPath.section)! == .description {
      tableView.estimatedRowHeight = 44
      return UITableViewAutomaticDimension
    }
    return UITableViewAutomaticDimension
  }
}
