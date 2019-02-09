//
//  ToDoListItem.swift
//  Bizzorg
//
//  Created by Jordan Field on 13/07/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//
import Foundation

/**
 The native client representation for a To-do list item on the server.
 
 Properties
 ==========
 
 `groupUri`: The URI that points to the group this item is assigned to.
 
 `group`: If the code requests that the user model be retrieved, it is placed
 into this variable, otherwise nil.
 
 `title`: The name of the item.
 
 `description`: An optional string that can be used to provide additional
 information about the item.
 
 `priority`: How urgent this task is.
 
 `completed`: Boolean value denoting whether the item has been achieved.
 
 `createdDate`: As the name suggests, the date the item was created.
 
 `deadlineDate`: The suggested date of completion for the item.
 
 `assignedEmployees`: List of employees that have been assigned to this item.
 
 `resourceUri`: The URL for this resource on the server.
 
 `id`: Computed integer that takes the ID from the resource URI.
 */
class ToDoListItem: ApiDataModel, Titleizable {
  var groupUri: URL
  var group: EmployeeGroup?
  var title: String
  var description: String?
  var priority: TaskPriority
  var completed: Bool
  var createdDate: Date
  var deadlineDate: Date?
  var assignedEmployees: [Employee]
  var resourceUri: URL
  var id: Int {
    let dataUriSplit = resourceUri.relativeString.components(separatedBy: "/")
    return Int(dataUriSplit[4])!
  }
  
  //List of possible task priorities and the subsequent string that should
  //be sent to the server.
  enum TaskPriority: String, Titleizable {
    case Low = "low"
    case Regular = "reg"
    case Significant = "sig"
    case Urgent = "urg"
    case Severe = "sev"
    
    //The pretty value is used when the priority is displayed to the user.
    var prettyValue: String {
      switch self {
      case .Low: return "Low"
      case .Regular: return "Regular"
      case .Significant: return "Significant"
      case .Urgent: return "Urgent"
      case .Severe: return "Severe"
      }
    }
    
    //So that this can work with the picker views, create a computed variable
    //called 'title' that returns the pretty string.
    var title: String {
      return prettyValue
    }
  }
  
  //A list of all possible attributes and the string that should be used against
  //the dictionary to retrieve that attribute.
  enum ToDoListItemAttribute: String {
    case
    resourceUri = "resource_uri",
    group = "group",
    title = "title",
    description = "description",
    priority = "priority",
    completed = "completed",
    createdDate = "date_created",
    deadlineDate = "deadline_date",
    assignedEmployees = "employees"
  }

  //Retrieves the group this tasks is assigned to and places it in the 'group'
  //variable. An asynchronous function that calls back when completed.
  func getGroup(callback: @escaping () -> Void) {
    getObjectFromUri(groupUri, urlSession: globalUrlSession) {
      (group: EmployeeGroup?, error) in
      self.group = group
      callback()
    }
  }
  
  //See init(data: KeyValuePairs in Employee object for detailed explanation.
  required init(data: KeyValuePairs) throws {
    
    //See 'extract' function in employee object for detailed explanation.
    func extract(_ key: ToDoListItemAttribute,
                 from data: KeyValuePairs) -> Any? {
      return data[key.rawValue]
    }
    
    //See 'extractUri' function in employee object for detailed explanation.
    func extractUri(_ key: ToDoListItemAttribute,
                    from data: KeyValuePairs) -> URL? {
      guard let relativeString = extract(key, from: data) as? String,
        let url = URL(string: relativeString, relativeTo: baseUrl) else {
          return nil
      }
      return url
    }
    
    guard extractUri(.resourceUri, from: data) != nil &&
          extractUri(.group, from: data) != nil &&
          extract(.title, from: data) != nil &&
          extract(.priority, from: data) != nil &&
          extract(.completed, from: data) != nil &&
          extract(.createdDate, from: data) != nil else {
        throw DataError.dataConversionFailed
    }
    resourceUri = extractUri(.resourceUri, from: data)!
    groupUri = extractUri(.group, from: data)!
    title = extract(.title, from: data) as! String
    description = extract(.description, from: data) as? String
    priority =
      TaskPriority(rawValue: extract(.priority, from: data) as! String)!
    completed = extract(.completed, from: data) as! Bool
    
    //I need to convert the string date into a native swift Date, which is done
    //using the DateFormatter object.
    let dateFormatter = DateFormatter()
    
    //Set the format that the date formatter should use to covert strings.
    dateFormatter.dateFormat = "yyyy-mm-dd"
    createdDate =
      dateFormatter.date(from: extract(.createdDate, from: data) as! String)!
    if let possibleDeadline = extract(.deadlineDate, from: data) as? String {
      deadlineDate = dateFormatter.date(from: possibleDeadline)
    }
    let assignedEmployeeObjects =
      extract(.assignedEmployees, from: data) as? [Any]
    assignedEmployees = []
    for object in assignedEmployeeObjects! {
      let objectKvp = object as! KeyValuePairs
      assignedEmployees.append(try! Employee(data: objectKvp))
    }
  }
  
  //See init(data: Data) in employee object for detailed explanation.
  convenience required init?(data: Data) {
    do {
      let kvp = try
        JSONSerialization.jsonObject(with: data, options: []) as! KeyValuePairs
      try self.init(data: kvp)
    } catch {
      return nil
    }
  }

}
