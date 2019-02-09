//
//  Employee.swift
//  Bizzorg
//
//  Created by Jordan Field on 13/07/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
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
class Employee: ApiDataModel {
  var username: String
  var firstName: String
  var surname: String
  var jobPosition: String
  var email: String
  var resourceUri: URL
  var profilePictureUri: URL?
  var administrating: [URL] = []
  var profilePicture: UIImage?
  var isStaff: Bool
  var fullName: String {
    return "\(self.firstName) \(self.surname)"
  }
  var id: Int {
    let dataUriSplit = resourceUri.relativeString.components(separatedBy: "/")
    return Int(dataUriSplit[4])!
  }
  
  enum EmployeeJSONKeys: String {
    case ResourceUri = "resource_uri"
    case User = "user"
    case JobPosition = "job_position"
    case FirstName = "first_name"
    case Surname = "last_name"
    case Username = "username"
    case Email = "email"
    case ProfilePicture = "profile_picture"
    case IsStaff = "is_staff"
    case Administrating = "administrating"
  }
  
  ///Initisalises an Employee instance from a KeyValuePairs bundle. It is
  ///important to note that the user objects must be contained within a
  ///seperate `user` dictionary inside the main dictionary.
  required init(data: KeyValuePairs) throws {
   
    /**
    The extract function defined here simplifies extracting data from the
    dictionary. Instead of calling the dictionary objects like:
     `resourceUri = data[EmployeeJSONKeys.ResourceUri.rawValue)`,
     the function allows data to be extracted using the statement:
     `resourceUri = extract(data, .ResourceUri)`,
     Which is easier to type and read.
     
     - parameter key: An Employee JSON Enum key, denoting which detail to
     extract.
     - parameter from: The KeyValuePairs dictionary to extract the data from.
     */
    func extract(_ key: EmployeeJSONKeys, from data: KeyValuePairs) -> Any? {
      return data[key.rawValue]
    }
    
    /**
     I have to extract a few URIs from the data dictionary. this requires that
     I first extract the leaf of the url as a String then call a URL
     initalizer with the relative string relative to the base Bizzorg URL and
     returning that URL. This function does this and allows me to call it in
     one line, decreasing code complexity.
     
     - parameter key: The Employee JSON Enum key to extract.
     - parameter from: The KeyValuePairs dictionary to extract from.
    */
    func extractURI(_ key: EmployeeJSONKeys, from data: KeyValuePairs) -> URL? {
      //Attempt to extract the relative URL leaf string from the dictionary
      guard let extractedString = extract(key, from: data) as? String,
        //Atttempt to Use the extracted leaf to generate a URL relative to 
        //the base URL.
        let url = URL(string: extractedString, relativeTo: baseUrl) else {
          //If either process fails, return nil to denote that the data doesn't
          //exist.
          return nil
      }
      //Return the created URL.
      return url
    }
    
    //Ensure that a resourceUri exists and a job position string exists in the
    //data supplied. If not, throw an error.
    guard extractURI(.ResourceUri, from: data) != nil &&
          extract(.JobPosition, from: data) != nil else {
      throw DataError.dataConversionFailed
    }
    
    //assign the resource URI in the dictionary to the instance URI
    resourceUri = extractURI(.ResourceUri, from: data)!
    
    //Assign the profile picture URI in the dictionary to the instance variable,
    //If the user does not have a profile picture, the function automatically
    //assigns it to nil.
    profilePictureUri = extractURI(.ProfilePicture, from: data)
    
    //Ensure that a list of groups the user is an admin of is present. it
    //may be an empty list e.g. [] but it needs to be there. If it isn't,
    //throw an error.
    guard let adminObjects =
      extract(.Administrating, from: data) as? [String] else {
      throw DataError.dataConversionFailed
    }
    
    //Create an empty list which will contain the URI, converted from the URI
    //strings generated earlier. Assign it to the administrating instance
    //variable.
    administrating = adminObjects.map {URL(string: $0, relativeTo: baseUrl)!}
    
    //Extract the job position as a string and assign it to the instance
    jobPosition = extract(.JobPosition, from: data) as! String
    
    //Inside a Employee response JSON dictionary is another User model
    //dictionary that contains information like the name and email of
    //the employee, extract this dictionary as a KeyValuePairs dictionary and
    //assign it to the variable userKvp
    let userKvp = extract(.User, from: data) as! KeyValuePairs
    
    //Extract the username from the user dictionary and assign it to the
    //username instance variable.
    username = extract(.Username, from: userKvp) as! String
    
    //Extract the first name from the user dictionary and assign it to the
    //firstName instance variable.
    firstName = extract(.FirstName, from: userKvp) as! String
    
    //Extract the surname from the user dictionary and assign it to the
    //surname instance variable.
    surname = extract(.Surname, from: userKvp) as! String
    
    //Extract the email address from the user dictionary and assign it to the
    //email instance variable.
    email = extract(.Email, from: userKvp) as! String
    
    //Extract the staff flag from the user dictionary and assign it to the
    //isStaff instance variable.
    isStaff = extract(.IsStaff, from: userKvp) as! Bool
  }
  
  
  ///This secondary initializer takes in a Data object, converts it to a
  ///KeyValuePairs dictionary and runs the primary initializer on the
  ///generated dictionary.
  convenience required init?(data: Data) {
    do {
      //Try to convert from raw data to a KeyValuePairs dictionary.
      let kvp = try JSONSerialization.jsonObject(with: data) as! KeyValuePairs
      //Try to initialise the object from the generated KVP dicitionary.
      try self.init(data: kvp)
    //If any errors are thrown in the process:
    } catch {
      //return nil to denote that the process failed.
      return nil
    }
  }
  
