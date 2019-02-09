//
//  EmployeeApiCalls.swift
//  Bizzorg
//
//  Created by Jordan Field on 08/09/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import Foundation

//A function to retrive the currently logged in user on this device.
func getLoggedInUser() -> Employee? {
  //Retrieve the dictionary for the logged in user from the user defaults
  //permanent storage.
  guard let employeeKvp =
    globalUserDefaults.dictionary(forKey: "logged-in-user") else {
    return nil
  }
  //Try to convert this dictionary into a native Employee object. the try?
  //keyword denotes that the result should be nil if this process fails.
  let employee = try? Employee(data: employeeKvp)
  loggedInUser = employee
  return employee
}
