//
//  EmployeeRewrite.swift
//  Bizzorg
//
//  Created by Jordan Field on 22/10/2017.
//  Copyright © 2017 Jordan Field. All rights reserved.
//

import Foundation
import UIKit

/**
 The employee class is the Client equivalent to the Server "`EmployeeProfile`"
 model. It also provides some methods for interacting with the server, such as
 updating the profile picture and converting from the instance to a JSON object.
 
 Properties
 ==========
 
 `username`: User's account name on the server.
 
 `FirstName`: User's first name.
 
 `surname`: User's last name.
 
 `jobPosition`: The job position in the company.
 
 `email`: User's email address
 
 `resourceUri`: The link for requesting this object from the server.
 
 `profilePictureUri`: Link to user's profile picture
 
 `administrating` : List of resource URIs for groups this employee is an
 admin of.
 
 `profilePicture`: The user's profile picture, or `nil` if the profile picture
 hasn't been loaded into memory.
 
 `isStaff`: Boolean value that denotes whether the employee is part of the
 VIP staff list.
 
 `fullName`: Computed varible that combines the first and last name of the
 employee.
 
 `id`: Computed variable that extracts the employee's ID from the resource URI.
 */
class EmployeeV2: Codable {
  var username: String
  var firstName: String
  var lastName: String
  var email: String
  var isStaff: Bool
  var jobPosition: String
  var resourceUri: URL?
  var profilePictureUri: URL?
  var administrating: [URL]
  
  enum CodingKeys: String, CodingKey {
    case user
    case jobPosition = "job_position"
    case resourceUri = "resource_uri"
    case profilePictureUri = "profile_picture"
    case administrating
  }
  
  enum UserKeys: String, CodingKey {
    case username
    case firstName = "first_name"
    case lastName = "surname"
    case email
    case isStaff = "is_staff"
  }
  
  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let userBundle = try values.nestedContainer(keyedBy: UserKeys.self,
                                                forKey: .user)
    username = try userBundle.decode(String.self, forKey: .username)
    firstName = try userBundle.decode(String.self, forKey: .firstName)
    lastName = try userBundle.decode(String.self, forKey: .lastName)
    email = try userBundle.decode(String.self, forKey: .email)
    isStaff = try userBundle.decode(Bool.self, forKey: .isStaff)
    
    jobPosition = try values.decode(String.self, forKey: .jobPosition)
    resourceUri = try values.decode(URL.self, forKey: .resourceUri)
    profilePictureUri = try values.decode(URL.self, forKey: .profilePictureUri)
    administrating = try values.decode([URL].self, forKey: .administrating)
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    var userBundle = container.nestedContainer(keyedBy: UserKeys.self,
                                               forKey: .user)
    try userBundle.encode(username, forKey: .username)
    try userBundle.encode(firstName, forKey: .firstName)
    try userBundle.encode(lastName, forKey: .lastName)
    try userBundle.encode(email, forKey: .email)
    try userBundle.encode(isStaff, forKey: .isStaff)
    
    try container.encode(jobPosition, forKey: .jobPosition)
  }
  
  var fullName: String {
    return "\(self.firstName) \(self.lastName)"
  }
  var id: Int? {
    guard let dataUriSplit = resourceUri?.relativeString.components(separatedBy: "/") else {
      return nil
    }
    return Int(dataUriSplit[4])
  }
}
