//
//  ModifyScheduleItemTableViewController.swift
//  Bizzorg
//
//  Created by Jordan Field on 08/10/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import UIKit

/**
 See ModifyToDoItemTableViewController for a detailed explanation of this class,
 since it is essentially identical. any changes are annotated here.
 */
class ModifyScheduleItemTableViewController: UITableViewController,
  UITextFieldDelegate,
  UITextViewDelegate,
  ItemPickerTableViewCellDelegate,
  DatePickerTableViewCellDelegate {

  enum TableViewSection: Int {
    case details = 0, employees, description, submit
  }
  
  enum PickerViewType: Int {
    case group = 1, priority
  }
  
  enum InfoCellType: DetailCellType {
    case title, group, priority, startDate, endDate
  }
  
  enum PickerCellType: DetailCellType {
    case startDatePicker, endDatePicker, groupPicker, priorityPicker
  }
  
  var itemTitle: String?
  var itemDescription: String?
  var group: EmployeeGroup? {
    didSet {
      guard group != nil else {
        return
      }
      potentialEmployees = group!.membersWithoutAdminFlag
    }
  }
  var priority: ScheduleItem.TaskPriority = .Regular
  //Schedule events have a start time and end time.
  var startDate: Date?
  var endDate: Date?
  var itemTitleTextField: UITextField?
  var descriptionTextView: UITextView?
  var potentialEmployees: [Employee] = [] {
    didSet {
      getProfilePictures()
    }
  }
  var employees: [Employee] = []
  
  var item: ScheduleItem? {
    didSet {
      guard item != nil else {
        return
      }
      group = item!.group
      itemTitle = item!.title
      itemDescription = item!.description
      priority = item!.priority
      startDate = item!.startDate
      endDate = item!.endDate
      employees = item!.assignedEmployees
      tableView.reloadData()
    }
  }
  
  var groups: [EmployeeGroup] = []
  var possiblePriorities: [ScheduleItem.TaskPriority] = [
    .Regular,
    .Low,
    .Significant,
    .Urgent,
    .Severe
  ]
  let dataDateFormatter = DateFormatter()
  let prettyDateFormatter = DateFormatter()
  var detailCells: [DetailCellType] = [
    InfoCellType.title,
    InfoCellType.group,
    InfoCellType.priority,
    InfoCellType.startDate,
    InfoCellType.endDate
  ]
  
  var detailSectionRows: [(title: String, detail: String)] = [
    ("Group", "Select Group"),
    ("Priority", "Regular"),
    ("Start date and time", ""),
    ("End date and time", ""),
  ]
  
  func generateFormData() -> KeyValuePairs? {
    guard itemTitle != nil && group != nil else {
      return nil
    }
    var formData: KeyValuePairs = [
      "group": group!.resourceUri.relativeString,
      "title": itemTitle!,
      "priority": priority.rawValue,
      "start": dataDateFormatter.string(from: startDate!),
      "end": dataDateFormatter.string(from: endDate!),
    ]
    
    if itemDescription != nil {
      formData["description"] = itemDescription!
    }
    
    var employeeUris = [String]()
    
    for employee in employees {
      employeeUris.append(employee.resourceUri.relativeString)
    }
    
    formData["employees"] = employeeUris as AnyObject?
    return formData
  }
  
  func getCreatorGroups() {
    var requestString = ""
    guard loggedInUser != nil else {
      return
    }
    for groupUri in loggedInUser!.administrating {
      let relativeString = groupUri.relativeString
      let components = relativeString.components(separatedBy: "/")
      requestString.append(components[4])
      if groupUri != loggedInUser!.administrating.last {
        requestString.append(";")
      }
    }
    let call = BizzorgApiCall("employee-groups/set/\(requestString)/",
      method: .GET)
    call.sendToServer(globalUrlSession) {
      guard call.serverResponse!.validated else {
        return
      }
      guard let groupList: [EmployeeGroup] =
        try? call.responseObjectsToDataModels() else {
        return
      }
      self.groups = groupList
      self.group = groupList.first
      executeUiChange {
        self.tableView.reloadData()
      }
    }
  }
  
  func getProfilePictures() {
    for employee in potentialEmployees {
      guard employee.profilePicture == nil else {
        return
      }
      employee.getProfilePicture(globalUrlSession) {
        executeUiChange { self.tableView.reloadData() }
      }
    }
  }
  
  override func viewDidLoad() {
    //Since there is time involved, the date formats have to accomodate those
    //too.
    dataDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    prettyDateFormatter.setLocalizedDateFormatFromTemplate("EdMMMyyyyHHm")
    tableView.keyboardDismissMode = .onDrag
    if item == nil {
      startDate = Date.now
      endDate = Date.now
      getCreatorGroups()
    }
  }
  
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

  func retrieveDetailCell(title: String, detail: String?) -> UITableViewCell {
    let cell =
      tableView.dequeueReusableCell(withIdentifier: "detail-showing-cell")!
    cell.textLabel?.text = title
    cell.detailTextLabel?.text = detail
    return cell
  }
  
  override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch TableViewSection(rawValue: indexPath.section)! {
    case .details:
      var cell: UITableViewCell
      switch detailCells[indexPath.row] {
      case InfoCellType.title:
        cell = tableView.dequeueReusableCell(withIdentifier: "item-title-cell")!
        itemTitleTextField = cell.viewWithTag(17) as? UITextField
        itemTitleTextField?.delegate = self
        itemTitleTextField?.text = itemTitle
      case InfoCellType.group:
        cell = retrieveDetailCell(title: "Group", detail: group?.name.capitalized)
      case InfoCellType.priority:
        cell = retrieveDetailCell(title: "Priority", detail: priority.prettyValue)
      case InfoCellType.startDate:
        var dateString: String?
        if startDate == nil {
          dateString = nil
        } else {
          dateString = prettyDateFormatter.string(from: startDate!)
        }
        cell = retrieveDetailCell(title: "Starts", detail: dateString)
      case InfoCellType.endDate:
        var dateString: String?
        if endDate == nil {
          dateString = nil
        } else {
          dateString = prettyDateFormatter.string(from: endDate!)
        }
        cell = retrieveDetailCell(title: "Ends", detail: dateString)
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
      case PickerCellType.startDatePicker:
        cell = tableView.dequeueReusableCell(withIdentifier: "date-picker-cell")!
        let dateCell = cell as! DatePickerTableViewCell
        dateCell.updateDelegate = self
        //Since we have multiple date picker views we have to be able to discern
        //between them, I do this using the mode flag.
        dateCell.mode = .start
        if startDate != nil {
          dateCell.datePicker.setDate(startDate!, animated: false)
        }
      case PickerCellType.endDatePicker:
        cell = tableView.dequeueReusableCell(withIdentifier: "date-picker-cell")!
        let dateCell = cell as! DatePickerTableViewCell
        dateCell.updateDelegate = self
        dateCell.mode = .end
        if endDate != nil {
          dateCell.datePicker.setDate(endDate!, animated: false)
        }
      default: cell = UITableViewCell()
      }
      return cell
    case .employees:
      let employee = potentialEmployees[indexPath.row]
      let selected = employees.contains(where: {$0.id == employee.id})
      let cell = retrieveEmployeeSelectionCell(employee, checkmark: selected)
      return cell
    case .description:
      let cell =
        tableView.dequeueReusableCell(withIdentifier: "item-description-cell")!
      descriptionTextView = cell.viewWithTag(15) as? UITextView
      descriptionTextView?.delegate = self
      descriptionTextView?.text = itemDescription
      return cell
    case .submit:
      let cell =
        tableView.dequeueReusableCell(withIdentifier: "send-information-cell")!
      return cell
    }
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    itemTitle = textField.text
  }
  
  func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
    textView.textColor = UIColor.black
    textView.text = ""
    return true
  }
  
  func textViewDidEndEditing(_ textView: UITextView) {
    itemDescription = textView.text
    if textView.text.characters.count == 0 {
      textView.textColor = UIColor.lightGray
      textView.text = "Description"
    }
  }
  
  func removePicker(at indexPath: IndexPath) {
    tableView.beginUpdates()
    detailCells.remove(at: indexPath.row)
    tableView.deleteRows(at: [indexPath], with: .fade)
    tableView.endUpdates()
  }
  
  func insertPicker(_ type: PickerCellType, at indexPath: IndexPath) {
    tableView.beginUpdates()
    detailCells.insert(type, at: indexPath.row)
    tableView.insertRows(at: [indexPath], with: .fade)
    tableView.endUpdates()
  }
  
  func toggleEmployeeAssignment(_ employee: Employee) {
    if let index = employees.index(where: {$0.id == employee.id}) {
      employees.remove(at: index)
    } else {
      employees.append(employee)
    }
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    tableView.endEditing(false)
    super.touchesBegan(touches, with: event)
  }
  
  override func tableView(_ tableView: UITableView,
                          didSelectRowAt indexPath: IndexPath) {
    var pickerType: PickerCellType?
    var mutableIndexPath = indexPath
    mutableIndexPath.row += 1
    switch TableViewSection(rawValue: indexPath.section)! {
    case .details:
      switch detailCells[indexPath.row] {
      case InfoCellType.group:
        pickerType = item != nil ? nil : .groupPicker
      case InfoCellType.priority:
        pickerType = .priorityPicker
      case InfoCellType.startDate:
        pickerType = .startDatePicker
      case InfoCellType.endDate:
        pickerType = .endDatePicker
      default: break
      }
    case .employees:
      let employee = potentialEmployees[indexPath.row]
      toggleEmployeeAssignment(employee)
      tableView.reloadRows(at: [indexPath], with: .none)
    case .description: break
    case .submit:
      let kvp = generateFormData()
      var call: BizzorgApiCall
      if item != nil {
        call = BizzorgApiCall("schedule-items/\(item!.id)/", method: .PATCH)
      } else {
        call = BizzorgApiCall("schedule-items/", method: .POST)
      }
      call.apiData = kvp
      call.sendToServer(globalUrlSession) {
        print(call.serverResponse!.statusCode!)
        guard call.responseValidated &&
          call.serverResponse?.statusCode == 201 else {
            displayErrorMessage("Server error.", viewController: self)
            return
        }
        executeUiChange {
          self.navigationController!.popViewController(animated: true)
        }
      }
    }
    tableView.deselectRow(at: indexPath, animated: true)
    let pickerIndex = detailCells.index(where: {$0 is PickerCellType})
    if pickerIndex != nil {
      removePicker(at: IndexPath(row: pickerIndex!, section: 0))
      if pickerIndex! < mutableIndexPath.row {
        mutableIndexPath.row -= 1
      }
    }
    if pickerType != nil && pickerIndex != mutableIndexPath.row {
      insertPicker(pickerType!, at: mutableIndexPath)
    }
  }
  
  func pickerViewDidSelect(_ pickerView: ItemPickerTableViewCell) {
    guard pickerView.selectedOption != nil else {
      return
    }
    if pickerView.selectedOption is ScheduleItem.TaskPriority {
      priority = pickerView.selectedOption as! ScheduleItem.TaskPriority
    } else if pickerView.selectedOption is EmployeeGroup {
      group = pickerView.selectedOption as? EmployeeGroup
      employees = []
      guard group != nil else {
        return
      }
    }
    executeUiChange {
      self.tableView.reloadData()
    }
  }
  
  func datePickerViewDidSelect(_ datePicker: UIDatePicker,
                               cell: DatePickerTableViewCell) {
    //When a date picker has finished, check the mode to see which one was
    //being used, then set the correct date accordingly
    switch cell.mode! {
    case .start:
      startDate = datePicker.date
    case .end:
      endDate = datePicker.date
    }
    executeUiChange {
      self.tableView.reloadData()
    }
  }
  
  override func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
    if TableViewSection(rawValue: indexPath.section)! == .description {
      tableView.estimatedRowHeight = 44
      return UITableViewAutomaticDimension
    }
    return UITableViewAutomaticDimension
  }
}