  /**
   Takes the variables for this instance and compacts them down into a
   KeyValuePair dictionary.
  */
  func toDict() -> KeyValuePairs {
    
    /*
     Shorthand function that extracts the raw String value for an
     EmployeeJSONKeys enum object.
    */
    let r: (EmployeeJSONKeys) -> String = {$0.rawValue}
    
    //Create the dictionary with the relevant variables.
    var dictionary: KeyValuePairs = [
      r(.ResourceUri): resourceUri.relativeString,
      r(.JobPosition): jobPosition,
      r(.User): [
        r(.FirstName): firstName,
        r(.Surname): surname,
        r(.Username): username,
        r(.Email): email,
        r(.IsStaff): isStaff,
      ]
    ]
    
    //Assign the administrated groups to the dictionary if present.
    //The server cannot deal with native URLs, so I must map the relative
    //URL leaf strings instead of the URLs.
    dictionary[r(.Administrating)] = administrating.map {$0.relativeString}
    
    //Assign the profile picture to the dictionary if it exists.
    dictionary[r(.ProfilePicture)] = profilePictureUri?.relativeString
    return dictionary
  }
  
  /**
   Produces a JSON object from the instance, used for updating the server with
   new information.
   */
  func toJSON() -> String {
    //Attempt to convert the dictionary representation of the object to a
    //JSON object.
    guard let serialization =
      try? JSONSerialization.data(withJSONObject: self.toDict()) else {
        //Return an error if this process fails.
        return "{'Error':''}"
    }
    //Return a string representation of the JSON data.
    return String(data: serialization, encoding: .utf8)!
  }
  
  /**
   Retrieves the user's profile picture from the server.
   
   - parameter urlSession: The URLSession used for client-server communication.
   - parameter callback: Function that is called once a response from the
   server has been recieved.
   */
  func getProfilePicture(_ urlSession: URLSession,
                         callback: @escaping () -> Void) {
    //Check that the user has a profile picture. If not, immediately call back
    //since there was no picture to retrieve.
    guard profilePictureUri != nil else {
      callback()
      return
    }
    
    //Retrieve the profile picture from the employee's profile picture URI
    getObjectFromUri(profilePictureUri!, urlSession: urlSession) {
      //Once a response has been recieved a type must be assigned to it,
      //since this function is type agnostic. since I am retrieving a
      //picture, assign the UIImage type.
      (image: UIImage?, _) in
      //Assign the picture to the profilePicture instance variable.
      self.profilePicture = image
      //Call back to denote the process is complete.
      callback()
    }
  }
  
  /**
   Asynchronous function that updates the profile picture of an employee.
   
   - parameter urlSession: The URLSession object used for client-server
   communication.
   - parameter newPicture: The image to be sent to the server.
   - parameter callback: Function that is invoked when the process has
   completed, or an error has occcured.
   */
  func updateProfilePicture(_ urlSession: URLSession,
                            newPicture: UIImage,
                            callback: @escaping (Error?) -> Void) {
    
    //Take the full resolution image and scale it down to a suitable size.
    //Assign this resized profile picture to a new constant.
    let resizedProfilePicture =
      newPicture.resize(CGSize(width: 256.0, height: 256.0))
    
    //Create a new UploadableFile object to contain the picture.
    let profilePictureFile = UploadableFile()
    
    //Assign the data JPEG representation of the resized profile picture to
    //the file data attribute.
    profilePictureFile.data =
      UIImageJPEGRepresentation(resizedProfilePicture, 0.75)!
    
    //Assign the other relevant attributes.
    profilePictureFile.name = "new_profile_picture"
    profilePictureFile.contentType = "image/jpeg"
    profilePictureFile.fileName = "image.jpg"
    
    //Retrieve the ID of the employee and assign it to a constant.
    let employeeIdString = String(id)
    
    //Create another UploadableFile object for the other form data.
    let employeeInfo = UploadableFile()
    
    //Assign the UFT8 data representation of the ID string and assign it to the
    //employeeInfo file data.
    employeeInfo.data = employeeIdString.data(using: .utf8)!
    
    //Assign the form attribute correctly.
    employeeInfo.name = "user"
    
    //Create a new BizzorgCall object pointing to the url for updating profile
    //pictures.
    let call = BizzorgCall("groups/update_profile_picture/", method: .POST)
    
    //Add the newly ceated files to the BizzorgCall files attribute.
    call.files = [profilePictureFile, employeeInfo]
    
    //Send the call to the server and wait for a response.
    call.sendToServer(urlSession) {
      //Once a response has been recieved assign it to a constant.
      let response = call.serverResponse!
      
      //Ensure the response is suitable for processing. If it is not, return
      //the error the has come about.
      guard response.validated else {
        callback(response.error!)
        return
      }
      
      //The server will respond with a new URI for the user's profile picture.
      //Retrieve it from the response and assign it to a constant.
      let newProfilePictureUri = String(data: response.data!, encoding: .utf8)!
      
      //Set the employee's profile picture URI to the new URI.
      self.profilePictureUri =
        URL(string: newProfilePictureUri, relativeTo: baseUrl)
      
      //Callback to denote the process has completed.
      callback(nil)
    }
  }
}
