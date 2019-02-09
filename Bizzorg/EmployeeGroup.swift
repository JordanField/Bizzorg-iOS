//
//  EmployeeGroup.swift
//  Bizzorg
//
//  Created by Jordan Field on 13/07/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import Foundation

/**
 The native client representation for the EmployeeGroup model on the server.
 
 Properties
 ==========
 
 `name`: The name of the employee group.
 
 `title`: Computed variable that returns a titleized version of the group's
 name.
 
 `parentGroupUri`: The URI of the parent group of this group (that is, the
 group for which this group is a sub-group.) This can be `nil`.
 
 `resourceUri`: The URI for this instance on the server.
 
 `members`: List of tuples for the members of the group. contains two values:
 `admin`, which is a flag for whether this member is an admin of the group, and
 `employee`, which is this member's employee profile.
 
 `membersWithoutAdminFlag`: A computed variable that removes the admin flag
 from the list of employees, leaving just a list of employee profiles.
 
 `id`: Computed variable for the id of this object, extracted from the resource
 URI.
 
 */
class EmployeeGroup: ApiDataModel, Titleizable {
  var name: String
  var title: String {
    return name.capitalized
  }
  var parentGroupUri: URL?
  var resourceUri: URL
  var members: [(admin: Bool, employee: Employee)] {
    /*
     The map funciton will go through each object in a list, apply the passed
     function to each object, then append the result to a new list, then
     return that newly created list. In this case, I create a tuple with the
     first value being the admin boolean flag and the second value being
     the employee object. The admin flag is checked by seeing if the member is
     also in the admin list.
     */
    return membersWithoutAdminFlag.map {(admins.contains($0.resourceUri), $0)}

  }
  var admins: [URL]
  var membersWithoutAdminFlag: [Employee]
  var id: Int {
    //Split the resource URI String into a list of strings, with the separator
    //being the '/' symbol.
    let dataUriSplit = resourceUri.relativeString.components(separatedBy: "/")
    
    //Return the 5th object in the list.
    //  0   1      2     3                  4    5
    // ["", "api", "v1", "employee-groups", "5", ""]
    return Int(dataUriSplit[4])!
  }
  
  //The possible user attributes and their corresponding server response values.
  enum EmployeeGroupAttribute: String {
    case
    resourceUri = "resource_uri",
    name = "name",
    parentGroupUri = "parent_group",
    membersFull = "members_full",
    members = "members",
    admins = "admins"
  }
  
  ///Initialises an employee group from a KeyValuePairs dictionary.
  /// - parameter data: The dictionary to create the employee group from.
  required init(data: KeyValuePairs) throws {
    
    //See 'extract' function in employee object for detailed explanation.
    func extract(_ key: EmployeeGroupAttribute,
                 from data: KeyValuePairs) -> Any? {
      return data[key.rawValue]
    }
    
    //See 'extractUri' function in employee object for detailed explanation.
    func extractUri(_ key: EmployeeGroupAttribute,
                    from data: KeyValuePairs) -> URL? {
      guard let relativeString = extract(key, from: data) as? String,
        let url = URL(string: relativeString, relativeTo: baseUrl) else {
          return nil
      }
      return url
    }
    
    //Ensure that a resource URI, group name and members list all appear in the
    //passed dictionary.
    guard
      extractUri(.resourceUri, from: data) != nil &&
      extract(.name, from: data) != nil &&
      extract(.members, from: data) != nil else {
        //Throw an error if at least one of these characteristics is not 
        //present.
        throw DataError.dataConversionFailed
    }
    
    //Extract the group name from the dictionary and assign it to the instance
    //variable.
    name = extract(.name, from: data) as! String
    
    //Extract the optional parent group URI from the dictionary and assign it
    //to the instance variable. The function automatically produces nil if there
    //is no URI present.
    parentGroupUri = extractUri(.parentGroupUri, from: data)
    
    //Extract the resouce URI from the dictionary and assign it to the instance
    //variable. Since I have already checked and verified the resource URI I
    //can force unwrap this optional value, since it will never be nil.
    resourceUri = extractUri(.resourceUri, from: data)!
    
    //Extract the list of members from the dictionary and assign it to a
    //constant.
    let membersArray = extract(.membersFull, from: data) as! [KeyValuePairs]
    
    //Extract the group admin URIs from the dictionary and create a list
    //of string leaves from it.
    let adminUrlLeaves = extract(.admins, from: data) as! [String]
    
    //Create a new array by creating URL objects from the relative string 
    //leaves, assign this to the admins instance variable.
    admins = adminUrlLeaves.map {URL(string: $0, relativeTo: baseUrl)!}
    
    //Attempt to convert each member dictionary in the member array to a native
    //Employee object and create a new list for these native objects. If this
    //succeeds, assign it to the membersWithoutAdminFlag instance variable.
    do {
      membersWithoutAdminFlag = try membersArray.map {
        (object) in try Employee(data: object["employee"] as! KeyValuePairs)
      }
    } catch {
      throw error
    }
  }
  
  ///Initializes an employee group object from a binary data packe
  /// - parameter data: the Data packet to be used for initialization.
  convenience required init?(data: Data) {
    do {
      //Attempt to convert the data packet into a KeyValuePairs dictionary.
      let kvp = try JSONSerialization.jsonObject(with: data) as! KeyValuePairs
      //Use that dictionary to attempt to initialise an EmployeeGroup object
      //using the initializer above.
      try self.init(data: kvp)
    } catch {
      //If either process fails, return nil to denote the process failed.
      return nil
    }
  }

}
