//
//  ScheduleItem.swift
//  Bizzorg
//
//  Created by Jordan Field on 21/09/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//


/*
 This code is pretty much identical to the ToDoListItem code, so it will be 
 sparse with annotation. For detailed explanation on how model items work, see
 the Employee and Employee group classes.
 */

import Foundation

/**
 The native client representation for a Schedule event on the server.
 
 Properties
 ==========
 
 `groupUri`: The URL of the group this item is assigned to.
 
 `group`: If the code requests that the user model be retrieved, it is placed
 into this variable, otherwise nil.
 
 `title`: The name of the event.
 
 `Description`: An optional string that can be used to provide additional
 information about the event.
 
 `Priority`: How urgent this event is.
 
 `startDate`: The date and time this event will start.
 
 `endDate`: The date and time this event will end.
 
 `assignedEmployees`: List of employees that have been assigned to this event.
 
 `resourceUri`: The URL for this resource on the server.
 
 `id`: Computed integer that takes the ID from the resource URI.
 */
class ScheduleItem: ApiDataModel {
  var groupUri: URL
  var group: EmployeeGroup?
  var title: String
  var description: String?
  var priority: TaskPriority
  var startDate: Date
  var endDate: Date
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
    
    var title: String {
      return prettyValue
    }
  }
  
  //A list of all possible attributes and the string that should be used against
  //the dictionary to retrieve that attribute.
  enum ScheduleItemAttribute: String {
    case
    resourceUri = "resource_uri",
    group = "group",
    title = "title",
    description = "description",
    priority = "priority",
    startDate = "start",
    endDate = "end",
    assignedEmployees = "employees"
  }
  
  func getGroup(callback: @escaping () -> Void) {
    getObjectFromUri(groupUri, urlSession: globalUrlSession) {
      (group: EmployeeGroup?, error) in
      self.group = group
      callback()
    }
  }
  
  required init(data: KeyValuePairs) throws {
    
    //See 'extract' function in Employee object for detailed explanation.
    func extract(_ key: ScheduleItemAttribute,
                 from data: KeyValuePairs) -> Any? {
      return data[key.rawValue]
    }
    
    //See 'extractUri' function in employee object for detailed explanation.
    func extractUri(_ key: ScheduleItemAttribute,
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
      extract(.startDate, from: data) != nil &&
      extract(.endDate, from: data) != nil else {
        throw DataError.dataConversionFailed
    }
    resourceUri = extractUri(.resourceUri, from: data)!
    groupUri = extractUri(.group, from: data)!
    title = extract(.title, from: data) as! String
    description = extract(.description, from: data) as? String
    priority =
      TaskPriority(rawValue: extract(.priority, from: data) as! String)!
    
    let dateFormatter = DateFormatter()
    
    //Since the Schedule event system involves both dates and times, I have
    //to use a more precise way of sending and retrieving the information.
    //Therefore I decided to use the industry standard POSIX interface.
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    
    startDate =
      dateFormatter.date(from: extract(.startDate, from: data) as! String)!
    endDate =
      dateFormatter.date(from: extract(.endDate, from: data) as! String)!
    let assignedEmployeeObjects = data["employees"] as? [Any]
    assignedEmployees = []
    for object in assignedEmployeeObjects! {
      let objectKvp = object as! KeyValuePairs
      assignedEmployees.append(try! Employee(data: objectKvp))
    }
  }
  
  convenience required init?(data: Data) {
    do {
      let kvp =
        try JSONSerialization.jsonObject(with: data) as! KeyValuePairs
      try self.init(data: kvp)
    } catch {
      return nil
    }
  }
  
}
